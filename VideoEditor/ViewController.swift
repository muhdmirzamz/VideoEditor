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
	var assetsArr = [AVAsset]()
	var assetsURLArr = [URL]()
	
	@IBOutlet var collectionView: UICollectionView!
	@IBOutlet var mainImageView: UIImageView!
	
	var scrubber: UIView?
	
	var exporter: AVAssetExportSession?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.collectionView.backgroundColor = .blue
		
		self.scrubber = UIView.init(frame: CGRect.init(x: self.collectionView.frame.origin.x, y: self.collectionView.frame.origin.y - 10, width: 5, height: self.collectionView.frame.size.height + 20))
		self.scrubber?.backgroundColor = .red
		self.view.addSubview(self.scrubber!)
		
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		
		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	
	
	
	@IBAction func loadVideo() {
		let imagePicker = UIImagePickerController()
		imagePicker.delegate = self
		imagePicker.allowsEditing = true
		imagePicker.mediaTypes = [kUTTypeMovie as String]
		
		let alert = UIAlertController.init(title: "Choose media", message: "", preferredStyle: .actionSheet)
		let cameraOption = UIAlertAction.init(title: "Camera", style: .default) { (action) in
			imagePicker.sourceType = .camera
			
			self.present(imagePicker, animated: true, completion: nil)
		}
		let libraryOption = UIAlertAction.init(title: "Photo Library", style: .default) { (action) in
			imagePicker.sourceType = .photoLibrary
			
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
			self.assetsURLArr.append(assetURL)
			
			self.dismiss(animated: true) {
				self.collectionView.reloadData()
			}
		}
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
			let track = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
			
			if i == 0 {
				initialDuration = kCMTimeZero
			}
			
			do {
				try track?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.assetsArr[i].duration), of: self.assetsArr[i].tracks(withMediaType: .video)[0], at: initialDuration!)
			} catch {
				print("Failed to load track")
			}
			
			duration = initialDuration! + self.assetsArr[i].duration
			initialDuration = duration
			
			tracks.append(track!)

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
		

		mainInstruction.layerInstructions = layerInstructions
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
		mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		

		
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
			cell?.assetURL = self.assetsURLArr[indexPath.row]
			
			
			
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
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		var touchLocation = touches.first?.location(in: self.view)
		
		if (self.scrubber?.frame.contains(touchLocation!))! {
			self.scrubber?.frame.origin.x = (touchLocation?.x)!
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		var touchLocation = touches.first?.location(in: self.view)
		
		self.scrubber?.frame.origin.x = (touchLocation?.x)!
		
		var videoTimeScrubLocation = self.view.convert(touchLocation!, to: self.collectionView)
		
		if let indexPath = self.collectionView.indexPathForItem(at: videoTimeScrubLocation) {
			let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell
			
			let progress = videoTimeScrubLocation.x / (cell?.frame.maxX)!
			
			let asset = AVAsset.init(url: (cell?.assetURL)!)
			
			let imageAssetGenerator = AVAssetImageGenerator.init(asset: asset)
			imageAssetGenerator.appliesPreferredTrackTransform = true
			
			// example: 0.45 is 45%
			// there is not a need to divide by 100 again
			let time = Double(progress) * asset.duration.seconds
			let convertedTime = CMTimeMake(Int64(time), 1)
			do {
				let imageRef = try imageAssetGenerator.copyCGImage(at: convertedTime, actualTime: nil)
				
				let image = UIImage.init(cgImage: imageRef)
				self.mainImageView.image = image
			} catch {
				print("Error image generation")
			}
		}
	}
}

