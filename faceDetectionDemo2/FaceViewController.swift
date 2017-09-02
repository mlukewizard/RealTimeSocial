import UIKit
import AVFoundation

class FaceViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //variables for storing face information
    var faces = [CGRect]()
    var touchedFace: Int?
    
    //variables for displaying the rectangles on the faces
    var previewLayer: AVCaptureVideoPreviewLayer!
    var faceRectCALayer: CALayer!
    
    //Variables for rendering video
    fileprivate var currentCameraFace: AVCaptureDevice?
    fileprivate var sessionQueue: DispatchQueue = DispatchQueue(label: "videoQueue", attributes: [])
    
    fileprivate var session: AVCaptureSession!
    fileprivate var backCameraDevice: AVCaptureDevice?
    fileprivate var frontCameraDevice: AVCaptureDevice?
    fileprivate var metadataOutput: AVCaptureMetadataOutput!
    
    //variables for capturing pictures
    let photoOutput = AVCapturePhotoOutput()
    var videoDeviceInput: AVCaptureDeviceInput!
    
    //Reactive function to the video screen being touched
    @IBAction func TouchHappens(_ sender: UITapGestureRecognizer) {
        //gets the location where the user touched the screen
        let point = sender.location(in: self.view)
        let x = point.x
        let y = point.y
        
        //runs through the faces to see if you touched inside any of them
        touchedFace = nil
        for index in 0...faces.count-1{
            let face = faces[index]
            if x>face.minX && x<face.minX+face.width && y>face.minY && y<face.minY+face.height{
                touchedFace = index
            }
        }
        
        //if you touched inside a face, then take a photo
        if touchedFace != nil {
            let photoSettings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
            //from here "func capture(_ captureOutput: AVCapturePhotoOutput, didFinishPro..." is called
        }
        
    }
    
    //this is automatically executed if a photo is taken and is a direct follow on from the above
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        //YOU SHOULD TRY AND CHANGE THIS BIT TO PNG!!!!!
        if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) {
            
            //Converts data to UIImage
            if let image = UIImage(data: dataImage) {
                
                //Converts the coordinates of the touch to CGImage coordinates
                //Currently only working in portrait
                let face = faces[touchedFace!]
                let exactWidthHeight = ((face.height)/380)*1080
                let newMinX = (face.minY/670)*1920
                let newMinY = (((380-face.minX)/380)*1080)-exactWidthHeight
                
                //Constructs a rectangle from the new coordinates which is used to crop the image
                var rect = CGRect(x: newMinX, y: newMinY, width: exactWidthHeight, height: exactWidthHeight)
                
                //Increase the rectangle size to make sure all of the face is included
                rect = increaseRect(rect: rect, byPercentage: 50)
                
                
                //Convert to cgImage and crop. N.B. origin of cgImage is in the top right!
                var newimage = image.cgImage
                newimage = newimage?.cropping(to: rect)
                
                //Reconstruct a UIImage and make it vertical in case you want to save it
                let croppedImage = UIImage(cgImage: newimage!, scale: image.scale, orientation: .right)
                
                UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
                
                /*
                 PostNewFace(userImage: croppedImage, NameString: "Simon Cowell 2", GalleryString: "MyGallery"){response in
                 print(response)
                 }
                 */
                
                
                /*
                GetGalleryIDs() { response in
                    print(response)
                }
                */
                
                
                 RecogniseFace(userImage: croppedImage, GalleryString: "MyGallery"){response in
                 print(response)
                 }
                 
                
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
        
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],mediaType: AVMediaTypeVideo,position: AVCaptureDevicePosition.unspecified) {
            
            for device in deviceDescoverySession.devices{
                if device.position == .back {
                    backCameraDevice = device
                } else if device.position == .front{
                    frontCameraDevice = device
                }
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
        
        self.faces = [CGRect]() //I think you can delete this
        
        //Detects faces and then adds them to the end of the faces variable
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
    //----GetGalleryIDs----
    func GetGalleryIDs(GetGalleryIDsCallBack:@escaping ([String: Any]) -> ()) {
        //Defining a new request and setting the necessary fields for GetGalleryIDs
        let url = URL(string: "https://api.kairos.com/gallery/view")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        request.httpBody = "{\n  \"gallery_name\": \"MyGallery\"\n}".data(using: .utf8)
        
        //Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                //Format the response as a dictionary for easy access
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let unwrappedJson = json!!
                
                GetGalleryIDsCallBack(unwrappedJson)
            } else {
                //Create a dictionary which is returned to throw an error
                var errorDictionary = [String: Any]()
                errorDictionary["status"] = "fail"
                GetGalleryIDsCallBack(errorDictionary)
            }
        }
        task.resume()
    }
    
    //----PostNewFace----
    func PostNewFace(userImage: UIImage, NameString: String, GalleryString: String, PostNewFaceCallBack:@escaping ([String: Any]) -> ()){
        
        //Rotate, send to PNG and then convert to base64
        let croppedImage = userImage.image(withRotation: 3*3.14159/2)
        let ImagePNG = UIImagePNGRepresentation(croppedImage)
        let imageData:NSData = ImagePNG! as NSData
        let ImageString = imageData.base64EncodedString(options: .lineLength64Characters)
        
        //Defining a new request and setting the necessary fields for PostNewFace
        let url = URL(string: "https://api.kairos.com/enroll")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"subject_id\": \"" + NameString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
        
        //Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let unwrappedJson = json!!
                
                PostNewFaceCallBack(unwrappedJson)
            } else {
                //Create a dictionary which is returned to throw an error
                var errorDictionary = [String: Any]()
                errorDictionary["status"] = "fail"
                PostNewFaceCallBack(errorDictionary)
            }
        }
        
        task.resume()
    }
    
    //----RecogniseFace----
    func RecogniseFace(userImage: UIImage, GalleryString: String, RecogniseFaceCallBack:@escaping ([String: Any]) -> ()){
        //Rotate, send to PNG and then convert to base64
        let croppedImage = userImage.image(withRotation: 3*3.14159/2)
        let ImagePNG = UIImagePNGRepresentation(croppedImage)
        let imageData:NSData = ImagePNG! as NSData
        let ImageString = imageData.base64EncodedString(options: .lineLength64Characters)
        
        //Defining a new request and setting the necessary fields for RecogniseFace
        let url = URL(string: "https://api.kairos.com/recognize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        request.httpBody = ("{\n  \"image\": \"" + ImageString + "\",\n  \"gallery_name\": \"" + GalleryString + "\"\n}").data(using: .utf8)
        
        //Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let unwrappedJson = json!!
                
                RecogniseFaceCallBack(unwrappedJson)
            } else {
                //Create a dictionary which is returned to throw an error
                var errorDictionary = [String: Any]()
                errorDictionary["status"] = "fail"
                RecogniseFaceCallBack(errorDictionary)
            }
        }
        
        task.resume()
    }
    
    //----RemoveIdWithName----
    func RemoveIdWithName(NameString: String, GalleryString: String, RemoveIDCallBack:@escaping ([String: Any]) -> ()){
        //Defining a new request and setting the necessary fields for RemoveID
        let url = URL(string: "https://api.kairos.com/gallery/remove_subject")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("66261a1d", forHTTPHeaderField: "app_id")
        request.addValue("11da5256b834011f91378a81202a1393", forHTTPHeaderField: "app_key")
        request.httpBody = ("{\n  \"gallery_name\": \"" + GalleryString + "\",\n  \"subject_id\": \"" + NameString + "\"\n}").data(using: .utf8)
        
        //Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let unwrappedJson = json!!
                
                RemoveIDCallBack(unwrappedJson)
            } else {
                //Create a dictionary which is returned to throw an error
                var errorDictionary = [String: Any]()
                errorDictionary["status"] = "fail"
                RemoveIDCallBack(errorDictionary)
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
