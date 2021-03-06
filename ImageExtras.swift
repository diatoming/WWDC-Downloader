//
//  ImageExtras.swift
//  WWDC
//
//  Created by David Roberts on 21/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
	
	func tintImageToBrightBlurColor() -> NSImage {
		return self.tintImageToColor(NSColor(deviceRed: 23.0/255.0, green: 123.0/255.0, blue: 250.0/255.0, alpha: 1))
	}
	
	func tintImageToWhiteColor() -> NSImage {
		return self.tintImageToColor(NSColor.whiteColor())
	}

	
	func tintImageToColor(color:NSColor) -> NSImage {
		
		let size = self.size
		
		let rect : NSRect = NSMakeRect(0, 0, size.width, size.height)
		
		let copiedImage = self.copy() as! NSImage
		
		copiedImage.lockFocus()
		
		color.set()
		
		NSRectFillUsingOperation(rect, NSCompositingOperation.CompositeSourceAtop)
		
		copiedImage.unlockFocus()
		
		return copiedImage
	}

}