import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    let features = [
        ("Apple Intelligence Coaching", "brain.head.profile"),
        ("Vision Meal Scanner", "camera.viewfinder"),
        ("AR Workout Posture Guide", "arkit"),
        ("iCloud Sync & Widgets", "cloud.fill")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background Gradient
            LinearGradient(colors: [.purple.opacity(0.3), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    Text("Unlock WellnessForge PRO")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .scaleEffect(appearAnimate ? 1.0 : 0.9)
                        .opacity(appearAnimate ? 1.0 : 0)
                    
                    Text("Elevate your health journey with advanced AI tools.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimate ? 1.0 : 0)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(0..<features.count, id: \.self) { index in
                        let item = features[index]
                        HStack(spacing: 15) {
                            Image(systemName: item.1)
                                .foregroundStyle(.purple)
                                .font(.title3)
                                .frame(width: 30)
                            Text(item.0)
                                .foregroundStyle(.white)
                                .font(.body)
                        }
                        .offset(x: appearAnimate ? 0 : -20)
                        .opacity(appearAnimate ? 1.0 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: appearAnimate)
                    }
                }
                .padding()
                .background(.white.opacity(0.08))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal)
                
                Spacer()

                if storeManager.isLoading {
                    ProgressView().tint(.white)
                } else if let error = storeManager.fetchError {
                    VStack(spacing: 12) {
                        Text("Store Unavailable")
                            .font(.headline).foregroundStyle(.red)
                        Text(error)
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // --- SIMULATOR FALLBACK UI ---
                        if storeManager.mockFallbackAvailable {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                // Simulator mock - just dismiss as if purchased
                                storeManager.purchasedSubscriptions.append("wellness_pro_yearly")
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Yearly Pro (Simulator Mock)")
                                            .font(.headline)
                                        Text("Unlock all AI and AR features yearly.")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("$39.99")
                                        .font(.headline)
                                        .foregroundStyle(.purple)
                                }
                                .padding()
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)
                        } else {
                            Button(action: {
                                Task { await storeManager.fetchProducts() }
                            }) {
                                Text("Retry Connection")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(.white.opacity(0.1), in: Capsule())
                            }
                        }
                        // --- END SIMULATOR FALLBACK UI ---
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(storeManager.subscriptions) { product in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                Task {
                                    try? await storeManager.buy(product)
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.displayName)
                                            .font(.headline)
                                        Text(product.description)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.headline)
                                        .foregroundStyle(.purple)
                                }
                                .padding()
                                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(storeManager.purchasedSubscriptions.contains(product.id) ? Color.purple : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(storeManager.purchasedSubscriptions.contains(product.id))
                        }
                        
                        if !storeManager.isPremium {
                            Text("Choose a plan to continue.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Button("Continue to App") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing), in: Capsule())
                        }
                    }
                }
                
                Button("Restore Purchases") {
                    Task { await storeManager.updatePurchasedProducts() }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            }
            .padding(.horizontal)
            .opacity(appearAnimate ? 1.0 : 0)
            
            Text("Cancel anytime. Terms of Service & Privacy Policy apply.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.bottom)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appearAnimate = true
            }
            if storeManager.subscriptions.isEmpty {
                Task { await storeManager.fetchProducts() }
            }
        }
    }
    
    @State private var appearAnimate = false
}
