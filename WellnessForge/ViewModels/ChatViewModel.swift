import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: ForgeError? = nil
    
    private let aiService = AIModelService()

    init() {
        let welcome = AIMessage(role: AIMessage.Role.assistant, content: "Hey! 👋 I'm your WellnessForge AI Coach. Ask me anything about your health, energy, sleep, or workout plan.")
        messages.append(welcome)
    }

    func send(snapshot: HealthSnapshot, user: UserProfile?) {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        let userMsg = AIMessage(role: AIMessage.Role.user, content: userText)
        messages.append(userMsg)
        inputText = ""
        Task {
            await MainActor.run { self.isLoading = true }
            let reply = await aiService.generateResponse(to: userText, healthSnapshot: snapshot, user: user)
            await MainActor.run {
                self.messages.append(AIMessage(role: .assistant, content: reply))
                self.isLoading = false
            }
        }
    }
}

