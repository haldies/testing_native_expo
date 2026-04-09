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
        if AVCaptureMultiCamSession.isMultiCamSupported {
            setupMultiCamSession()
        } else {
            setupSingleCamSession()
        }
    }
    
    private func setupSingleCamSession() {
        let singleSession = AVCaptureSession()
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
              
        if singleSession.canAddInput(input) {
            singleSession.addInput(input)
        }
        
        mainPreviewLayer.session = singleSession
        pipContainer.isHidden = true // Sembunyikan PiP jika tidak support dual camera
        
        DispatchQueue.global(qos: .userInitiated).async {
            singleSession.startRunning()
        }
    }
    
    private func setupMultiCamSession() {
        let session = AVCaptureMultiCamSession()
        self.session = session
        
        session.beginConfiguration()
        
        // 1. Setup Main Camera (Wide)
        guard let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let wideInput = try? AVCaptureDeviceInput(device: wideCamera) else { return }
        
        if session.canAddInput(wideInput) {
            session.addInputWithNoConnections(wideInput)
        }
        
        mainPreviewLayer.setSessionWithNoConnection(session)
        let widePort = wideInput.ports.first(where: { $0.mediaType == .video })!
        let mainConnection = AVCaptureConnection(inputPort: widePort, videoPreviewLayer: mainPreviewLayer)
        if session.canAddConnection(mainConnection) {
            session.addConnection(mainConnection)
        }
        
        // 2. Setup PiP Camera (UltraWide or Tele)
        let secondaryDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) ?? 
                              AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
                              
        if let secondCam = secondaryDevice,
           let ultraWideInput = try? AVCaptureDeviceInput(device: secondCam) {
            
            if session.canAddInput(ultraWideInput) {
                session.addInputWithNoConnections(ultraWideInput)
                
                PiPPreviewLayer.setSessionWithNoConnection(session)
                let ultraWidePort = ultraWideInput.ports.first(where: { $0.mediaType == .video })!
                let pipConnection = AVCaptureConnection(inputPort: ultraWidePort, videoPreviewLayer: PiPPreviewLayer)
                
                if session.canAddConnection(pipConnection) {
                    session.addConnection(pipConnection)
                    pipContainer.isHidden = false
                }
            }
        } else {
            pipContainer.isHidden = true
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
