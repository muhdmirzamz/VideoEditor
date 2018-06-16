//
//  ImageCollectionViewCell.swift
//  VideoEditor
//
//  Created by Muhd Mirza on 5/5/18.
//  Copyright © 2018 muhdmirzamz. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
	var assetURL: URL?
	
//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		let touchLocation = touches.first?.location(in: superview)
//
//		print("diff: \(touchLocation)")
//	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchLocation = touches.first?.location(in: self)
		
		if self.frame.contains(touchLocation!) {
			print("Touch location: \((touchLocation?.x)!)")
		}
	}
	
	//	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
	//		<#code#>
	//	}
}
