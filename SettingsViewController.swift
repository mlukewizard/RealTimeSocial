//
//  SettingsViewController.swift
//  faceDetectionDemo2
//
//  Created by Luke Markham on 02/09/2017.
//  Copyright © 2017 XueYu. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var userText: UITextField!
    @IBOutlet weak var userSelfie: UIImageView!
    var userImage: UIImage?
    
    @IBAction func newSelfie(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        
        //Place image picker on the screen
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]){
        //Get picked image from info dictionary
        userImage = info[UIImagePickerControllerOriginalImage] as! UIImage

        //Put that image on the screen in the image view
        userSelfie.image = userImage
        
        //Take image picker off the screen - you must call this dismiss method
        dismiss(animated: true, completion:nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func deleteSelfie(_ sender: Any) {
        userSelfie.image = nil
    }
    
    @IBAction func updateProfile(_ sender: Any) {
        PostNewFace(userImage: userImage!, NameString: userText.text!, GalleryString: "MyGallery"){success in
            if success["uploaded_image_url"] != nil{
            let alert = UIAlertController(title: "Success", message: "Your profile has been successfully uploaded", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            }else{
                let alert = UIAlertController(title: "Oops", message: "Sorry there's been an error uploading your profile", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        }

    }
    
    @IBAction func deleteProfile(_ sender: Any) {
        
    }
}
