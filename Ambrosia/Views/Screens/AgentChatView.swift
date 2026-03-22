import SwiftUI

struct AgentChatView: View {
    @Bindable var store: AppStore
    var isHost: Bool

    @State private var hasStartedChat = false
    @State private var typingAgent: String? = nil
    @State private var isProcessingConsensus = false
    @State private var isPulsing = false

    // B4: Error boundaries
    @State private var llmError: String? = nil
    @State private var lastFailedAction: (() async -> Void)? = nil
    @State private var isSessionIdle = false
    @State private var idleTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            NodTheme.Cinematic.deepBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear.frame(height: 80)

                if !hasStartedChat {
                    lobbyView
                } else {
                    chatView
                }
            }

            if isProcessingConsensus {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(NodTheme.Cinematic.amber)
                        Text("Drafting final order...")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
            }
        }
        .floatingNavBar(
            title: isHost ? "Host Lobby" : "Table Lobby",
            leading: .init(icon: "chevron.left") { store.navigationPath.removeLast() },
            trailing: (!hasStartedChat && isHost) ? .init(icon: "play.fill") { startAIChat() } : nil
        )
        .overlay(alignment: .top) {
            VStack(spacing: NodTheme.Spacing.sm) {
                if store.chatManager.isReconnecting {
                    reconnectingBanner
                }
                if store.chatManager.hasUndeliveredMessage {
                    deliveryFailureBanner
                }
                if let err = llmError {
                    llmErrorBanner(message: err)
                }
                if isSessionIdle {
                    idlePromptBanner
                }
            }
        }
        .task {
            if isHost {
                store.chatManager.startHosting()
            } else {
                store.chatManager.startBrowsing()
            }
            await listenToNetwork()
        }
    }

    // MARK: - Reconnecting Banner

    private var reconnectingBanner: some View {
        HStack(spacing: NodTheme.Spacing.sm) {
            ProgressView()
                .tint(NodTheme.Cinematic.amber)
                .scaleEffect(0.8)
            Text("Connection lost — reconnecting...")
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.pureWhite)
        }
        .padding(.horizontal, NodTheme.Spacing.lg)
        .padding(.vertical, NodTheme.Spacing.sm)
        .background(Color.black.opacity(0.75))
        .clipShape(Capsule())
        .padding(.top, NodTheme.Spacing.xl)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.chatManager.isReconnecting)
    }

    private var deliveryFailureBanner: some View {
        HStack(spacing: NodTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            Text("A message failed to deliver.")
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.pureWhite)
            Spacer()
            Button("Dismiss") {
                store.chatManager.hasUndeliveredMessage = false
            }
            .font(NodTheme.Typography.caption)
            .foregroundColor(NodTheme.Cinematic.amber)
        }
        .padding(.horizontal, NodTheme.Spacing.lg)
        .padding(.vertical, NodTheme.Spacing.sm)
        .background(Color.red.opacity(0.25))
        .clipShape(Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.chatManager.hasUndeliveredMessage)
    }

    // MARK: - B4 Error Boundary Banners

    private func llmErrorBanner(message: String) -> some View {
        HStack(spacing: NodTheme.Spacing.sm) {
            Image(systemName: "bolt.slash.fill")
                .font(.caption)
                .foregroundColor(NodTheme.Cinematic.amber)
            Text(message)
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.pureWhite)
                .lineLimit(2)
            Spacer()
            if let retry = lastFailedAction {
                Button("Retry") {
                    llmError = nil
                    Task { await retry() }
                }
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.amber)
            }
            Button { llmError = nil } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(NodTheme.Cinematic.smokeGray)
            }
        }
        .padding(.horizontal, NodTheme.Spacing.lg)
        .padding(.vertical, NodTheme.Spacing.sm)
        .background(Color(white: 0.12))
        .clipShape(Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: llmError)
    }

    private var idlePromptBanner: some View {
        HStack(spacing: NodTheme.Spacing.sm) {
            Image(systemName: "clock.badge.questionmark")
                .font(.caption)
                .foregroundColor(NodTheme.Cinematic.smokeGray)
            Text("Is everyone still there? The table has been quiet for a while.")
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.smokeGray)
                .lineLimit(2)
            Spacer()
            Button("Dismiss") { isSessionIdle = false }
                .font(NodTheme.Typography.caption)
                .foregroundColor(NodTheme.Cinematic.amber)
        }
        .padding(.horizontal, NodTheme.Spacing.lg)
        .padding(.vertical, NodTheme.Spacing.sm)
        .background(Color(white: 0.1))
        .clipShape(Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSessionIdle)
    }

    /// Resets the 5-minute idle watchdog each time an LLM reply is sent or received.
    private func resetIdleTimer() {
        idleTask?.cancel()
        isSessionIdle = false
        idleTask = Task {
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { isSessionIdle = true }
        }
    }

    // MARK: - Pre-Chat Lobby

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: NodTheme.Spacing.xl) {
                if isHost {
                    hostLobbyContent
                } else {
                    delegateLobbyContent
                }
            }
            .padding(.horizontal, NodTheme.Spacing.xl)
            .padding(.vertical, NodTheme.Spacing.lg)
        }
    }

    private var hostLobbyContent: some View {
        VStack(spacing: NodTheme.Spacing.xl) {
            // Amber pulsing advertising indicator
            HStack(spacing: NodTheme.Spacing.sm) {
                Circle()
                    .fill(NodTheme.Cinematic.amber)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.4 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                Text("Advertising to nearby friends...")
                    .font(NodTheme.Typography.body)
                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                Spacer()
            }
            .padding(NodTheme.Spacing.lg)
            .glassCard(cornerRadius: NodTheme.Radius.xl)
            .onAppear { isPulsing = true }

            // Connected delegate count
            HStack {
                Text("Connected Delegates")
                    .font(NodTheme.Typography.headline)
                    .foregroundColor(NodTheme.Cinematic.pureWhite)
                Spacer()
                Text("\(store.chatManager.connectedPeers.count)")
                    .font(NodTheme.Typography.headline)
                    .foregroundColor(NodTheme.Cinematic.amber)
            }
            .padding(NodTheme.Spacing.lg)
            .glassCard(cornerRadius: NodTheme.Radius.lg)

            // Peer chips
            ForEach(store.chatManager.connectedPeers, id: \.self) { peer in
                HStack(spacing: NodTheme.Spacing.md) {
                    Image(systemName: "person.fill")
                        .foregroundColor(NodTheme.Cinematic.amber)
                    Text(peer.displayName)
                        .font(NodTheme.Typography.body)
                        .foregroundColor(NodTheme.Cinematic.pureWhite)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NodTheme.Cinematic.amber)
                }
                .padding(NodTheme.Spacing.md)
                .glassCard(cornerRadius: NodTheme.Radius.lg)
            }
        }
    }

    private var delegateLobbyContent: some View {
        VStack(spacing: NodTheme.Spacing.xl) {
            // Smoky pulsing waiting indicator
            HStack(spacing: NodTheme.Spacing.sm) {
                Circle()
                    .fill(NodTheme.Cinematic.smokeGray)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.4 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                Text("Waiting for Host to start...")
                    .font(NodTheme.Typography.body)
                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                Spacer()
            }
            .padding(NodTheme.Spacing.lg)
            .glassCard(cornerRadius: NodTheme.Radius.xl)
            .onAppear { isPulsing = true }

            if !store.chatManager.availableHosts.isEmpty {
                Text("Select Host to Join:")
                    .font(NodTheme.Typography.headline)
                    .foregroundColor(NodTheme.Cinematic.pureWhite)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(store.chatManager.availableHosts, id: \.self) { host in
                    GlassButton(title: host.displayName, icon: "person.wave.2.fill", variant: .secondary) {
                        store.chatManager.joinHost(host)
                    }
                }
            }
        }
    }

    // MARK: - Active Chat View

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: NodTheme.Spacing.lg) {
                    ForEach(store.chatTranscript) { msg in
                        ChatBubble(message: msg, isMe: msg.agentName.contains("Host"))
                            .id(msg.id)
                    }

                    if let typing = typingAgent {
                        HStack {
                            if typing.contains("Host") { Spacer() }
                            HStack(spacing: NodTheme.Spacing.sm) {
                                ProgressView()
                                    .tint(NodTheme.Cinematic.amber)
                                    .scaleEffect(0.75)
                                Text("\(typing) is typing...")
                                    .font(NodTheme.Typography.caption)
                                    .italic()
                                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                            }
                            .padding(.horizontal, NodTheme.Spacing.lg)
                            .padding(.vertical, NodTheme.Spacing.sm)
                            .glassCard(cornerRadius: NodTheme.Radius.xl)
                            .transition(.opacity)
                            if !typing.contains("Host") { Spacer() }
                        }
                        .id("TYPING_INDICATOR")
                    }
                }
                .padding(NodTheme.Spacing.lg)
            }
            .onChange(of: store.chatTranscript.count) {
                if let last = store.chatTranscript.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: typingAgent) {
                withAnimation {
                    proxy.scrollTo("TYPING_INDICATOR", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Core A2A Logic

    private func listenToNetwork() async {
        for await payload in store.chatManager.incomingMessages {
            await handleIncomingPayload(payload)
        }
    }

    @MainActor
    private func handleIncomingPayload(_ payload: A2APayload) async {
        do {
            switch payload.type {
            case .chatMessage:
                let msg = try JSONDecoder().decode(ChatMessage.self, from: payload.data)
                store.chatTranscript.append(msg)
                // Host tracks history so it can sync to reconnected peers.
                if isHost { store.chatManager.chatHistory.append(msg) }

                if isHost {
                    if msg.isFinalConsensus {
                        triggerConsensusFound(rawText: msg.text)
                    } else if !msg.agentName.contains("Host") {
                        typingAgent = "Host Moderator"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        typingAgent = nil
                        await triggerHostLLMReply()
                    }
                } else {
                    if msg.isFinalConsensus {
                        triggerConsensusFound(rawText: msg.text)
                    } else if msg.agentName.contains("Host") {
                        typingAgent = "\(UIDevice.current.name)'s Agent"
                        let delay = UInt64(Double.random(in: 1.5...3.5) * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: delay)
                        typingAgent = nil
                        await triggerDelegateLLMReply(restaurantName: store.cachedParsedMenu?.metadata.restaurantName ?? "This Restaurant")
                    }
                }

            case .soulBroadcast:
                let soulData = try JSONDecoder().decode(SoulBroadcastPayload.self, from: payload.data)
                hasStartedChat = true
                store.cachedParsedMenu = try JSONDecoder().decode(MenuData.self, from: soulData.serializedMenuData)

            case .chatHistorySync:
                // Delegate receives this after reconnecting mid-session.
                // Merges server-side history without duplicating messages already in transcript.
                let syncData = try JSONDecoder().decode(ChatHistorySyncPayload.self, from: payload.data)
                let existingIDs = Set(store.chatTranscript.map { $0.id })
                let newMessages = syncData.messages.filter { !existingIDs.contains($0.id) }
                if !newMessages.isEmpty {
                    store.chatTranscript.append(contentsOf: newMessages.sorted { $0.timestamp < $1.timestamp })
                }
                hasStartedChat = true

            default: break
            }
        } catch {
            print("Failed decoding payload: \(error)")
        }
    }

    @MainActor
    private func startAIChat() {
        hasStartedChat = true
        let menuBytes = (try? JSONEncoder().encode(store.cachedParsedMenu)) ?? Data()
        let soulPayload = SoulBroadcastPayload(
            restaurantName: store.cachedParsedMenu?.metadata.restaurantName ?? "This Restaurant",
            serializedMenuData: menuBytes,
            requiredDishCount: 3
        )
        if let payloadData = try? JSONEncoder().encode(soulPayload) {
            let env = A2APayload(type: .soulBroadcast, senderID: UUID(), data: payloadData)
            try? store.chatManager.broadcast(payload: env)
        }

        Task {
            isProcessingConsensus = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isProcessingConsensus = false
            await triggerHostLLMReply()
        }
    }

    private func triggerHostLLMReply() async {
        let agent = ModeratorAgent()
        let rName = store.cachedParsedMenu?.metadata.restaurantName ?? "This Restaurant"
        let soul = AgentSoul.hostModeratorCommandments(restaurantName: rName, requiredDishes: 3)
        do {
            let reply = try await agent.generateChatReply(
                transcript: store.chatTranscript,
                soulCommandments: soul,
                menuData: store.cachedParsedMenu
            )
            store.chatTranscript.append(reply)
            if isHost { store.chatManager.chatHistory.append(reply) }
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
            }
            resetIdleTimer()
            llmError = nil
            if reply.isFinalConsensus {
                triggerConsensusFound(rawText: reply.text)
            }
        } catch {
            await MainActor.run {
                llmError = "Host AI failed to respond. \(error.localizedDescription)"
                lastFailedAction = { await self.triggerHostLLMReply() }
            }
        }
    }

    private func triggerDelegateLLMReply(restaurantName: String) async {
        let agent = DelegateAgent(profile: store.individualProfile, delegateName: UIDevice.current.name)
        let vetoesStr = store.individualProfile.vetoes.isEmpty ? "None" : store.individualProfile.vetoes.joined(separator: ", ")
        let cravingsStr = store.individualProfile.cravings.isEmpty ? "Surprise me" : store.individualProfile.cravings.joined(separator: ", ")
        let soul = AgentSoul.delegateCommandments(
            delegateName: UIDevice.current.name,
            vetoes: vetoesStr,
            cravings: cravingsStr
        )
        do {
            let reply = try await agent.generateChatReply(
                transcript: store.chatTranscript,
                soulCommandments: soul,
                menuData: store.cachedParsedMenu
            )
            store.chatTranscript.append(reply)
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
            }
            resetIdleTimer()
            llmError = nil
        } catch {
            await MainActor.run {
                llmError = "Your Agent failed to respond. \(error.localizedDescription)"
                lastFailedAction = { await self.triggerDelegateLLMReply(restaurantName: restaurantName) }
            }
        }
    }

    private func triggerConsensusFound(rawText: String) {
        print("🎉 CONSENSUS REACHED. Shutting down chat and routing to Results!")
        isProcessingConsensus = true

        Task {
            do {
                let parser = ConsensusParserAgent()
                var combo = try await parser.parseConsensus(rawText: rawText, menuData: store.cachedParsedMenu)

                let visualizer = VisualizerAgent()
                let dishNames = combo.dishes.map { $0.originalName }.joined(separator: ", ")
                let imgURL = try? await visualizer.visualize(dishName: dishNames, culturalDescription: "A curated meal combination negotiated by experts")
                combo.imageURL = imgURL

                try await withThrowingTaskGroup(of: (Int, URL?).self) { group in
                    for (index, dish) in combo.dishes.enumerated() {
                        group.addTask {
                            let url = try? await visualizer.visualize(dishName: dish.originalName, culturalDescription: dish.description ?? "tasty")
                            return (index, url)
                        }
                    }
                    for try await (index, url) in group {
                        combo.dishes[index].imageURL = url
                    }
                }

                let finalSet = GroupRecommendationSet(combos: [combo])

                await MainActor.run {
                    withAnimation {
                        isProcessingConsensus = false
                        store.navigationPath.append(.groupResult(finalSet))
                    }
                }
            } catch {
                print("Failed to parse consensus string into structured data: \(error)")
                await MainActor.run {
                    withAnimation { isProcessingConsensus = false }
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer() }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Text(message.agentName)
                    .font(NodTheme.Typography.caption)
                    .foregroundColor(NodTheme.Cinematic.smokeGray)
                    .padding(.horizontal, 4)

                Text(message.text)
                    .padding(12)
                    .background(isMe ? NodTheme.Cinematic.amber : Color(white: 0.2))
                    .foregroundColor(isMe ? .black : .white)
                    .cornerRadius(isMe ? 18 : 14, corners: isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            }

            if !isMe { Spacer() }
        }
    }
}

// Helper Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
