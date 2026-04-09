import UIKit
import AVFoundation
import React

@available(iOS 13.0, *)
class DualCameraView: UIView, AVCaptureFileOutputRecordingDelegate {
    
    private let sessionQueue = DispatchQueue(label: "com.myapp.dualcam.sessionQueue", qos: .userInteractive)
    
    private var multicamSession: AVCaptureMultiCamSession?
    private var singleSession: AVCaptureSession?
    
    private var isDual = true
    private var isFront = false
    private var isRecording = false
    private var isMirrored = false
    private var currentFPS: Int = 30
    private var currentRes: String = "1080p"
    
    private let movieOutput = AVCaptureMovieFileOutput()
    private let mainPreviewLayer = AVCaptureVideoPreviewLayer()
    private let PiPPreviewLayer = AVCaptureVideoPreviewLayer()
    private let pipContainer = UIView()
    private let focusVisualizer = UIView()
    
    @objc var onRecordingStateChanged: RCTDirectEventBlock?
    
    
    @objc func setIsDualMode(_ dual: Bool) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isDual != dual {
                self.isDual = dual
                self.setupSessionInternal()
            }
        }
    }

    @objc func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isFront = !self.isFront
            self.setupSessionInternal()
        }
    }
    
    @objc func setFPS(_ fps: Int) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentFPS = fps
            self.applyCaptureSettings()
        }
    }

    @objc func setResolution(_ res: String) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentRes = res
            self.setupSessionInternal()
        }
    }

    @objc func setIsMirrored(_ mirrored: Bool) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isMirrored = mirrored
            self.applyCaptureSettings()
        }
    }
    
    @objc func toggleRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isRecording {
                self.movieOutput.stopRecording()
            } else {
                let path = NSTemporaryDirectory() + "\(Date().timeIntervalSince1970).mov"
                let url = URL(fileURLWithPath: path)
                self.movieOutput.startRecording(to: url, recordingDelegate: self)
            }
            self.isRecording = !self.isRecording
            DispatchQueue.main.async {
                self.onRecordingStateChanged?(["isRecording": self.isRecording])
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        sessionQueue.async { [weak self] in
            self?.setupSessionInternal()
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupUI() {
        backgroundColor = .black
        mainPreviewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(mainPreviewLayer)
        
        focusVisualizer.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        focusVisualizer.layer.borderColor = UIColor.systemYellow.cgColor
        focusVisualizer.layer.borderWidth = 1.5
        focusVisualizer.alpha = 0
        addSubview(focusVisualizer)
        
        pipContainer.backgroundColor = .black
        pipContainer.layer.cornerRadius = 8
        pipContainer.clipsToBounds = true
        pipContainer.layer.borderWidth = 1
        pipContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        addSubview(pipContainer)
        
        PiPPreviewLayer.videoGravity = .resizeAspectFill
        pipContainer.layer.addSublayer(PiPPreviewLayer)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mainPreviewLayer.frame = bounds
        
        // Fix Orientation to Portrait
        if let connection = mainPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if let pipConn = PiPPreviewLayer.connection, pipConn.isVideoOrientationSupported {
            pipConn.videoOrientation = .portrait
        }
        
        let pipWidth = bounds.width * 0.45
        let pipHeight = pipWidth * (9/16) 
        
        pipContainer.frame = CGRect(x: (bounds.width - pipWidth) / 2, 
                                   y: bounds.height - pipHeight - 170, 
                                   width: pipWidth, 
                                   height: pipHeight)
        PiPPreviewLayer.frame = pipContainer.bounds
    }
    
    
    private func setupSessionInternal() {
        if let multi = multicamSession, multi.isRunning { multi.stopRunning() }
        if let single = singleSession, single.isRunning { single.stopRunning() }
        multicamSession = nil
        singleSession = nil
        
        if isDual && AVCaptureMultiCamSession.isMultiCamSupported {
            setupMultiCamInternal()
        } else {
            setupSingleCamInternal()
        }
    }
    
    private func setupSingleCamInternal() {
        let session = AVCaptureSession()
        self.singleSession = session
        session.beginConfiguration()
        
        let position: AVCaptureDevice.Position = isFront ? .front : .back
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera]
        
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: position)
        guard let camera = discovery.devices.first,
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        // Resolution setting
        if currentRes == "4K" && session.canSetSessionPreset(.hd4K3840x2160) {
            session.sessionPreset = .hd4K3840x2160
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }
        
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        
        session.commitConfiguration()
        DispatchQueue.main.async {
            self.mainPreviewLayer.session = session
            self.pipContainer.isHidden = true
        }
        session.startRunning()
        applyCaptureSettings()
    }
    
    private func setupMultiCamInternal() {
        let session = AVCaptureMultiCamSession()
        self.multicamSession = session
        session.beginConfiguration()
        
        let primaryPos: AVCaptureDevice.Position = isFront ? .front : .back
        guard let primaryCam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: primaryPos),
              let primaryInput = try? AVCaptureDeviceInput(device: primaryCam) else {
            session.commitConfiguration()
            setupSingleCamInternal()
            return
        }
        
        if session.canAddInput(primaryInput) { 
            session.addInputWithNoConnections(primaryInput) 
        } else {
            session.commitConfiguration()
            setupSingleCamInternal()
            return
        }
        
        guard let primaryPort = primaryInput.ports.first(where: { $0.mediaType == .video }) else {
            session.commitConfiguration()
            return
        }
        let mainConnection = AVCaptureConnection(inputPort: primaryPort, videoPreviewLayer: mainPreviewLayer)
        if session.canAddConnection(mainConnection) { session.addConnection(mainConnection) }
  
        let secondaryPos: AVCaptureDevice.Position = isFront ? .back : .back
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified)
        let validSets = discoverySession.supportedMultiCamDeviceSets.filter { $0.contains(primaryCam) }
        

        var secondaryCam: AVCaptureDevice? = nil
        for deviceSet in validSets {
            if let candidate = deviceSet.first(where: { $0.position == secondaryPos && $0 != primaryCam }) {
                secondaryCam = candidate
                break
            }
        }
        
        if let secondCam = secondaryCam,
           let secondInput = try? AVCaptureDeviceInput(device: secondCam),
           let secondPort = secondInput.ports.first(where: { $0.mediaType == .video }) {
            
            if session.canAddInput(secondInput) {
                session.addInputWithNoConnections(secondInput)
                let pipConnection = AVCaptureConnection(inputPort: secondPort, videoPreviewLayer: PiPPreviewLayer)
                if session.canAddConnection(pipConnection) {
                    session.addConnection(pipConnection)
                    DispatchQueue.main.async { self.pipContainer.isHidden = false }
                }
            }
        } else {
            DispatchQueue.main.async { self.pipContainer.isHidden = true }
        }
        
        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.mainPreviewLayer.setSessionWithNoConnection(session)
            self.PiPPreviewLayer.setSessionWithNoConnection(session)
            self.bringSubviewToFront(self.pipContainer)
            self.bringSubviewToFront(self.focusVisualizer)
        }
        
        session.startRunning()
        applyCaptureSettings()
    }
    
    private func applyCaptureSettings() {
        let activeSession: AVCaptureSession? = isDual ? multicamSession : singleSession
        guard let session = activeSession else { return }
        
        session.beginConfiguration()
        for input in session.inputs {
            if let devInput = input as? AVCaptureDeviceInput {
                let device = devInput.device
                do {
                    try device.lockForConfiguration()
                    let duration = CMTime(value: 1, timescale: Int32(currentFPS))
                    if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= Double(currentFPS) }) {
                        device.activeVideoMinFrameDuration = duration
                        device.activeVideoMaxFrameDuration = duration
                    }
                    device.unlockForConfiguration()
                } catch {}
            }
        }
        
        // Handle Mirroring on Connections
        for connection in session.connections {
            if connection.isVideoMirroringSupported {
                // Biasanya mirroring cuma untuk kamera depan
                let isFrontConnection = session.inputs.contains { input in
                    if let devInput = input as? AVCaptureDeviceInput {
                        return devInput.device.position == .front
                    }
                    return false
                }
                connection.isVideoMirrored = isFrontConnection ? isMirrored : false
            }
        }
        
        session.commitConfiguration()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        showFocusCircle(at: location)
        let devicePoint = mainPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        focus(at: devicePoint)
    }
    
    private func showFocusCircle(at point: CGPoint) {
        focusVisualizer.center = point
        focusVisualizer.alpha = 1
        focusVisualizer.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.2, animations: {
            self.focusVisualizer.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: { self.focusVisualizer.alpha = 0 })
        }
    }
    
    private func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            let session: AVCaptureSession? = self?.isDual == true ? self?.multicamSession : self?.singleSession
            guard let inputs = session?.inputs else { return }
            for input in inputs {
                if let devInput = input as? AVCaptureDeviceInput {
                    let device = devInput.device
                    try? device.lockForConfiguration()
                    if device.isFocusPointOfInterestSupported {
                        device.focusPointOfInterest = point
                        device.focusMode = .autoFocus
                    }
                    if device.isExposurePointOfInterestSupported {
                        device.exposurePointOfInterest = point
                        device.exposureMode = .continuousAutoExposure
                    }
                    device.unlockForConfiguration()
                }
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {}
}
