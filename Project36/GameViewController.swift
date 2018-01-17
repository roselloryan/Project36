 
import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    
    var gameInProgress = true
    
    var stopCount = 0
    var blinkCount = 0
    var smileCount = 0
    
    var isInMidBlink = false
    var isInMidSmile = false
    
    var facialFeaturePreference = FacialFeature.smile
    
    var parentFrame: CGRect!
    
    var session: AVCaptureSession?
    var stillOutput = AVCapturePhotoOutput()
    var borderLayer: CAShapeLayer?
    
    
    
    let detailsView: DetailsView = {
        let detailsView = DetailsView()
        detailsView.isUserInteractionEnabled = false
        detailsView.setup()
        
        return detailsView
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        
        var previewLay = AVCaptureVideoPreviewLayer(session: self.session!)
        previewLay.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        return previewLay
    }()
    
    lazy var frontCamera: AVCaptureDevice? = {
        
        let discoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: AVCaptureDevice.Position.front)
        
        return discoverySession.devices.count > 0 ? discoverySession.devices.first : nil
    }()
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
    
    
    
    
    //MARK: - Life Cylcle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = GameScene(fileNamed: "GameScene") {
                
                // Set the scale mode to scale to fit the window
//                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
//            view.showsPhysics = true
        }
        
        
        // For face tracking //
        sessionPrepare()
        session?.startRunning()
        
        parentFrame = self.view.frame
    
        
        addNotificationObservers()
    }
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggleFacialFeaturePreference), name: Notification.Name("toggleFacialFeaturePreference"), object: nil)
    }
    
    @objc func toggleFacialFeaturePreference() {
        
        if facialFeaturePreference == .smile {
            facialFeaturePreference = .blink
        }
        else {
                facialFeaturePreference = .smile
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - Methods for face tracking
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.addSubview(detailsView)
        view.bringSubview(toFront: detailsView)
        
        /////// Uncertain if will have preview option //////////////
        //        guard let previewLayer = previewLayer else { return }
        //        view.layer.addSublayer(previewLayer)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.frame
    }
    
    func sessionPrepare() {
        session = AVCaptureSession()
        
        guard let session = session, let captureDevice = frontCamera else { return }
        
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }
}

class DetailsView: UIView {
    
    lazy var detailsLabel: UILabel = {
        let detailsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        detailsLabel.numberOfLines = 0
        detailsLabel.textColor = .white
        detailsLabel.font = UIFont.systemFont(ofSize: 18.0)
        detailsLabel.textAlignment = .left
        
        return detailsLabel
    }()
    
    func setup() {
        layer.borderColor = UIColor.blue.withAlphaComponent(0.7).cgColor
        layer.borderWidth = 5.0
        
        addSubview(detailsLabel)
    }
    
    override var frame: CGRect {
        didSet(newFrame) {
            var detailsFrame = detailsLabel.frame
            detailsFrame = CGRect(x: 0, y: newFrame.size.height, width: newFrame.size.width * 2.0, height: newFrame.size.height / 2.0)
            detailsLabel.frame = detailsFrame
        }
    }
}


extension GameViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        
        let options: [String : Any] = [CIDetectorImageOrientation: 6,
                                       CIDetectorSmile: true,
                                       CIDetectorEyeBlink: true]
        
        
        let allFeatures = faceDetector?.features(in: ciImage, options: options)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        guard let features = allFeatures else { return }
        
        for feature in features {
            if let faceFeature = feature as? CIFaceFeature {
                
                let faceRect = calculateFaceRect(facePosition: faceFeature.mouthPosition, faceBounds: faceFeature.bounds, clearAperture: cleanAperture)
                
                
                
                if gameInProgress {
            
                    if facialFeaturePreference == .smile {
                        smileCheck(faceFeature: faceFeature)
                    }
                    else {
                        blinkCheck(faceFeature: faceFeature)
                    }
                }
                
                update(with: faceRect)
            }
        }
        
        if features.count == 0 {
            DispatchQueue.main.async {
                self.detailsView.alpha = 0.0
            }
        }
        
    }
    
    
    func blinkCheck(faceFeature: CIFaceFeature) {
        
        if faceFeature.leftEyeClosed && faceFeature.rightEyeClosed && !isInMidBlink {
            // Start of blink
            blinkCount += 1
            isInMidBlink = true
            
            if let view = self.view as? SKView {
                view.touchesBegan([UITouch.init()], with: nil)
            }
        }
        else if faceFeature.leftEyeClosed && faceFeature.rightEyeClosed && isInMidBlink {
            // Mid blink, do nothing
        }
        else {
            isInMidBlink = false
        }
        
    }

    func smileCheck(faceFeature: CIFaceFeature) {
        
        if faceFeature.hasSmile {
            if let view = self.view as? SKView {
                view.touchesBegan([UITouch.init()], with: nil)
            }
        }
    }
    
    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSize.zero
        
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width
            size.height = apertureSize.width * (frameSize.width / apertureSize.height)
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width)
            size.height = frameSize.height
        }
        
        var videoBox = CGRect(origin: .zero, size: size)
        
        if (size.width < frameSize.width) {
            videoBox.origin.x = (frameSize.width - size.width) / 2.0
        } else {
            videoBox.origin.x = (size.width - frameSize.width) / 2.0
        }
        
        if (size.height < frameSize.height) {
            videoBox.origin.y = (frameSize.height - size.height) / 2.0
        } else {
            videoBox.origin.y = (size.height - frameSize.height) / 2.0
        }
        
        return videoBox
    }
    
    func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
        //        let parentFrameSize = previewLayer!.frame.size
        let parentFrameSize = parentFrame.size
        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)
        
        var faceRect = faceBounds
        
        swap(&faceRect.size.width, &faceRect.size.height)
        swap(&faceRect.origin.x, &faceRect.origin.y)
        
        let widthScaleBy = previewBox.size.width / clearAperture.size.height
        let heightScaleBy = previewBox.size.height / clearAperture.size.width
        
        faceRect.size.width *= widthScaleBy
        faceRect.size.height *= heightScaleBy
        faceRect.origin.x *= widthScaleBy
        faceRect.origin.y *= heightScaleBy
        
        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
        let frame = CGRect(x: parentFrameSize.width - faceRect.origin.x - faceRect.size.width / 2.0 - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
        
        return frame
    }
}

extension GameViewController {

    func update(with faceRect: CGRect) {
        
        DispatchQueue.main.async { [unowned self] in
            UIView.animate(withDuration: 0.3) { [unowned self] in

                self.detailsView.alpha = 1.0
                self.detailsView.frame = faceRect
            }
        }
    }
    
}


