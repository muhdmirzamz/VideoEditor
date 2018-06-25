//
//  ImageCollectionViewCell.swift
//  VideoEditor
//
//  Created by Muhd Mirza on 5/5/18.
//  Copyright © 2018 muhdmirzamz. All rights reserved.
//

import UIKit

protocol ForwardDataFromCell {
	func forwardData(progress: CGFloat, assetURL: URL)
}

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
	var assetURL: URL?
	var delegate: ForwardDataFromCell?
	
//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		let touchLocation = touches.first?.location(in: superview)
//
//		print("diff: \(touchLocation)")
//	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchLocation = touches.first?.location(in: self)
		
		if self.frame.contains(touchLocation!) {
			print("Touch location: \((touchLocation?.x)!)")
			
			let progress = (touchLocation?.x)! / self.frame.maxX
			print("progress: \(progress)")
			
			self.delegate?.forwardData(progress: progress, assetURL: assetURL!)
		}
	}
	
	//	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
	//		<#code#>
	//	}
}
