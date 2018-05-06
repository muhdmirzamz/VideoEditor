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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

	var takingVideo = false
	var loadingAsset = false
	var firstAssetLoaded = false
	
	var firstAsset: AVAsset?
	var secondAsset: AVAsset?
	
	var assetsArr = [AVAsset]()
	
	@IBOutlet var collectionView: UICollectionView!
	
	var exporter: AVAssetExportSession?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		
		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func loadVideo() {
		self.loadingAsset = true
		
		let alert = UIAlertController.init(title: "Choose media", message: "", preferredStyle: .actionSheet)
		let cameraOption = UIAlertAction.init(title: "Camera", style: .default) { (action) in
			let imagePicker = UIImagePickerController()
			imagePicker.allowsEditing = true
			imagePicker.delegate = self
			imagePicker.sourceType = .camera
			imagePicker.mediaTypes = [kUTTypeMovie as String]
			
			self.present(imagePicker, animated: true, completion: nil)
		}
		let libraryOption = UIAlertAction.init(title: "Photo Library", style: .default) { (action) in
			let imagePicker = UIImagePickerController()
			imagePicker.sourceType = .photoLibrary
			imagePicker.allowsEditing = true
			imagePicker.delegate = self
			imagePicker.mediaTypes = [kUTTypeMovie as String]
			
			self.present(imagePicker, animated: true, completion: nil)
		}
		
		alert.addAction(cameraOption)
		alert.addAction(libraryOption)
		
		self.present(alert, animated: true, completion: nil)
	}
	
	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let mediaInfo = info[UIImagePickerControllerMediaType] as! String
		
		if mediaInfo == kUTTypeMovie as String {
			let assetURL = info[UIImagePickerControllerMediaURL] as! URL
			let asset = AVAsset.init(url: assetURL)
			self.assetsArr.append(asset)
			
			self.dismiss(animated: true) {
				self.collectionView.reloadData()
			}
		}
		
//		if self.loadingAsset {
//			let mediaInfo = info[UIImagePickerControllerMediaType] as! String
//
//			if self.firstAssetLoaded {
//				if mediaInfo == kUTTypeMovie as String {
//					self.secondAsset = AVAsset.init(url: info[UIImagePickerControllerMediaURL] as! URL)
//
//					if let firstAsset = self.firstAsset, let secondAsset = self.secondAsset {
//						let alertController = UIAlertController.init(title: "Successfully loaded both assets", message: "", preferredStyle: .alert)
//						let okAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
//
//						alertController.addAction(okAction)
//
//						self.dismiss(animated: true) {
//							self.present(alertController, animated: true, completion: nil)
//						}
//					}
//				}
//			} else {
//				if mediaInfo == kUTTypeMovie as String {
//					self.firstAsset = AVAsset.init(url: info[UIImagePickerControllerMediaURL] as! URL)
//
//					self.firstAssetLoaded = true
//
//					self.dismiss(animated: true, completion: nil)
//				}
//			}
//		} else if self.takingVideo {
//			let mediaURL = info[UIImagePickerControllerMediaURL] as! URL
//
//			self.dismiss(animated: true) {
//				if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path) {
//					let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
//					let okAction = UIAlertAction.init(title: "Ok", style: .default) { (action) in
//						UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil)
//					}
//
//					alertController.addAction(okAction)
//
//					self.present(alertController, animated: true, completion: nil)
//				}
//			}
//		} else {
//			let mediaInfo = info[UIImagePickerControllerMediaType] as! String
//
//			if mediaInfo == kUTTypeMovie as String {
//				self.dismiss(animated: true) {
//					let url = info[UIImagePickerControllerMediaURL] as! URL
//					let avPlayer = AVPlayer.init(url: url)
//					let avPlayerVC = AVPlayerViewController()
//					avPlayerVC.player = avPlayer
//
//					self.present(avPlayerVC, animated: true, completion: nil)
//
//					avPlayer.play()
//				}
//			}
//		}
	}
	
	public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func merge() {
		let mixComposition = AVMutableComposition()
		
		var tracks = [AVMutableCompositionTrack]()

		var initialDuration: CMTime?
		var duration: CMTime?
		
		for i in 0 ..< self.assetsArr.count {
			if i == 0 {
				print("I is 0")
				
				let track = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
				do {
					try track?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.assetsArr[i].duration), of: self.assetsArr[i].tracks(withMediaType: .video)[0], at: kCMTimeZero)
					
					initialDuration = kCMTimeZero + self.assetsArr[i].duration
					
					tracks.append(track!)
				} catch {
					print("Failed to load first track")
				}
			} else {
				print("I is \(i)")
				
				let track = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
				do {
					try track?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.assetsArr[i].duration), of: self.assetsArr[i].tracks(withMediaType: .video)[0], at: initialDuration!)
					
					duration = initialDuration! + self.assetsArr[i].duration
					initialDuration = duration
					
					tracks.append(track!)
				} catch {
					print("Failed to load track \(i)")
				}
			}
			
			print("Composition duration: \(mixComposition.duration.seconds)")
		}
		
		let mainInstruction = AVMutableVideoCompositionInstruction()
		
		var time: CMTime?
		var initialTime: CMTime?
		for i in 0 ..< self.assetsArr.count {
			if i == 0 {
				initialTime = CMTimeAdd(kCMTimeZero, self.assetsArr[i].duration)
			} else {
				time = initialTime! + self.assetsArr[i].duration
				initialTime = time
			}
		}

		if let time = time {
			mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, time)
			print("duration: \(time.seconds)")
		}
		
		var layerInstructions = [AVVideoCompositionLayerInstruction]()
		
		var initialAssetDuration = kCMTimeZero
		var assetDuration: CMTime?
		
		for i in 0 ..< self.assetsArr.count {
			let instruction = videoCompositionInstructionForTrack(track: tracks[i], asset: self.assetsArr[i])
			
			assetDuration = initialAssetDuration + self.assetsArr[i].duration
			initialAssetDuration = assetDuration!
			
			if i < self.assetsArr.count {
				instruction.setOpacity(0.0, at: initialAssetDuration)
			}
			
			layerInstructions.append(instruction)
		}
		
		print("Assets: \(self.assetsArr.count)")
		print("layer instructions: \(layerInstructions.count)")
		
		// 2.1
//		let mainInstruction = AVMutableVideoCompositionInstruction()
//		mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd((firstAsset?.duration)!, (secondAsset?.duration)!))
		
		// 2.2
//		let firstInstruction = videoCompositionInstructionForTrack(track: firstTrack!, asset: firstAsset!)
//		firstInstruction.setOpacity(0.0, at: (firstAsset?.duration)!)
//		let secondInstruction = videoCompositionInstructionForTrack(track: secondTrack!, asset: secondAsset!)
		
		// 2.3
		mainInstruction.layerInstructions = layerInstructions
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
		mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		
		
//		let firstTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
//		do {
//			try firstTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, (self.firstAsset?.duration)!), of: (firstAsset?.tracks(withMediaType: .video)[0])!, at: kCMTimeZero)
//		} catch {
//			print("Failed to load first track")
//		}
//
//		let secondTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
//		do {
//			try secondTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, (self.secondAsset?.duration)!), of: (secondAsset?.tracks(withMediaType: .video)[0])!, at: (firstAsset?.duration)!)
//		} catch {
//			print("Failed to load first track")
//		}
		
		
		
		
		
		
		let fileManager = FileManager.default
		
		let randPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path.appending("/mergevideo.mov")
		let url = NSURL.fileURL(withPath: randPath)
		
		var fileExists = false
		
		if fileManager.fileExists(atPath: url.path) {
			
			print("File exists")
			fileExists = true
			
			do {
				print("Im here")
				
				try fileManager.removeItem(atPath: url.path)
			} catch {
				print("Yo failed to remove")
			}
			
			PHPhotoLibrary.shared().performChanges({
				let fetchOptions = PHFetchOptions()
				fetchOptions.predicate = NSPredicate(format: "title == %@", "Hello")
				
				print("Im in perform changes")
				
				if let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject {
				
					print("Im in fetch asset collections")
					
					let assets = PHAsset.fetchAssets(in: assetCollection, options: nil)
					
					if assets.count > 0 {
						// if there is nothing in the album, it won't go here
						assets.enumerateObjects({ (asset, i, stop) in
							print("Im in enumerate")
							
							let enumeration: NSArray = [asset]
							let _ = PHAssetChangeRequest.deleteAssets(enumeration)
							
							fileExists = false
							
							print("Album does exist")
						})
					} else {
						fileExists = false
					}
				} else {
					// if album itself does not exist
					fileExists = false
					print("Album does not exist")
					print("File exists bool: \(fileExists)")
				}
			}) { (success, error) in
				if success {
					if fileExists == false {
						print("Going to exporter")
						
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
				
				if (error != nil) {
					print("This is the error \(error)")
				}
			}
		} else {
			print("File does not exist on first load")
			
			if fileExists == false {
				print("Going to exporter")
				
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
	}
	
	func exportDidFinish(session: AVAssetExportSession) {
		if session.status == .completed {
			print("Completed")
			
			let outputURL = session.outputURL
			
			PHPhotoLibrary.shared().performChanges({
				let fetchOptions = PHFetchOptions()
				fetchOptions.predicate = NSPredicate(format: "title == %@", "Hello")
				
				if let assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject {
					let creationReq = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: outputURL!)
					let assetAddReq = PHAssetCollectionChangeRequest.init(for: assetCollection)
					assetAddReq?.addAssets([(creationReq?.placeholderForCreatedAsset)!] as NSArray)
				} else {
					let creationReq = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: outputURL!)
					let assetAddReq = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Hello")
					assetAddReq.addAssets([(creationReq?.placeholderForCreatedAsset)!] as NSArray)
				}
			}) { (success, error) in
				let alertController = UIAlertController.init(title: "Successfully saved", message: "", preferredStyle: .alert)
				let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
				
				alertController.addAction(okAction)
				
				self.present(alertController, animated: true, completion: nil)
			}
		}
		
		if session.status == .failed {
			print("Failed")
			
			print("Error: \(session.error)")
			
			let alertController = UIAlertController.init(title: "Failed", message: "", preferredStyle: .alert)
			let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
			
			alertController.addAction(okAction)
			
			self.present(alertController, animated: true, completion: nil)
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
	
	
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.assetsArr.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ImageCollectionViewCell
		
		let asset = self.assetsArr[indexPath.row]
		
		let imageAssetGenerator = AVAssetImageGenerator.init(asset: asset)
		imageAssetGenerator.appliesPreferredTrackTransform = true
		
		do {
			let imageRef = try imageAssetGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)
			
			let image = UIImage.init(cgImage: imageRef)
			cell?.imageView.image = image

			if let cell = cell {
				print("Cell is goof to go")
				
				if let image = cell.imageView.image {
					print("image is goof to go")
				}
			}
			
		} catch {
			print("Error image generation")
		}
		
		return cell!
	}
	
	
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
}

