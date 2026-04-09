import UIKit
import AVFoundation

@available(iOS 13.0, *)
class DualCameraView: UIView {
    private var session: AVCaptureMultiCamSession?
    private let mainPreviewLayer = AVCaptureVideoPreviewLayer()
    private let PiPPreviewLayer = AVCaptureVideoPreviewLayer()
    
    private let pipContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupSession()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        
        // Main full screen preview
        mainPreviewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(mainPreviewLayer)
        
        // PiP (Picture in Picture) container
        pipContainer.backgroundColor = .darkGray
        pipContainer.layer.cornerRadius = 12
        pipContainer.clipsToBounds = true
        pipContainer.layer.borderWidth = 2
        pipContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        addSubview(pipContainer)
        
        PiPPreviewLayer.videoGravity = .resizeAspectFill
        pipContainer.layer.addSublayer(PiPPreviewLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mainPreviewLayer.frame = bounds
        
        let pipWidth = bounds.width * 0.4
        let pipHeight = pipWidth * (3/4) // 4:3 ratio
        pipContainer.frame = CGRect(x: bounds.width - pipWidth - 20, 
                                   y: bounds.height - pipHeight - 120, 
                                   width: pipWidth, 
                                   height: pipHeight)
        PiPPreviewLayer.frame = pipContainer.bounds
    }
    
    private func setupSession() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("MultiCam not supported on this device")
            return
        }
        
        let session = AVCaptureMultiCamSession()
        self.session = session
        
        session.beginConfiguration()
        
        // 1. Wide Angle Camera (Main)
        guard let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let wideInput = try? AVCaptureDeviceInput(device: wideCamera) else { return }
        
        if session.canAddInput(wideInput) {
            session.addInputWithNoConnections(wideInput)
        }
        
        // 2. Ultra Wide Camera (Secondary/PiP)
        guard let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
              let ultraWideInput = try? AVCaptureDeviceInput(device: ultraWideCamera) else { return }

        if session.canAddInput(ultraWideInput) {
            session.addInputWithNoConnections(ultraWideInput)
        }
        
        // Connect Wide to Main Preview
        let widePort = wideInput.ports.first(where: { $0.mediaType == .video })!
        let mainConnection = AVCaptureConnection(inputPort: widePort, videoPreviewLayer: mainPreviewLayer)
        if session.canAddConnection(mainConnection) {
            session.addConnection(mainConnection)
        }
        
        // Connect UltraWide to PiP Preview
        let ultraWidePort = ultraWideInput.ports.first(where: { $0.mediaType == .video })!
        let pipConnection = AVCaptureConnection(inputPort: ultraWidePort, videoPreviewLayer: PiPPreviewLayer)
        if session.canAddConnection(pipConnection) {
            session.addConnection(pipConnection)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stopSession() {
        session?.stopRunning()
    }
    
    deinit {
        stopSession()
    }
}
