import SwiftUI

struct AgentChatView: View {
    @Bindable var store: AppStore
    var isHost: Bool
    
    // Internal States
    @State private var hasStartedChat = false
    @State private var typingAgent: String? = nil
    @State private var isProcessingConsensus = false

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
                                
                                if let typing = typingAgent {
                                    HStack {
                                        if typing.contains("Host") { Spacer() }
                                        Text("\(typing) is typing...")
                                            .font(.caption)
                                            .italic()
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.horizontal)
                                            .transition(.opacity)
                                        if !typing.contains("Host") { Spacer() }
                                    }
                                    .id("TYPING_INDICATOR")
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
                        .onChange(of: typingAgent) {
                            withAnimation {
                                proxy.scrollTo("TYPING_INDICATOR", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            if isProcessingConsensus {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(AmbrosiaTheme.Cinematic.amber)
                        Text("Drafting final order...")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
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
                
                if isHost {
                    if msg.isFinalConsensus {
                        triggerConsensusFound(rawText: msg.text)
                    } else if !msg.agentName.contains("Host") {
                        // Host replies to Delegate messages
                        typingAgent = "Host Moderator"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        typingAgent = nil
                        await triggerHostLLMReply()
                    }
                } else {
                    if msg.isFinalConsensus {
                         triggerConsensusFound(rawText: msg.text)
                    } else if msg.agentName.contains("Host") {
                        // Delegate replies strictly to the Host's prompts
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
                // Delegate waits for the Host's first chatMessage to arrive before speaking.
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
            restaurantName: store.cachedParsedMenu?.metadata.restaurantName ?? "This Restaurant",
            serializedMenuData: menuBytes,
            requiredDishCount: 3
        )
        if let payloadData = try? JSONEncoder().encode(soulPayload) {
            let env = A2APayload(type: .soulBroadcast, senderID: UUID(), data: payloadData)
            try? store.chatManager.broadcast(payload: env)
        }
        
        // Host kickstarts the conversation with the first LLM prompt
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
        
        if let reply = try? await agent.generateChatReply(transcript: store.chatTranscript, soulCommandments: soul, menuData: store.cachedParsedMenu) {
            store.chatTranscript.append(reply)
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
            }
            if reply.isFinalConsensus {
                triggerConsensusFound(rawText: reply.text)
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
        
        if let reply = try? await agent.generateChatReply(transcript: store.chatTranscript, soulCommandments: soul, menuData: store.cachedParsedMenu) {
            store.chatTranscript.append(reply)
            if let bData = try? JSONEncoder().encode(reply) {
                let env = A2APayload(type: .chatMessage, senderID: UUID(), data: bData)
                try? store.chatManager.broadcast(payload: env)
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
