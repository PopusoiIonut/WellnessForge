import SwiftUI
import RealityKit
import ARKit

struct WorkoutARView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white, .ultraThinMaterial)
                    }
                    .padding()
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Yoga Posture Guide")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Align your posture with the pulse")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .scaleEffect(isAligned ? 1.5 : 1.0)
                        .opacity(isAligned ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isAligned)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            }
        }
    }
    
    @State private var isAligned = false
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Standard AR Configuration
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Place a pulsating virtual guide
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.1, 0.1])
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .purple.withAlphaComponent(0.6), isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // Scale pulse for visual 'breathing'
        var scaleTransform = model.transform
        scaleTransform.scale = [1.5, 1.5, 1.5]
        
        anchor.addChild(model)
        arView.scene.addAnchor(anchor)
        
        model.move(to: scaleTransform, relativeTo: model, duration: 2.0, timingFunction: .easeInOut)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

