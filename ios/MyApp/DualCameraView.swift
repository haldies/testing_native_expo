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
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            sessionQueue.async { [weak self] in
                self?.setupSessionInternal()
            }
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
        pipContainer.layer.cornerRadius = 12
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
        
        let pipWidth = bounds.width * 0.45
        let pipHeight = pipWidth * (9/16) 
        pipContainer.frame = CGRect(x: (bounds.width - pipWidth) / 2, 
                                   y: bounds.height - pipHeight - 170, 
                                   width: pipWidth, 
                                   height: pipHeight)
        PiPPreviewLayer.frame = pipContainer.bounds
        
        // Orientation
        if let connection = mainPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if let pipConn = PiPPreviewLayer.connection, pipConn.isVideoOrientationSupported {
            pipConn.videoOrientation = .portrait
        }
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
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
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
        
        // 1. Primary Camera (Wide)
        let primaryPos: AVCaptureDevice.Position = isFront ? .front : .back
        guard let wideCam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: primaryPos),
              let wideInput = try? AVCaptureDeviceInput(device: wideCam) else {
            session.commitConfiguration()
            setupSingleCamInternal()
            return
        }
        
        if session.canAddInput(wideInput) {
            session.addInputWithNoConnections(wideInput)
        }
        
        // 2. Secondary Camera (Front for Multi-Cam PIP or UltraWide if possible)
        // If front is requested as primary, secondary is back. If back wide is primary, secondary is back ultraWide or front.
        let secondPos: AVCaptureDevice.Position = isFront ? .back : (AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil ? .back : .front)
        let secondType: AVCaptureDevice.DeviceType = (secondPos == .back && !isFront) ? .builtInUltraWideCamera : .builtInWideAngleCamera
        
        guard let secondCam = AVCaptureDevice.default(secondType, for: .video, position: secondPos),
              let secondInput = try? AVCaptureDeviceInput(device: secondCam) else {
            session.commitConfiguration()
            setupSingleCamInternal()
            return
        }
        
        if session.canAddInput(secondInput) {
            session.addInputWithNoConnections(secondInput)
        }
        
        // Connections
        if let widePort = wideInput.ports.first(where: { $0.mediaType == .video }) {
            let conn = AVCaptureConnection(inputPort: widePort, videoPreviewLayer: mainPreviewLayer)
            if session.canAddConnection(conn) { session.addConnection(conn) }
        }
        
        if let secondPort = secondInput.ports.first(where: { $0.mediaType == .video }) {
            let conn = AVCaptureConnection(inputPort: secondPort, videoPreviewLayer: PiPPreviewLayer)
            if session.canAddConnection(conn) { session.addConnection(conn) }
        }
        
        if session.canAddOutput(movieOutput) {
            session.addOutputWithNoConnections(movieOutput)
            if let widePort = wideInput.ports.first(where: { $0.mediaType == .video }) {
                let conn = AVCaptureConnection(inputPorts: [widePort], output: movieOutput)
                if session.canAddConnection(conn) { session.addConnection(conn) }
            }
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.mainPreviewLayer.session = session
            self.PiPPreviewLayer.session = session
            self.pipContainer.isHidden = false
            self.bringSubviewToFront(self.pipContainer)
        }
        
        session.startRunning()
        applyCaptureSettings()
    }
    
    private func applyCaptureSettings() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let session: AVCaptureSession? = self.isDual ? self.multicamSession : self.singleSession
            guard let active = session else { return }
            
            active.beginConfiguration()
            for input in active.inputs {
                if let devInput = input as? AVCaptureDeviceInput {
                    let device = devInput.device
                    try? device.lockForConfiguration()
                    let duration = CMTime(value: 1, timescale: Int32(self.currentFPS))
                    if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= Double(self.currentFPS) }) {
                        device.activeVideoMinFrameDuration = duration
                        device.activeVideoMaxFrameDuration = duration
                    }
                    device.unlockForConfiguration()
                }
            }
            
            for connection in active.connections {
                if connection.isVideoMirroringSupported {
                    let isFrontConn = active.inputs.contains { input in
                        (input as? AVCaptureDeviceInput)?.device.position == .front
                    }
                    connection.isVideoMirrored = isFrontConn ? self.isMirrored : false
                }
            }
            active.commitConfiguration()
        }
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
        UIView.animate(withDuration: 0.2, animations: { self.focusVisualizer.transform = .identity }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: { self.focusVisualizer.alpha = 0 })
        }
    }
    
    private func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            let session: AVCaptureSession? = self?.isDual == true ? self?.multicamSession : self?.singleSession
            guard let inputs = session?.inputs else { return }
            for input in inputs {
                if let devInput = input as? AVCaptureDeviceInput {
                    try? devInput.device.lockForConfiguration()
                    if devInput.device.isFocusPointOfInterestSupported {
                        devInput.device.focusPointOfInterest = point
                        devInput.device.focusMode = .autoFocus
                    }
                    devInput.device.unlockForConfiguration()
                }
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL, from connections: [AVCaptureConnection], error: Error?) {}
}
