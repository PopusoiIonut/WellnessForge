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
                                withAnimation {
                                    self.isLocalPurchasing = true
                                }
                                
                                Task {
                                    // Artificial delay for verification
                                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                                    
                                    await MainActor.run {
                                        storeManager.purchasedSubscriptions.append("wellness_pro_yearly")
                                        withAnimation {
                                            self.isLocalPurchasing = false
                                        }
                                        dismiss()
                                    }
                                }
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
                                .contentShape(RoundedRectangle(cornerRadius: 16))
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
                                withAnimation {
                                    self.isLocalPurchasing = true
                                }
                                Task {
                                    do {
                                        try await storeManager.buy(product)
                                        if storeManager.isPremium {
                                            dismiss()
                                        }
                                    } catch {
                                        self.purchaseError = error.localizedDescription
                                        self.showError = true
                                    }
                                    withAnimation {
                                        self.isLocalPurchasing = false
                                    }
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
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .disabled(storeManager.purchasedSubscriptions.contains(product.id) || storeManager.isPurchasing)
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
                .disabled(storeManager.isPurchasing)
            }
            .padding(.horizontal)
            .opacity(appearAnimate ? 1.0 : 0)
            .blur(radius: storeManager.isPurchasing ? 3 : 0)
            
            if storeManager.isPurchasing || isLocalPurchasing {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(2.0)
                            .padding()
                        
                        Text("Connecting to App Store...")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("Please do not close the app.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20)
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            VStack(spacing: 8) {
                Text("A purchase will be applied to your iTunes account on confirmation. Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime with your iTunes account settings. For more information, see our Terms of Use and Privacy Policy.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .padding(.vertical, 8)
                    Text("•")
                    Link("Privacy Policy", destination: URL(string: "https://github.com/PopusoiIonut/WellnessForge/blob/main/privacypolicy.txt")!)
                        .padding(.vertical, 8)
                }
                .font(.caption)
                .foregroundStyle(.purple)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = purchaseError {
                Text(error)
            }
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
    @State private var showError = false
    @State private var purchaseError: String? = nil
    @State private var isLocalPurchasing = false
}
