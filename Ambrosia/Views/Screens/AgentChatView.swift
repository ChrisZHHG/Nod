import SwiftUI

struct AgentChatView: View {
    @Bindable var store: AppStore
    var isHost: Bool
    
    // Internal States
    @State private var hasStartedChat = false

    var body: some View {
        ZStack {
            AmbrosiaTheme.Cinematic.deepBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(isHost ? "Host Lobby" : "Table Lobby")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if !hasStartedChat && isHost {
                        Button("Start Negotiation") {
                            startAIChat()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AmbrosiaTheme.Cinematic.amber)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                
                if !hasStartedChat {
                    // pre-chat Lobby View
                    VStack(spacing: 20) {
                        Spacer()
                        if isHost {
                            ProgressView("Advertising to nearby friends...")
                                .tint(AmbrosiaTheme.Cinematic.amber)
                                .foregroundColor(.white)
                            
                            Text("Connected Delegates: \(store.chatManager.connectedPeers.count)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(store.chatManager.connectedPeers, id: \.self) { peer in
                                Text(peer.displayName)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        } else {
                            Text("Waiting for Host to start...")
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .tint(.white)
                                .padding()
                            
                            if !store.chatManager.availableHosts.isEmpty {
                                Text("Select Host to Join:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                                ForEach(store.chatManager.availableHosts, id: \.self) { host in
                                    Button(action: {
                                        store.chatManager.joinHost(host)
                                    }) {
                                        Text(host.displayName)
                                            .padding()
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                } else {
                    // Active Chat View (The Spectator UI)
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(store.chatTranscript) { msg in
                                    ChatBubble(message: msg, isMe: msg.agentName.contains("Host"))
                                        .id(msg.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: store.chatTranscript.count) {
                            if let last = store.chatTranscript.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
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
                
                // If Host, and we just received a message from a Delegate, the Host must reply
                if isHost {
                    if msg.isFinalConsensus {
                        triggerConsensusFound()
                    } else {
                        await triggerHostLLMReply()
                    }
                } else {
                    // If Delegate, check if this message demands a response from us.
                    // For simplicity, everyone replies when Host prompts, but to avoid infinite loops, we need a turn-based system.
                    // The Host calls out who should speak, but in our design, delegates speak when they hear the Host.
                    // We'll wire up the LLM integration in the next step.
                    if msg.isFinalConsensus {
                         triggerConsensusFound()
                    }
                }
            case .soulBroadcast:
                let soulData = try JSONDecoder().decode(SoulBroadcastPayload.self, from: payload.data)
                hasStartedChat = true
                store.cachedParsedMenu = try JSONDecoder().decode(MenuData.self, from: soulData.serializedMenuData)
                // The Delegate LLM should now speak based on this injection
                await triggerDelegateLLMReply(soulRules: soulData.moderatorSoulRules)
            default: break
            }
        } catch {
            print("Failed decoding payload: \(error)")
        }
    }
    
    @MainActor
    private func startAIChat() {
        hasStartedChat = true
        // Host broadcasts the Soul and Menu to all delegates to begin
        let menuBytes = (try? JSONEncoder().encode(store.cachedParsedMenu)) ?? Data()
        let soulPayload = SoulBroadcastPayload(
            moderatorSoulRules: AgentSoul.hostModeratorCommandments,
            serializedMenuData: menuBytes,
            requiredDishCount: 3
        )
        if let payloadData = try? JSONEncoder().encode(soulPayload) {
            let env = A2APayload(type: .soulBroadcast, senderID: UUID(), data: payloadData)
            try? store.chatManager.broadcast(payload: env)
        }
        
        // Host kickstarts the conversation with the first LLM prompt
        Task {
            await triggerHostLLMReply()
        }
    }
    
    private func triggerHostLLMReply() async {
        let agent = ModeratorAgent()
        if let reply = try? await agent.generateChatReply(transcript: store.chatTranscript, soulCommandments: AgentSoul.hostModeratorCommandments, menuData: store.cachedParsedMenu) {
            store.chatTranscript.append(reply)
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
            }
            if reply.isFinalConsensus {
                triggerConsensusFound()
            }
        }
    }
    
    private func triggerDelegateLLMReply(soulRules: String) async {
        let agent = DelegateAgent(profile: store.individualProfile, delegateName: UIDevice.current.name)
        if let reply = try? await agent.generateChatReply(transcript: store.chatTranscript, soulCommandments: AgentSoul.delegateCommandments, menuData: store.cachedParsedMenu) {
            store.chatTranscript.append(reply)
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
            }
        }
    }
    
    private func triggerConsensusFound() {
        print("🎉 CONSENSUS REACHED. Shutting down chat and routing to Results!")
        // Process the final dishes. This logic connects the Chat to the GroupResultView
        // We will fake a RecommendationSet for now or parse the text to generate the final Output.
        // store.navigationPath.append(.groupResult(...))
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
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 4)
                
                Text(message.text)
                    .padding(12)
                    .background(isMe ? AmbrosiaTheme.Cinematic.amber : Color(white: 0.2))
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
