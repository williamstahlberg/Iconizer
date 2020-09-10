//
//  IconSet.swift
//  Iconizer
//
//  Created by subli on 9/3/20.
//  Copyright © 2020 subli. All rights reserved.
//

import Cocoa

class IconSet {
	private let availableSizeNames = [
		16: "icon_16x16",
		32: "icon_32x32",
		128: "icon_128x128",
		256: "icon_256x256",
		512: "icon_512x512",
	]
	
	var name: String? = nil
	var images: [Int: NSImage] = [:]
	
	init() {
	}
	
//	init(withName name: String) {
//		self.name = name
//	}
//
//	init?(withName name: String, imageUrl url: URL) {
//		self.name = name
//		guard self.addImage(contentsOf: url) else {
//			return nil
//		}
//	}
	
	func addImage(contentsOf url: URL) -> Bool {
		guard var image = NSImage(contentsOf: url) else {
			return false
		}
		
		/* We need to also work with cgImage to get the correct width/height. */
		guard var cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
			return false
		}
		
		/* We need to make the image square if it's not already. */
		if cgImage.width != cgImage.height {
			guard let squareImage = square(image: image) else {
				return false
			}
			if let squareCgImage = squareImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
				cgImage = squareCgImage
			}
		}

		let debug0Url = URL(fileURLWithPath: "/Users/subli/Desktop/debug0_image.png")
		image.debugWriteToFile(to: debug0Url)
		
		print("image.size: \(image.size)")
		print("cgImage.width,height: (\(cgImage.width), \(cgImage.height))")

		let curSize = cgImage.width
		var newSize: Int?
		
		for availSize in availableSizeNames.keys.reversed() {
			if curSize >= availSize {
				newSize = availSize
				break
			}
		}
		
		guard newSize != nil else {
			return false
		}
		
		if newSize != curSize {
			let newCgSize = CGSize(width: newSize!, height: newSize!)
			guard let resizedImage = image.resized(to: newCgSize) else {
				return false
			}
			image = resizedImage
		}
		
		let key = Int(newSize!)
		guard !images.keys.contains(key) else {
			return false
		}
		
		images[key] = image
		
		let debug1Url = URL(fileURLWithPath: "/Users/subli/Desktop/debug1_image.png")
		images[key]?.debugWriteToFile(to: debug1Url)
		
		return true
	}
	
	private func square(image: NSImage) -> NSImage? {
		let width = image.size.width
		let height = image.size.height
		let squareDim = max(width, height)
		let squareSize = CGSize(width: squareDim, height: squareDim)
		
		let newImage = NSImage.init(size: squareSize)
		let rep = NSBitmapImageRep.init(
			bitmapDataPlanes: nil,
			pixelsWide: Int(width),
			pixelsHigh: Int(height),
			bitsPerSample: 8,
			samplesPerPixel: 4,
			hasAlpha: true,
			isPlanar: false,
			colorSpaceName: NSColorSpaceName.calibratedRGB,
			bytesPerRow: 0,
			bitsPerPixel: 0)

		newImage.addRepresentation(rep!)
		newImage.lockFocus()

		let rect = NSMakeRect(0, 0, squareDim, squareDim)
		guard let ctx = NSGraphicsContext.current?.cgContext else {
			return nil
		}
		let transparent = NSColor(calibratedWhite: 0, alpha: 0)
		
		ctx.clear(rect)
		ctx.setFillColor(transparent.cgColor)
		ctx.fill(rect)

		image.draw(in: CGRect(x: (squareDim-width) / 2, y: (squareDim - height) / 2, width: width, height: height))
		newImage.unlockFocus()
		
		return newImage
	}
}

extension NSImage {
	@discardableResult func debugWriteToFile(to dest: URL) -> Bool {
		guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
			return false
		}
		guard let cgImageDest = CGImageDestinationCreateWithURL(dest as CFURL, kUTTypePNG, 1, nil) else {
			return false
		}
		CGImageDestinationAddImage(cgImageDest, cgImage, nil)

		return CGImageDestinationFinalize(cgImageDest)
	}

	func resized(to newSize: NSSize) -> NSImage? {
		if let bitmapRep = NSBitmapImageRep(
			bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
			bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
			colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
		) {
			bitmapRep.size = newSize
			NSGraphicsContext.saveGraphicsState()
			NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
			draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
			NSGraphicsContext.restoreGraphicsState()

			let resizedImage = NSImage(size: newSize)
			resizedImage.addRepresentation(bitmapRep)
			return resizedImage
		}

		return nil
	}
}
