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
	
	var exporter: AVAssetExportSession?
	
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
		
		
		// 2.1
		let mainInstruction = AVMutableVideoCompositionInstruction()
		mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd((firstAsset?.duration)!, (secondAsset?.duration)!))
		
		// 2.2
		let firstInstruction = videoCompositionInstructionForTrack(track: firstTrack!, asset: firstAsset!)
		firstInstruction.setOpacity(0.0, at: (firstAsset?.duration)!)
		let secondInstruction = videoCompositionInstructionForTrack(track: secondTrack!, asset: secondAsset!)
		
		// 2.3
		mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTimeMake(1, 30)
		mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		
		
		
		let fileManager = FileManager.default
		
		
		
//		let docDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//		let savePath = docDirectory.path.appending("/mergevideo.mov")
		
		
		let randPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path.appending("/mergevideo.mov")
		let url = NSURL.fileURL(withPath: randPath)
		
		print("\n\n")
		print("URL: \(url)")
		print("absoluteString: \(url.absoluteString)")
		print("randPath: \(randPath)")
		
		var fileExists = false
		
		if fileManager.fileExists(atPath: randPath) {
			
			print("File exists!")
			
			fileExists = true

			PHPhotoLibrary.shared().performChanges({
				if let asset = PHAsset.fetchAssets(with: .video, options: nil).lastObject {
					print("Asset is valid")
					
					let enumeration: NSArray = [asset]
					let _ = PHAssetChangeRequest.deleteAssets(enumeration)
				}
			}) { (success, error) in
				if success {
					print("WOOO")
				}
				
				if (error != nil) {
					print("NOOOOOOO")
				}
			}
		} else {
			print("File does not exist on first load")
		}
		
		if fileExists == false {
			self.exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
			self.exporter?.outputURL = url
			self.exporter?.outputFileType = AVFileType.mov
			self.exporter?.videoComposition = mainComposition
			self.exporter?.exportAsynchronously(completionHandler: {
				DispatchQueue.main.async {
					self.exportDidFinish(session: self.exporter!)
				}
			})
		}
	}
	
	func exportDidFinish(session: AVAssetExportSession) {
		print("Session status: \(session.status.rawValue)")
		
		if session.status == .completed {
			print("Completed")
			
			let outputURL = session.outputURL
			
			if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((outputURL?.path)!) {
				let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
				let okAction = UIAlertAction.init(title: "Ok", style: .default) { (action) in
					UISaveVideoAtPathToSavedPhotosAlbum((outputURL?.path)!, nil, nil, nil)
				}
				
				alertController.addAction(okAction)
				
				self.present(alertController, animated: true, completion: nil)
			}
		}
		
		if session.status == .failed {
			print("Failed")
			
			let alertController = UIAlertController.init(title: "Failed", message: "", preferredStyle: .alert)
			let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
			
			alertController.addAction(okAction)
			
			self.present(alertController, animated: true, completion: nil)
			// might want to prompt user to retry saving since there is sort of like a null pointer bug case scenario we are dealing with here
		}
	}
	
	
	
	
	
	
	func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
		let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
		let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
		
		let transform = assetTrack.preferredTransform
		let assetInfo = self.orientationFromTransform(transform: transform)
		
		var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
		if assetInfo.isPortrait {
			scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
			let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
			instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor), at: kCMTimeZero)
		} else {
			let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
			var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
			if assetInfo.orientation == .down {
				let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(M_PI))
				let windowBounds = UIScreen.main.bounds
				let yFix = assetTrack.naturalSize.height + windowBounds.height
				let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
				concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
			}
			instruction.setTransform(concat, at: kCMTimeZero)
		}
		
		return instruction
	}
	
	func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
		var assetOrientation = UIImageOrientation.up
		var isPortrait = false
		if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
			assetOrientation = .right
			isPortrait = true
		} else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
			assetOrientation = .left
			isPortrait = true
		} else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
			assetOrientation = .up
		} else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
			assetOrientation = .down
		}
		return (assetOrientation, isPortrait)
	}
}

