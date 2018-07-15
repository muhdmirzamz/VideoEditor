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
	
	var scrubbedCell: ImageCollectionViewCell?
	var scrubbedTimeLocation: CGPoint?
	
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
		
		// adding track
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
		
		
		// adding time
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
		
		// set video composition
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
	
	@IBAction func cut() {
		// make sure there is a cell to cut
		if let cell = self.scrubbedCell {
			let fileManager = FileManager.default

			// create a new directory
			guard let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
				return
			}

			let mediaType = "mp4"

			if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String {
				// create a new directory called "output"
				// so now you have "originalDir/output"
				var outputURL = documentDirectory.appendingPathComponent("output")
				var name = outputURL
				do {
					try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
					
					// so now you have "originalDir/output/name.mp4"
					name = outputURL.appendingPathComponent("cutVideo.mp4")
				}catch let error {
					print(error)
				}
				
				
				

				let asset = AVAsset.init(url: cell.assetURL!)
				var asset2 = AVAsset.init(url: cell.assetURL!)
				let progress = (self.scrubbedTimeLocation?.x)! / cell.frame.maxX
				
				let time = Double(progress) * asset2.duration.seconds
				let convertedTime = CMTimeMake(Int64(time), 1)
				
				let timeRange = CMTimeRange(start: CMTimeMake(Int64(0), 1), end: convertedTime)
				
				print("asset duration:\(asset.duration.seconds)")
				print("asset2 duration:\(asset2.duration.seconds)")
				print("Time range: \(timeRange.start.seconds) and \(timeRange.end.seconds)")
				
				guard let exportSession = AVAssetExportSession(asset: asset2, presetName: AVAssetExportPresetHighestQuality) else {return}
				exportSession.outputURL = name
				exportSession.outputFileType = AVFileType.mov
				exportSession.timeRange = timeRange
				
				exportSession.exportAsynchronously {
					switch exportSession.status {
					case .completed:
						let assetURL = name
						asset2 = AVAsset.init(url: assetURL)
						
						print("asset duration after export:\(asset.duration.seconds)")
						print("asset2 duration after export:\(asset2.duration.seconds)")
						
						
						print("First")
						print("Assets count: \(self.assetsArr.count)")
						print("Assets URL count: \(self.assetsURLArr.count)")
						print("Assets: \(self.assetsArr.description)")
						
						self.assetsArr.append(asset2)
						self.assetsURLArr.append(assetURL)
						
						print("Assets count: \(self.assetsArr.count)")
						print("Assets URL count: \(self.assetsURLArr.count)")
						print("Assets: \(self.assetsArr.description)")
						
						print("exported at \(name)")
						
						

						
					
						// so now you have "originalDir/output/name.mp4"
						print("Output url \(outputURL)")
						name = outputURL.appendingPathComponent("cutVideo0.mp4")
						print("name \(name)")
						
						var progress: CGFloat = 0
						DispatchQueue.main.async {
							progress = (self.scrubbedTimeLocation?.x)! / cell.frame.maxX
						}
						let time = Double(progress) * asset.duration.seconds
						let convertedTime = CMTimeMake(Int64(time), 1)
						
						let timeRange = CMTimeRange(start: convertedTime, end: asset.duration)
						print("Second Time range: \(timeRange.start.seconds) and \(timeRange.end.seconds)")

						guard let exportSession2 = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
						exportSession2.outputURL = name
						exportSession2.outputFileType = AVFileType.mov
						exportSession2.timeRange = timeRange

						exportSession2.exportAsynchronously {
							switch exportSession2.status {
							case .completed:
								let assetURL = name
								let asset = AVAsset.init(url: assetURL)

								print("Second")
								print("Assets count: \(self.assetsArr.count)")
								print("Assets URL count: \(self.assetsURLArr.count)")
								print("Assets: \(self.assetsArr.description)")
								
								self.assetsArr.append(asset)
								self.assetsURLArr.append(assetURL)

								print("Assets count: \(self.assetsArr.count)")
								print("Assets URL count: \(self.assetsURLArr.count)")
								print("Assets: \(self.assetsArr.description)")
								
								print("exported at \(name)")
								
								
								if let index = self.assetsURLArr.index(of: cell.assetURL!) {
									print("Assets count: \(self.assetsArr.count)")
									print("Assets URL count: \(self.assetsURLArr.count)")
									print("Assets: \(self.assetsArr.description)")
									
									self.assetsArr.remove(at: index)
									self.assetsURLArr.remove(at: index)
									
									print("Removed at")
									
									print("Assets count: \(self.assetsArr.count)")
									print("Assets URL count: \(self.assetsURLArr.count)")
									print("Assets: \(self.assetsArr.description)")
									
									_ = try? fileManager.removeItem(at: cell.assetURL!)
									
								}
								
								DispatchQueue.main.async {
									self.collectionView.reloadData()
								}



							case .failed:
								print("failed \(exportSession.error)")
							case .cancelled:
								print("failed \(exportSession.error)")
							default:
								break
							}
						}
						
						
						
						
						
						
						
						
						
						
						
						
						

						case .failed:
							print("failed \(exportSession.error)")

						case .cancelled:
							print("cancelled \(exportSession.error)")

						default: break
					}
				}
				

				
				
				
				
				
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
		let touchLocation = touches.first?.location(in: self.view)
		
		self.scrubber?.frame.origin.x = (touchLocation?.x)!
		
		let videoTimeScrubLocation = self.view.convert(touchLocation!, to: self.collectionView)
		self.scrubbedTimeLocation = videoTimeScrubLocation
		
		if let indexPath = self.collectionView.indexPathForItem(at: videoTimeScrubLocation) {
			self.scrubbedCell = self.collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell

			let progress = videoTimeScrubLocation.x / (self.scrubbedCell?.frame.maxX)!
			
			let asset = AVAsset.init(url: (self.scrubbedCell?.assetURL)!)
			
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

