//
//  SettingsViewController.swift
//  faceDetectionDemo2
//
//  Created by Luke Markham on 02/09/2017.
//  Copyright © 2017 XueYu. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var userText: UITextField!
    @IBOutlet weak var userSelfie: UIImageView!
    
    @IBAction func newSelfie(_ sender: Any) {
    }
    @IBAction func deleteSelfie(_ sender: Any) {
    }
    @IBAction func updateProfile(_ sender: Any) {
        print("You pressed updateProfile")
    }
    
    @IBAction func deleteProfile(_ sender: Any) {
    print("You pressed deleteProfile")
    }
}
