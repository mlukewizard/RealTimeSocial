import UIKit
import AVFoundation

class FaceViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var faceRectCALayer: CALayer!
    
    fileprivate var currentCameraFace: AVCaptureDevice?
    fileprivate var sessionQueue: DispatchQueue = DispatchQueue(label: "videoQueue", attributes: [])
    
    fileprivate var session: AVCaptureSession!
    fileprivate var backCameraDevice: AVCaptureDevice?
    fileprivate var frontCameraDevice: AVCaptureDevice?
    fileprivate var metadataOutput: AVCaptureMetadataOutput!
    
    let photoOutput = AVCapturePhotoOutput() //This is from the picture taking code
    var videoDeviceInput: AVCaptureDeviceInput! //This is from the picture taking code
    
    @IBAction func TouchHappens(_ sender: UITapGestureRecognizer) {
        //let point = sender.location(in: self.view)
        //let x = point.x
        //let y = point.y
        //print(x)
        //print(y)
        
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) {
                
                if let image = UIImage(data: dataImage) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                }
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSession()
        setupPreview()
        setupFace()
        startSession()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Setup session and preview
    //This gets run onnly once at setup
    func setupSession(){
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        let avaliableCameraDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for device in avaliableCameraDevices as! [AVCaptureDevice]{
            if device.position == .back {
                backCameraDevice = device
            } else if device.position == .front{
                frontCameraDevice = device
            }
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCameraDevice)
            if session.canAddInput(input){
                session.addInput(input)
            }
        } catch {
            print("Error handling the camera Input: \(error)")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            print("Could not add photo output to the session")
        }
        


    }
    
    
    func setupPreview(){
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    
    func startSession() {
        if !session.isRunning{
            session.startRunning()
        }
    }
    
    func setupFace(){
        faceRectCALayer = CALayer()
        faceRectCALayer.zPosition = 1
        faceRectCALayer.borderColor = UIColor.red.cgColor
        faceRectCALayer.borderWidth = 3.0

        previewLayer.addSublayer(faceRectCALayer)
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        var faces = [CGRect]()
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if metadataObject.type == AVMetadataObjectTypeFace {
                    let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                    let face = transformedMetadataObject?.bounds
                    faces.append(face!)
            }
        }
        
        print("FACE",faces)
        self.faceRectCALayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        if faces.count > 0 {
            setlayerHidden(false)
            DispatchQueue.main.async(execute: {
                () -> Void in
                
                //Removes the squares from the last iteration
                for face in faces {
                    let newLayer = CALayer()
                    newLayer.zPosition = 1
                    newLayer.borderColor = UIColor.red.cgColor
                    newLayer.borderWidth = 3.0
                    newLayer.frame = face
                    self.faceRectCALayer.addSublayer(newLayer)
                }
            })
        } else {
            setlayerHidden(true)
        }
    }
    
    func setlayerHidden(_ hidden: Bool) {
        if (faceRectCALayer.isHidden != hidden){
            print("hidden:" ,hidden)
            DispatchQueue.main.async(execute: { 
                () -> Void in
                self.faceRectCALayer.isHidden = hidden
            })
        }
    }
    

}
