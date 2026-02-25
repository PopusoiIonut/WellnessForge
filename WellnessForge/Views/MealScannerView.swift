import SwiftUI
import AVFoundation
import Vision

struct MealScannerView: View {
    @StateObject private var nutritionService = NutritionService()
    @State private var isScanning = true
    @EnvironmentObject var planVM: PlanViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background: Camera Preview or Placeholder
                #if targetEnvironment(simulator)
                Color.black.overlay(
                    Text("Camera Not Available in Simulator")
                        .foregroundStyle(.secondary)
                )
                .ignoresSafeArea()
                #else
                CameraPreview(nutritionService: nutritionService)
                    .ignoresSafeArea()
                #endif
                
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title3.bold())
                                .padding()
                                .background(.ultraThinMaterial, in: Circle())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        
                        #if targetEnvironment(simulator)
                        // Simulation Button for Testing
                        Button(action: {
                            simulateDiscovery()
                        }) {
                            Text("Simulate Scan")
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.yellow, in: Capsule())
                                .foregroundStyle(.black)
                        }
                        #endif
                    }
                    .padding()
                    
                    Spacer()
                    
                    if let item = nutritionService.detectedItem {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Detected Item")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .tracking(2)
                                Spacer()
                            }
                            
                            HStack(alignment: .bottom) {
                                Text(item.name)
                                    .font(.title2.bold())
                                Spacer()
                                Text("\(item.calories) kcal")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 20) {
                                NutritionMiniTile(label: "Pro", value: "\(item.protein)g")
                                NutritionMiniTile(label: "Carb", value: "\(item.carbs)g")
                                NutritionMiniTile(label: "Fat", value: "\(item.fats)g")
                            }
                            .padding(.vertical, 8)
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                let log = LoggedMeal(
                                    name: item.name,
                                    calories: item.calories,
                                    protein: item.protein,
                                    carbs: item.carbs,
                                    fats: item.fats
                                )
                                modelContext.insert(log)
                                dismiss()
                            }) {
                                Text("Add to Daily Log")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.yellow)
                            Text("Analyzing Frame...")
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.8))
                            
                            if !nutritionService.rawLabel.isEmpty {
                                Text(nutritionService.rawLabel)
                                    .font(.system(size: 8).monospaced())
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func simulateDiscovery() {
        // In simulation, we just pick a known key
        let items = ["apple", "banana", "egg", "chicken_breast", "salad", "pizza"]
        if let randomItem = items.randomElement(), let item = nutritionService.foodDatabase[randomItem] {
            DispatchQueue.main.async {
                nutritionService.detectedItem = item
            }
        }
    }
}

struct NutritionMiniTile: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Camera Bridge
struct CameraPreview: UIViewRepresentable {
    let nutritionService: NutritionService
    
    func makeUIView(context: Context) -> CameraUIView {
        let view = CameraUIView()
        view.nutritionService = nutritionService
        return view
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {}
}

class CameraUIView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    var nutritionService: NutritionService?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraQueue = DispatchQueue(label: "com.wellnessforge.camera_queue", qos: .userInitiated)
    private var lastProcessingTime: TimeInterval = 0
    private let processingInterval: TimeInterval = 0.2 // Throttle to 5 FPS
    
    private static var sharedModel: VNCoreMLModel? = nil // Deprecated in favor of system classifier
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.cameraQueue)
            if self.captureSession.canAddOutput(output) {
                self.captureSession.addOutput(output)
            }
            
            self.captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.bounds
                self.layer.addSublayer(preview)
                self.previewLayer = preview
            }
            
            self.captureSession.startRunning()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessingTime >= processingInterval else { return }
        lastProcessingTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let orientation: CGImagePropertyOrientation
        switch UIDevice.current.orientation {
        case .landscapeLeft: orientation = .up
        case .landscapeRight: orientation = .down
        case .portraitUpsideDown: orientation = .left
        default: orientation = .right
        }

        let request = VNClassifyImageRequest { [weak self] req, _ in
            if let results = req.results as? [VNClassificationObservation] {
                self?.nutritionService?.processClassifications(results)
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:]).perform([request])
    }
}
