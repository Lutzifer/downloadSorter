//
//  MakeDirectoriesOperation.swift
//  DownloadSorterSwift
//
//  Created by admin on 25.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Cocoa

class MakeDirectoriesOperation: FileOperation {
	var directoryPath: String = ""

	override func describe() -> String { return "Will create directory \(directoryPath)" }

	override func doOperation() -> Bool {
		// create all Directories needed
		let fileManager = FileManager.default

		do {
			try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
			self.state = OperationState.done
			return true
		} catch let error as NSError {
			print("Error: \(error.localizedDescription)")
			self.state = OperationState.failed
			return false
		}
	}

	override func undoOperation() -> Bool {
		let fileManager = FileManager.default
		// Delete Directories, if they are empty

		var isEmpty = false
		var path = URL(fileURLWithPath: directoryPath)

		repeat {
			isEmpty = (try? fileManager.contentsOfDirectory(atPath: path.absoluteString))?.isEmpty ?? false

			if isEmpty {
				print("Remove Directory \(path)")
				do {
					try fileManager.removeItem(atPath: path.absoluteString)
					// remove last dir for next round
					path = path.deletingLastPathComponent()
				} catch let error as NSError {
					print("Error: \(error.localizedDescription)")
					self.state = OperationState.failed
					return false
				}

			}
		} while(isEmpty)

		self.state = OperationState.undone
		return true
	}
}
