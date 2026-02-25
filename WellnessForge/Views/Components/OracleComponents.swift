import SwiftUI

struct OracleForecastCard: View {
    let oracle: OracleReading
    @State private var isAnimating = false
    
    var color: Color {
        switch oracle.mood {
        case .peak: return .purple
        case .steady: return .green
        case .recovery: return .orange
        case .rest: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: oracle.mood.icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .symbolEffect(.bounce, value: isAnimating)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(oracle.headline)
                        .font(.headline)
                        .foregroundStyle(color)
                    Text("AI-Derived Health Forecast")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .kerning(1)
                        .textCase(.uppercase)
                }
                
                Spacer()
            }
            
            Text(oracle.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Label(oracle.actionTip, systemImage: "sparkles")
                    .font(.caption).bold()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                )
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct DirectiveRow: View {
    let directive: ForgeDirective
    
    var color: Color {
        switch directive.color {
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "red": return .red
        default: return .primary
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: directive.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(directive.title)
                    .font(.subheadline).bold()
                Text(directive.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}
