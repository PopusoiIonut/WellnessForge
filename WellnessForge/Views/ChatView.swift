import SwiftUI
import SwiftData

struct ChatView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var healthKit: HealthKitService
    @FocusState private var isTextFieldFocused: Bool
    
    @Query private var users: [UserProfile]
    var user: UserProfile? { users.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatVM.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatVM.isLoading {
                                ThinkingBubble()
                                    .id("thinking")
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                    .onChange(of: chatVM.messages.count) {
                        withAnimation {
                            proxy.scrollTo(chatVM.messages.last?.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    TextField("Ask WellnessForge Coach…", text: $chatVM.inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .focused($isTextFieldFocused)
                    
                    Button {
                        chatVM.send(snapshot: healthKit.snapshot, user: user)
                        isTextFieldFocused = false // Dismiss keyboard after sending
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(chatVM.inputText.isEmpty ? Color.secondary : Color.purple)
                    }
                    .disabled(chatVM.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                if let error = chatVM.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == .user ? Color.purple : Color(.secondarySystemBackground))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(ChatBubbleShape(isUser: message.role == .user))
            
            if message.role == .assistant { Spacer() }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, isUser ? .bottomLeft : .bottomRight], cornerRadii: CGSize(width: 18, height: 18))
        return Path(path.cgPath)
    }
}

struct ThinkingBubble: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(dotCount % 4 > index ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onReceive(timer) { _ in
                dotCount += 1
            }
            Spacer()
        }
    }
}
