import Foundation
@preconcurrency import MultipeerConnectivity
import OSLog

// MARK: - MultipeerChatManager
// Handles all P2P networking for the A2A Agent Chat feature.
// Responsibilities: peer discovery, session lifecycle, message broadcast,
// auto-reconnect with exponential backoff, and chat-history sync on rejoin.

@MainActor
@Observable
final class MultipeerChatManager: NSObject, Sendable {
    private let myPeerId: MCPeerID
    private let serviceType = "nod-a2a"
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // AsyncStream for delivering incoming payloads to the UI / Algorithms layer.
    private let incomingPayloadsContinuation: AsyncStream<A2APayload>.Continuation
    let incomingMessages: AsyncStream<A2APayload>

    /// Nearby peers detected by the browser (delegate view: pick a host to join).
    var availableHosts: [MCPeerID] = []

    /// Currently connected peers (host view: lobby headcount).
    var connectedPeers: [MCPeerID] = []

    // MARK: - Status

    /// True while trying to re-establish a dropped connection.
    var isReconnecting = false

    // Session role flags
    var isHosting = false
    var isBrowsing = false

    // MARK: - Reconnect State (private)

    /// Whether this device is running as Host (controls reconnect strategy).
    private var actingAsHost = false

    /// Retry attempt counter — reset on successful connection.
    private var reconnectAttempt = 0

    /// Maximum number of reconnect retries before giving up.
    private let maxReconnectAttempts = 5

    /// Backoff delays in seconds: 0 (immediate), 2, 5, 10, 20
    private let backoffDelays: [UInt64] = [0, 2, 5, 10, 20]

    // MARK: - Chat History (Host only)

    /// The Host stores a local copy of the transcript so it can sync it
    /// to any Delegate that reconnects mid-session.
    var chatHistory: [ChatMessage] = []

    // MARK: - B2: Outgoing Message Queue

    /// Tracks unacknowledged outbound payloads keyed by their envelope UUID.
    /// Value: (original payload, retry attempt count)
    private var pendingQueue: [UUID: (A2APayload, Int)] = [:]

    /// Serializes all pendingQueue reads/writes to prevent data races
    /// (accessed from DispatchQueue.global callbacks AND the MCSession delegate thread).
    private let pendingQueueLock = NSLock()

    /// Maximum delivery retries before giving up on a message.
    private let maxDeliveryRetries = 3

    /// Seconds to wait for an ACK before retrying.
    private let ackTimeoutSeconds: Double = 3.0

    /// Published flag: true when any message has exhausted all retries.
    var hasUndeliveredMessage = false

    // MARK: - Init

    init(displayName: String) {
        self.myPeerId = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)

        let (stream, continuation) = AsyncStream.makeStream(of: A2APayload.self)
        self.incomingMessages = stream
        self.incomingPayloadsContinuation = continuation

        super.init()
        self.session.delegate = self
    }

    deinit {
        // Properties like advertiser/browser are actor-isolated and cannot be 
        // safely stopped in a synchronous deinit. They will be released and 
        // stopped automatically by the OS when the manager is deallocated.
        incomingPayloadsContinuation.finish()
    }

    // MARK: - Hosting

    func startHosting() {
        guard !isHosting else { return }
        actingAsHost = true
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isHosting = true
        Logger.network.info("📡 Started advertising Nod A2A Lobby as \(self.myPeerId.displayName)")
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
        session.disconnect()
        connectedPeers.removeAll()
        chatHistory.removeAll()
        actingAsHost = false
    }

    // MARK: - Browsing (Delegate)

    func startBrowsing() {
        guard !isBrowsing else { return }
        actingAsHost = false
        availableHosts.removeAll()
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        Logger.network.info("🔍 Started browsing for Nod A2A Hosts")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
    }

    func joinHost(_ hostPeer: MCPeerID) {
        guard isBrowsing else { return }
        Logger.network.info("🤝 Attempting to join Host: \(hostPeer.displayName)")
        browser?.invitePeer(hostPeer, to: session, withContext: nil, timeout: 30)
    }

    // MARK: - Broadcasting

    /// Broadcasts a payload to all connected peers.
    /// Enqueues the payload for ACK tracking; retries up to `maxDeliveryRetries` times
    /// if no ACK is received within `ackTimeoutSeconds`.
    func broadcast(payload: A2APayload) throws {
        guard !session.connectedPeers.isEmpty else {
            Logger.network.warning("⚠️ Cannot broadcast: No connected peers.")
            return
        }
        try enqueueAndSend(payload: payload, toPeers: session.connectedPeers)
    }

    /// Sends a payload to a single specific peer (used for history sync on rejoin).
    private func send(payload: A2APayload, to peer: MCPeerID) throws {
        let data = try JSONEncoder().encode(payload)
        try session.send(data, toPeers: [peer], with: .reliable)
    }

    // MARK: - Internal Queue Helpers

    private func enqueueAndSend(payload: A2APayload, toPeers peers: [MCPeerID], retryCount: Int = 0) throws {
        let data = try JSONEncoder().encode(payload)
        if data.count > 100_000 {
            Logger.network.warning("⚠️ Payload unusually large: \(data.count) bytes.")
        }
        try session.send(data, toPeers: peers, with: .reliable)
        Logger.network.info("📤 Sent \(payload.type.rawValue) (attempt \(retryCount + 1)) to \(peers.count) peers.")

        // Skip ACK tracking for ack payloads themselves to prevent infinite loops.
        guard payload.type != .ack else { return }

        pendingQueueLock.lock()
        pendingQueue[payload.senderID] = (payload, retryCount)
        pendingQueueLock.unlock()

        // Schedule ACK timeout.
        let payloadID = payload.senderID
        DispatchQueue.global().asyncAfter(deadline: .now() + ackTimeoutSeconds) { [weak self] in
            Task { @MainActor in
                self?.handleAckTimeout(payloadID: payloadID)
            }
        }
    }

    private func handleAckTimeout(payloadID: UUID) {
        pendingQueueLock.lock()
        let entry = pendingQueue[payloadID]
        pendingQueueLock.unlock()

        guard let (payload, attempt) = entry else {
            // Already acknowledged — nothing to do.
            return
        }
        if attempt >= maxDeliveryRetries - 1 {
            Logger.network.error("🚫 Message \(payloadID) undelivered after \(self.maxDeliveryRetries) attempts. Giving up.")
            pendingQueueLock.lock()
            pendingQueue.removeValue(forKey: payloadID)
            pendingQueueLock.unlock()
            self.hasUndeliveredMessage = true
            return
        }
        Logger.network.warning("♻️ No ACK for \(payloadID). Retry \(attempt + 2)/\(self.maxDeliveryRetries)...")
        guard !session.connectedPeers.isEmpty else {
            pendingQueueLock.lock()
            pendingQueue.removeValue(forKey: payloadID)
            pendingQueueLock.unlock()
            return
        }
        try? enqueueAndSend(payload: payload, toPeers: session.connectedPeers, retryCount: attempt + 1)
    }

    /// Called when an ACK payload arrives. Removes the matching entry from the pending queue.
    private func processAck(payloadID: UUID) {
        pendingQueueLock.lock()
        let removed = pendingQueue.removeValue(forKey: payloadID)
        pendingQueueLock.unlock()
        if removed != nil {
            Logger.network.info("✅ ACK received for \(payloadID). Dequeued.")
        }
    }

    // MARK: - Reconnect Logic

    /// Called when a peer disconnects. Applies role-appropriate reconnect strategy.
    private func handleDisconnect(peer: MCPeerID) {
        Logger.network.warning("❌ Peer disconnected: \(peer.displayName). Attempting reconnect...")
        isReconnecting = true
        reconnectAttempt = 0

        if actingAsHost {
            // Host re-advertises so the lost delegate can find and rejoin.
            scheduleHostReAdvertise()
        } else {
            // Delegate restarts browsing to find the host again.
            scheduleDelegateRejoin()
        }
    }

    private func scheduleHostReAdvertise() {
        guard reconnectAttempt < maxReconnectAttempts else {
            Logger.network.error("🚫 Host gave up re-advertising after \(self.maxReconnectAttempts) attempts.")
            DispatchQueue.main.async { self.isReconnecting = false }
            return
        }
        let delay = backoffDelays[min(reconnectAttempt, backoffDelays.count - 1)]
        Logger.network.info("♻️ Host re-advertise attempt \(self.reconnectAttempt + 1) in \(delay)s...")
        
        Task {
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            
            // If a peer already reconnected while waiting, stop.
            guard self.session.connectedPeers.isEmpty else {
                self.isReconnecting = false
                return
            }
            self.advertiser?.stopAdvertisingPeer()
            self.advertiser?.startAdvertisingPeer()
            self.reconnectAttempt += 1
            self.scheduleHostReAdvertise()
        }
    }

    private func scheduleDelegateRejoin() {
        guard reconnectAttempt < maxReconnectAttempts else {
            Logger.network.error("🚫 Delegate gave up rejoining after \(self.maxReconnectAttempts) attempts.")
            DispatchQueue.main.async { self.isReconnecting = false }
            return
        }
        let delay = backoffDelays[min(reconnectAttempt, backoffDelays.count - 1)]
        Logger.network.info("♻️ Delegate rejoin attempt \(self.reconnectAttempt + 1) in \(delay)s...")
        
        Task {
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            guard self.session.connectedPeers.isEmpty else {
                self.isReconnecting = false
                return
            }
            self.browser?.stopBrowsingForPeers()
            self.browser?.startBrowsingForPeers()
            self.reconnectAttempt += 1
            self.scheduleDelegateRejoin()
        }
    }

    /// Called when a peer reconnects successfully.
    /// If we are the Host, we send the full chat history to the rejoined peer.
    private func handleReconnect(peer: MCPeerID) {
        Logger.network.info("✅ Peer reconnected: \(peer.displayName). Reconnect attempt count reset.")
        reconnectAttempt = 0
        self.isReconnecting = false

        guard actingAsHost, !chatHistory.isEmpty else { return }

        Logger.network.info("📜 Syncing \(self.chatHistory.count) messages to rejoined peer \(peer.displayName).")
        let syncPayload = ChatHistorySyncPayload(messages: chatHistory)
        guard let data = try? JSONEncoder().encode(syncPayload) else { return }
        let envelope = A2APayload(type: .chatHistorySync, senderID: UUID(), data: data)
        try? send(payload: envelope, to: peer)
    }
}

// MARK: - MCSessionDelegate

extension MultipeerChatManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.connectedPeers = session.connectedPeers
        }
        Task { @MainActor in
            switch state {
            case .connected:
                Logger.network.info("✅ Peer Connected: \(peerID.displayName)")
                self.handleReconnect(peer: peerID)
            case .connecting:
                Logger.network.info("⏳ Peer Connecting: \(peerID.displayName)")
            case .notConnected:
                Logger.network.info("❌ Peer Disconnected: \(peerID.displayName)")
                // Only trigger reconnect if we were previously fully connected (not first-join failures).
                if self.isHosting || self.isBrowsing {
                    self.handleDisconnect(peer: peerID)
                }
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let payload = try JSONDecoder().decode(A2APayload.self, from: data)
            Logger.network.info("📥 Received \(payload.type.rawValue) from \(peerID.displayName) (\(data.count) bytes)")

            if payload.type == .ack {
                // Decode which original message this ACK confirms.
                if let ackID = try? JSONDecoder().decode(UUID.self, from: payload.data) {
                    Task { @MainActor in
                        self.processAck(payloadID: ackID)
                    }
                }
                return // ACKs are not forwarded upstream.
            }

            // For every other payload type, send ACK back to the sender.
            if let ackData = try? JSONEncoder().encode(payload.senderID) {
                let ack = A2APayload(type: .ack, senderID: payload.senderID, data: ackData)
                Task { @MainActor in
                    try? self.send(payload: ack, to: peerID)
                    self.incomingPayloadsContinuation.yield(payload)
                }
            }
        } catch {
            Logger.network.error("💥 Failed to decode payload from \(peerID.displayName): \(error)")
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerChatManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.network.info("📬 Received invitation from \(peerID.displayName). Auto-accepting.")
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerChatManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Logger.network.info("🔭 Found Host: \(peerID.displayName)")
        Task { @MainActor in
            if !self.availableHosts.contains(peerID) {
                self.availableHosts.append(peerID)
            }
        }
        // If we are reconnecting, auto-rejoin the first host we find.
        Task { @MainActor in
            if self.isReconnecting {
                Logger.network.info("♻️ Auto-rejoining \(peerID.displayName) after reconnect.")
                self.joinHost(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Logger.network.info("💨 Lost Host: \(peerID.displayName)")
        Task { @MainActor in
            self.availableHosts.removeAll { $0 == peerID }
        }
    }
}

// MARK: - Logger

extension Logger {
    static let network = Logger(subsystem: "com.nod.a2a", category: "Multipeer")
}
