//
//  DropView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 14/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class DropView: NSView {
	@IBOutlet weak var backgroundImage: NSImageView!
	
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(named: "DropAreaShadeColor")?.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }

	func highlight() {
		self.animator().alphaValue = 1.0
	}
	
	func unhighlight() {
		self.animator().alphaValue = 0.6
	}

    private func initialize() {
        // Unregister from dragging all components
        for view in subviews {
            view.unregisterDraggedTypes()
        }
        // Register this view for handling fileURLs
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.init(rawValue: kUTTypeFileURL as String)])
		self.alphaValue = 0.6
    }

    private func getAcceptedUrls(fromPasteboard pasteboard: NSPasteboard) -> [URL] {
        var acceptedUrls = [URL]()
        if let pboardUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in pboardUrls {
                if FileManager.default.fileExists(atPath: url.path) {
					acceptedUrls.append(url)
                }
            }
        }
        return acceptedUrls
    }

	@discardableResult
	func openProcess(path: String, args: String...) -> (String, String) {
		let task = Process()
		task.executableURL = URL(fileURLWithPath: path)
		task.arguments = args
		
		do {
//			print("7")
			try task.run()
//			print("8")

//			let outputPipe = Pipe()
//			let errorPipe = Pipe()
//			print("9")

//			let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//			let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//			print("A")
//			let output = String(decoding: outputData, as: UTF8.self)
//			let error = String(decoding: errorData, as: UTF8.self)
//			print("B")
//
//			return (output, error)
			return ("", "")
		} catch {
			return ("", "Failed to open process '\(path)'.")
		}
	}
	
	func writeIconFile(with source: URL) {
		let iconsetUrl = source.deletingPathExtension().appendingPathExtension("iconset")
		let icnsUrl = iconsetUrl.appendingPathComponent("icon_512x512.png")
		let fileManager = FileManager.default
		do {
			var isDir : ObjCBool = false
			fileManager.fileExists(atPath: iconsetUrl.path, isDirectory:&isDir)
			if !isDir.boolValue {
				print("Created directory: \(iconsetUrl)")
				try FileManager.default.createDirectory(at: iconsetUrl, withIntermediateDirectories: true, attributes: nil)
			}
			if fileManager.fileExists(atPath: icnsUrl.path) {
				try fileManager.removeItem(at: icnsUrl)
			}
			
			try fileManager.copyItem(at: source, to: icnsUrl)
//			print("openProcess:")
			openProcess(path: "/usr/bin/iconutil", args: "-c", "icns", iconsetUrl.path)
//			print("Remove:")
//			print(iconsetUrl)
//			try fileManager.removeItem(at: iconsetUrl)
		} catch {
			print("\(error)")
			return
		}
	}
	
    // MARK: - NSDraggingDestination methods

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        super.draggingEntered(sender)
		backgroundImage.image = NSImage(named: "drop_prompt")
		let validDrop = (getAcceptedUrls(fromPasteboard: sender.draggingPasteboard).count > 0) ? true : false
        if validDrop {
            highlight()
            return .copy
        }
        return NSDragOperation()
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        super.draggingExited(sender)
		unhighlight()
//      if AppData.shared.imageCollection.count > 0 {
//          hide()
//      }
    }
	
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        super.performDragOperation(sender)
        let urls = getAcceptedUrls(fromPasteboard: sender.draggingPasteboard)
		
		if urls.count > 0 {
			DispatchQueue.global(qos: .userInitiated).async {
				let iconSet = IconSet()

				for url in urls {
					let wasAdded = iconSet.addImage(contentsOf: url)

					if wasAdded {
						let name = url.deletingPathExtension().lastPathComponent
						iconSet.name = name // Just use the name of the first successfully added file.
					}
				}
	
				DispatchQueue.main.async {
					self.unhighlight()
				}
			}
		}
		
//      for url in urls {
//          paths.append(url.path)
//          if url.path.hasSuffix(".\(Configuration.shared.saveDataExtension)") &&
//              appDelegate.loadImageDatabase(url)
//          {
//              // Found correct savefile and loaded successfully
//              // There's nothing else we need here
//              appDelegate.mainWindowController?.window?.makeKeyAndOrderFront(self)
//              return true
//          }
//      }
//      if AppData.shared.setLookupDirectories(paths) {
//          appDelegate.startScan(withConfirmation: true)
//      }
        return true
    }

}
