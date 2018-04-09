//
//  ViewController.swift
//  VideoEditor
//
//  Created by Muhd Mirza on 31/1/18.
//  Copyright © 2018 muhdmirzamz. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import AVKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var takingVideo = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func selectAndPlayVideo() {
		self.takingVideo = false
		
		let imagePicker = UIImagePickerController()
		imagePicker.allowsEditing = true
		imagePicker.delegate = self
		imagePicker.sourceType = .photoLibrary
		imagePicker.mediaTypes = [kUTTypeMovie as String]
		
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func takeAndSaveVideo() {
		self.takingVideo = true
		
		let imagePicker = UIImagePickerController()
		imagePicker.allowsEditing = true
		imagePicker.delegate = self
		imagePicker.sourceType = .camera
		imagePicker.mediaTypes = [kUTTypeMovie as String]
		
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if self.takingVideo {
			let mediaURL = info[UIImagePickerControllerMediaURL] as! URL
			
			self.dismiss(animated: true) {
				if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path) {
					let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
					let okAction = UIAlertAction.init(title: "Ok", style: .default) { (action) in
						UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil)
					}
					
					alertController.addAction(okAction)
					
					self.present(alertController, animated: true, completion: nil)
					
				}
			}
		} else {
			let mediaInfo = info[UIImagePickerControllerMediaType] as! String
			
			if mediaInfo == kUTTypeMovie as String {
				self.dismiss(animated: true) {
					let url = info[UIImagePickerControllerMediaURL] as! URL
					let avPlayer = AVPlayer.init(url: url)
					let avPlayerVC = AVPlayerViewController()
					avPlayerVC.player = avPlayer
					
					self.present(avPlayerVC, animated: true, completion: nil)
					
					avPlayer.play()
				}
			}
		}
	}
	
	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: true, completion: nil)
	}
}

