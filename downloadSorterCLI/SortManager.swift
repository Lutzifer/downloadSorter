//
//  SortManager.swift
//  DownloadSorterGUI
//
//  Created by Wolfgang Lutz on 28.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

class SortManager {
	static let sharedInstance = SortManager()
	var operationList = [FileOperation]()

	var sourceFolder = ""
	var targetFolder = ""

	var urlDepth = 0

	func getListOfFilesInFolder(_ path: String) -> [String] {
		let fileManager = FileManager.default
		var error: NSError?

		var fileFolderList: [String]
		do {
			fileFolderList = try fileManager.contentsOfDirectory(atPath: path)
		} catch let error1 as NSError {
			error = error1
			fileFolderList = []
		}

		if error != nil {
			print("Error: \(String(describing: error?.localizedDescription))")
			return []
		} else {
			var fileList = [String]()
			for file in fileFolderList {
				var isDirectory: ObjCBool = false
				if(fileManager.fileExists(atPath: "\(path)/\(file)", isDirectory: &isDirectory)) {
					if !isDirectory.boolValue {
						fileList.append("\(path)/\(file)")
					}
				}
			}
			return fileList
		}
	}

	func extractTargetFolder(_ input: [String]) -> String? {
		let isHTTP: NSPredicate = NSPredicate(format: "SELF MATCHES '^https?://.*'")
		let isFTP: NSPredicate = NSPredicate(format: "SELF MATCHES '^ftps?://.*'")
		let isEmail: NSPredicate = NSPredicate(format: "SELF MATCHES '.*<.*@.*>.*'")

		if isHTTP.evaluate(with: input.first) || isFTP.evaluate(with: input.first) {
			// get Host
			for result in Array(input.reversed()) {
				var resultArray = result.components(separatedBy: "/")

				if resultArray.count > 2 {
					var resultString: String = resultArray[2]

					// if URLDepth is set to value larger then 0, limit depth of hosts
					if self.urlDepth > 0 {
						var suffix: String?

						// replace multipart TLD with a singlePartTLD
						for tld in TLDList.multiPartTLDs() {
							if resultString.hasSuffix(".\(tld)") {
								suffix = tld
								let suffixLength = suffix!.characters.count + 1// (+1 to include dot)
								let endIndex = resultString.characters.index(resultString.endIndex, offsetBy: -suffixLength)
								let prefix = resultString.substring(with: resultString.startIndex..<endIndex)
								resultString = [prefix, "suffix"].joined(separator: ".")
								break
							}
						}

						resultString = getLast(resultString.components(separatedBy: "."), count: self.urlDepth).joined(separator: ".")

						// replace singlepart TLD with multipart TLD
						if let realSuffix = suffix {
							var strings = resultString.components(separatedBy: ".")
							strings.removeLast()
							strings.append(realSuffix)
							resultString = strings.joined(separator: ".")
						}

					}

					if resultString != "" {
						return resultString
					}
				}
			}

			return ""
		} else if isEmail.evaluate(with: input.first) {
			// Take first field (Full Name) for this
			return input.first?.components(separatedBy: "<")[0]
		} else {
			return input.last
		}
	}

	func filterRunningDownloads(_ fileList: [String]) -> [String] {
		// filter running Firefox downloads, which consist of the original file and the original file with extension ".part"

		let partFiles = fileList.filter { (fileName) -> Bool in
			URL(fileURLWithPath: fileName).pathExtension == "part"
		}

		var mutableFileList = fileList

		for partFile in partFiles {
			if let fileName = NSURL(fileURLWithPath: partFile).deletingPathExtension?.path,
				let partFileIndex = fileList.index(of: partFile),
				let fileIndex = fileList.index(of: fileName) {
				let reverseIndices = [partFileIndex, fileIndex].sorted { $0 > $1 }

				for index in reverseIndices {
					mutableFileList.remove(at: index)
				}
			}
		}

		return mutableFileList.filter({ (fileName) -> Bool in
			// filter running downloads for chrome, opera and safari
			// Safari .download files are actually folders, so they are ignored anyway
			return !["crdownload", "opdownload"].contains(URL(fileURLWithPath: fileName).pathExtension)

		})
	}

	func analyze() -> String {
		let sourcePath = self.sourceFolder
		let targetPath = self.targetFolder

		// Reset Operation List
		self.operationList = [FileOperation]()

		var cleanFileList: [String] = filterRunningDownloads(getListOfFilesInFolder(sourcePath))

		// Filter dot files
		cleanFileList = cleanFileList.filter({ (filePath: String) -> Bool in
			let fileName = URL(fileURLWithPath: filePath).lastPathComponent
			return !fileName.hasPrefix(".")
		})

		for file in cleanFileList {
			if let whereFroms = AttributeExtractor.getWhereFrom(forPath: file) as [String]? {

				let fileManager = FileManager.default

				var targetFolder: String

				if !whereFroms.isEmpty,
					let extractedFolder = extractTargetFolder(whereFroms) {
					let trimmedExtractedFolder = extractedFolder.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
					targetFolder = "\(targetPath)/\(trimmedExtractedFolder)"
				} else {
					targetFolder = "Unknown Source"
				}

				if !fileManager.fileExists(atPath: targetFolder) {
					let directoryOperation = MakeDirectoriesOperation()
					directoryOperation.directoryPath = targetFolder
					operationList.append(directoryOperation)
				}

				let moveOperation = MoveOperation()
				let fileName = file.replacingOccurrences(of: sourcePath, with: "", options: [], range: nil)

				moveOperation.sourceFolder = sourcePath
				moveOperation.sourceFileName = fileName
				moveOperation.targetFolder = targetFolder
				moveOperation.targetFileName = fileName

				operationList.append(moveOperation)
			}
		}

		var result = ""
		for fileOperation in operationList {
			result += "\n" + fileOperation.describe()
		}

		if result == "" {
			result = "Nothing to do"
		}

		return result

	}

	func doOperations() -> String {
		for fileOperation in operationList {
			if fileOperation.state != OperationState.todo {
				break
			} else {
				if !fileOperation.doOperation() {
					return "failed"
				}
			}
		}
		if operationList.count > 0 {
			return "done"
		} else {
			return ""
		}
	}

	func undoOperations() -> String {

		let undoneOperations = Array(operationList.reversed())
			.filter { $0.state == OperationState.done }
			.filter { $0.undoOperation() }

		if undoneOperations.count > 0 {
			return "undone"
		} else {
			return ""
		}
	}

	// http://stackoverflow.com/questions/31007643/in-swift-whats-the-cleanest-way-to-get-the-last-two-items-in-an-array
	func getLast<T>(_ array: [T], count: Int) -> [T] {
		if count >= array.count {
			return array
		}
		let first = array.count - count
		return Array(array[first..<first + count])
	}

}
