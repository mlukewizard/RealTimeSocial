import UIKit
import AVFoundation

class FaceViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    
    var faces = [CGRect]()
    
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
    
    func increaseRect(rect: CGRect, byPercentage percentage: CGFloat) -> CGRect {
        let startWidth = rect.width
        let startHeight = rect.height
        let adjustmentWidth = (startWidth * (percentage+100)/100) / 2.0
        let adjustmentHeight = (startHeight * (percentage+100)/100) / 2.0
        return rect.insetBy(dx: -adjustmentWidth, dy: -adjustmentHeight)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {

            if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) {
                
                if let image = UIImage(data: dataImage) {
                    
                    //Currently always working in portrait
                    
                    let exactWidthHeight = ((faces[0].height)/380)*1080
                    let newMinX = (faces[0].minY/670)*1920
                    let newMinY = (((380-faces[0].minX)/380)*1080)-exactWidthHeight
                
                    var rect = CGRect(x: newMinX, y: newMinY, width: exactWidthHeight, height: exactWidthHeight)
                    
                    rect = increaseRect(rect: rect, byPercentage: 50)
                    
                    //NB origin of cgImage is in the top right!
                    var newimage = image.cgImage
                    newimage = newimage?.cropping(to: rect)
                    
                    let croppedImage = UIImage(cgImage: newimage!, scale: image.scale, orientation: .right)

                    UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
                }
            }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setupSession()
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
        
        //setupPreview()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        //setupFace()
        faceRectCALayer = CALayer()
        previewLayer.addSublayer(faceRectCALayer)
        
        //startSession()
        if !session.isRunning{
            session.startRunning()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        self.faces = [CGRect]()
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if metadataObject.type == AVMetadataObjectTypeFace {
                    let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                    let face = transformedMetadataObject?.bounds
                
                    faces.append(face!)
            }
        }
        
        self.faceRectCALayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        if self.faces.count > 0 {
            setlayerHidden(false)
            DispatchQueue.main.async(execute: {
                () -> Void in
                
                //Removes the squares from the last iteration
                for face in self.faces {
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
