import SwiftUI

enum ForgeError: Error, Identifiable {
    case healthKit(String)
    case weather(String)
    case network(String)
    case ai(String)
    case unknown

    var id: String {
        self.localizedDescription
    }

    var localizedDescription: String {
        switch self {
        case .healthKit(let msg): return "Health Data Error: \(msg)"
        case .weather(let msg): return "Weather Sync Error: \(msg)"
        case .network(_): return "Network Error: Please check your connection."
        case .ai(let msg): return "AI Coach Error: \(msg)"
        case .unknown: return "An unexpected error occurred."
        }
    }

    var icon: String {
        switch self {
        case .healthKit: return "heart.slash.fill"
        case .weather: return "cloud.bolt.rain.fill"
        case .network: return "wifi.exclamationmark"
        case .ai: return "brain.head.profile"
        case .unknown: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Loading View (Shimmer)
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.gray.opacity(0.1)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.3), location: 0.5),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 2)
                .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Error Overlay
struct ErrorOverlay: View {
    let error: ForgeError
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: error.icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.purple, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
