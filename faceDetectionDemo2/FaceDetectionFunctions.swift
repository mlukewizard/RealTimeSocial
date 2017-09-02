//
//  FaceDetectionFunctions.swift
//  faceDetectionDemo2
//
//  Created by Luke Markham on 02/09/2017.
//  Copyright © 2017 XueYu. All rights reserved.
//

import Foundation
import UIKit

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
            var retDict = [String: Any]()
            retDict["gotData"] = "yes"
            let jsonAsString = String(data: data, encoding: String.Encoding.utf8) as String!
            //let json = try? JSONSerialization.jsonObject(with: data) as! [String: Any]
            //let unwrappedJson = json!
            if let subjectIndex = jsonAsString?.localizedStandardRange(of: "subject_id"){
                let personString = jsonAsString?.substring(from: subjectIndex.lowerBound)
                retDict["msg"] = "Got some!"
            }
            else{
                retDict["msg"] = "Didnt get a face"
            }
            RecogniseFaceCallBack(retDict)
        } else {
            //Create a dictionary which is returned to throw an error
            var retDict = [String: Any]()
            retDict["gotData"] = "no"
            retDict["msg"] = "Sorry there was an error retrieving data"
            RecogniseFaceCallBack(retDict)
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
