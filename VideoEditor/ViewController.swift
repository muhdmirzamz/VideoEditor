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
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var takingVideo = false
	var loadingAsset = false
	var firstAssetLoaded = false
	
	var firstAsset: AVAsset?
	var secondAsset: AVAsset?
	
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
	
	@IBAction func loadFirstAsset() {
		self.loadingAsset = true
		
		let imagePicker = UIImagePickerController()
		imagePicker.allowsEditing = true
		imagePicker.delegate = self
		imagePicker.sourceType = .photoLibrary
		imagePicker.mediaTypes = [kUTTypeMovie as String]
		
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func loadSecondAsset() {
		let imagePicker = UIImagePickerController()
		imagePicker.allowsEditing = true
		imagePicker.delegate = self
		imagePicker.sourceType = .photoLibrary
		imagePicker.mediaTypes = [kUTTypeMovie as String]
		
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if self.loadingAsset {
			let mediaInfo = info[UIImagePickerControllerMediaType] as! String
			
			if self.firstAssetLoaded {
				if mediaInfo == kUTTypeMovie as String {
					self.secondAsset = AVAsset.init(url: info[UIImagePickerControllerMediaURL] as! URL)
					
					if let firstAsset = self.firstAsset, let secondAsset = self.secondAsset {
						let alertController = UIAlertController.init(title: "Successfully loaded both assets", message: "", preferredStyle: .alert)
						let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
						
						alertController.addAction(okAction)
						
						self.dismiss(animated: true) {
							self.present(alertController, animated: true, completion: nil)
						}
					}
				}
			} else {
				if mediaInfo == kUTTypeMovie as String {
					self.firstAsset = AVAsset.init(url: info[UIImagePickerControllerMediaURL] as! URL)
					
					self.firstAssetLoaded = true
					
					self.dismiss(animated: true, completion: nil)
				}
			}
		} else if self.takingVideo {
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
	
	@IBAction func merge() {
		let mixComposition = AVMutableComposition()
		
		let firstTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
		do {
			try firstTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, (self.firstAsset?.duration)!), of: (firstAsset?.tracks(withMediaType: .video)[0])!, at: kCMTimeZero)
		} catch {
			print("Failed to load first track")
		}
		
		let secondTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
		do {
			try secondTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, (self.secondAsset?.duration)!), of: (secondAsset?.tracks(withMediaType: .video)[0])!, at: (firstAsset?.duration)!)
		} catch {
			print("Failed to load first track")
		}
		
		let docDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
		let savePath = (docDirectory as NSString).appending("/mergevideo.mov")
		let url = NSURL.fileURL(withPath: savePath)
		
		print("URL: \(url)")
		
		let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
		exporter?.outputURL = url
		exporter?.outputFileType = AVFileType.mov
		exporter?.exportAsynchronously(completionHandler: {
			DispatchQueue.main.async {
				self.exportDidFinish(session: exporter!)
			}
		})
	}
	
	func exportDidFinish(session: AVAssetExportSession) {
		if session.status == .completed {
			let outputURL = session.outputURL
			
			if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((outputURL?.path)!) {
				let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
				let okAction = UIAlertAction.init(title: "Ok", style: .default) { (action) in
					UISaveVideoAtPathToSavedPhotosAlbum((outputURL?.path)!, nil, nil, nil)
				}
				
				alertController.addAction(okAction)
				
				self.present(alertController, animated: true) {
					UISaveVideoAtPathToSavedPhotosAlbum((outputURL?.path)!, nil, nil, nil)
				}
			}
		}
		
		if session.status == .failed {
			let outputURL = session.outputURL
			
			let fileManager = FileManager.default
			
			if fileManager.fileExists(atPath: (outputURL?.path)!) {
				do {
					print("Here")
					try fileManager.removeItem(atPath: (outputURL?.path)!)
					
					let outputURL = session.outputURL
					
					if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((outputURL?.path)!) {
						let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
						let okAction = UIAlertAction.init(title: "Ok", style: .default) { (action) in
							UISaveVideoAtPathToSavedPhotosAlbum((outputURL?.path)!, nil, nil, nil)
						}
						
						alertController.addAction(okAction)
						
						self.present(alertController, animated: true) {
							UISaveVideoAtPathToSavedPhotosAlbum((outputURL?.path)!, nil, nil, nil)
						}
					}
				} catch {
					print("Failed to remove file")
				}
			}
			
			print("Export error: \(session.error)")
		}
	}
}

