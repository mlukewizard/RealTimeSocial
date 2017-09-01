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
        //from here "func capture(_ captureOutput: AVCapturePhotoOutput, didFinishPro..." is called
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
                    
                    var croppedImage = UIImage(cgImage: newimage!, scale: image.scale, orientation: .right)
                    
                    //UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
                    croppedImage = croppedImage.image(withRotation: 3*3.14159/2)
                    let ImagePNG = UIImagePNGRepresentation(croppedImage)
                    let imageData:NSData = ImagePNG! as NSData
                    let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                    print("imagestart")
                    print(strBase64)
                    print("imageend")
                    
                }
            }
    }
    
    //Expands the bounds of the rectangle to get all of the face in the picture
    func increaseRect(rect: CGRect, byPercentage percentage: CGFloat) -> CGRect {
        let startWidth = rect.width
        let startHeight = rect.height
        let adjustmentWidth = (startWidth * (percentage+100)/100) / 2.0
        let adjustmentHeight = (startHeight * (percentage+100)/100) / 2.0
        return rect.insetBy(dx: -adjustmentWidth, dy: -adjustmentHeight)
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
            DispatchQueue.main.async(execute: {
                () -> Void in
                self.faceRectCALayer.isHidden = hidden
            })
        }
    }
    
    //-------------------------------------------------------
    //----This is where the face detection wrappers start----
    //-------------------------------------------------------
    func GetGalleryIDs(GetGalleryIDsCallBack:@escaping (String) -> ()) {
        let url = URL(string: "https://api.kairos.com/gallery/view")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        
        request.httpBody = "{\n  \"gallery_name\": \"MyGallery\"\n}".data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //if let response = response, let data = data {
            if let data = data {
                GetGalleryIDsCallBack(String(data: data, encoding: .utf8)!)
            } else {
                GetGalleryIDsCallBack( "You got an error")
            }
        }
        
        task.resume()
    }
    
    
    func PostNewFace(ImageString: String, NameString: String, GalleryString: String, PostNewFaceCallBack:@escaping (String) -> ()){
        
        let url = URL(string: "https://api.kairos.com/enroll")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        
        request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"subject_id\": \"" + NameString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //if let response = response, let data = data {
            if let data = data {
                //PostNewFaceCallBack(response)
                PostNewFaceCallBack(String(data: data, encoding: .utf8)!)
            } else {
                PostNewFaceCallBack("You got an error")
            }
        }
        
        task.resume()
    }
    
    func VerifyFace(ImageString: String, NameString: String, GalleryString: String, VerifyFaceCallBack:@escaping (String) -> ()){
        let url = URL(string: "https://api.kairos.com/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        
        request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"gallery_name\": \"" + GalleryString + "\",\n  \"subject_id\": \"" + NameString + "\"\n}").data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //if let response = response, let data = data {
            if let data = data {
                //VerifyFaceCallBack(response)
                VerifyFaceCallBack(String(data: data, encoding: .utf8)!)
            } else {
                VerifyFaceCallBack("Youve got an error")
            }
        }
        
        task.resume()
    }
    
    func RecogniseFace(ImageString: String, GalleryString: String, RecogniseFaceCallBack:@escaping (String) -> ()){
        let url = URL(string: "https://api.kairos.com/recognize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        
        request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //if let response = response, let data = data {
            if let data = data {
                //RecogniseFaceCallBack(response)
                RecogniseFaceCallBack(String(data: data, encoding: .utf8)!)
            } else {
                RecogniseFaceCallBack("Youve got an error")
            }
        }
        
        task.resume()
    }
    
    func RemoveID(NameString: String, GalleryString: String, RemoveIDCallBack:@escaping (String) -> ()){
        let url = URL(string: "https://api.kairos.com/gallery/remove_subject")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        
        request.httpBody = ("{\n  \"gallery_name\": \"" + GalleryString + "\",\n  \"subject_id\": \"" + NameString + "\"\n}").data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //if let response = response, let data = data {
            if let data = data {
                //RemoveIDCallBack(response)
                RemoveIDCallBack(String(data: data, encoding: .utf8)!)
            } else {
                RemoveIDCallBack("Youve got an error")
            }
        }
        
        task.resume()
    }


}


//An extension to UIImage which lets you rotate it, NB. the extension is on the file level
extension UIImage {
    func image(withRotation radians: CGFloat) -> UIImage {
        let cgImage = self.cgImage!
        let LARGEST_SIZE = CGFloat(max(self.size.width, self.size.height))
        let context = CGContext.init(data: nil, width:Int(LARGEST_SIZE), height:Int(LARGEST_SIZE), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!
        
        var drawRect = CGRect.zero
        drawRect.size = self.size
        let drawOrigin = CGPoint(x: (LARGEST_SIZE - self.size.width) * 0.5,y: (LARGEST_SIZE - self.size.height) * 0.5)
        drawRect.origin = drawOrigin
        var tf = CGAffineTransform.identity
        tf = tf.translatedBy(x: LARGEST_SIZE * 0.5, y: LARGEST_SIZE * 0.5)
        tf = tf.rotated(by: CGFloat(radians))
        tf = tf.translatedBy(x: LARGEST_SIZE * -0.5, y: LARGEST_SIZE * -0.5)
        context.concatenate(tf)
        context.draw(cgImage, in: drawRect)
        var rotatedImage = context.makeImage()!
        
        drawRect = drawRect.applying(tf)
        
        rotatedImage = rotatedImage.cropping(to: drawRect)!
        let resultImage = UIImage(cgImage: rotatedImage)
        return resultImage
        
        
    }
}
