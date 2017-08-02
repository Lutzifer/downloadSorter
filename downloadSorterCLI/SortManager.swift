//
//  SortManager.swift
//  DownloadSorterGUI
//
//  Created by Wolfgang Lutz on 28.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

enum KindDetectorRegex: String {
  case https = "^https?://.*"
  case ftps = "^ftps?://.*"
  case email = ".*<.*@.*>.*"
}

class SortManager {
  static let defaultUrlDepth: Int = 0

  var operationList: [FileOperation] = [FileOperation]()

  let sourceFolder: String
  let targetFolder: String
  let urlDepth: Int

  init(sourceFolder: String?, targetFolder: String?, urlDepth: Int?) {
    if sourceFolder == "." {
      self.sourceFolder = FileManager.default.currentDirectoryPath
    } else {
      self.sourceFolder = sourceFolder ?? FileManager.default.currentDirectoryPath
    }

    if targetFolder == "." {
      self.targetFolder = FileManager.default.currentDirectoryPath
    } else {
      self.targetFolder = targetFolder ?? sourceFolder ?? FileManager.default.currentDirectoryPath
    }

    if let urlDepth = urlDepth, urlDepth < 0 {
      print("Negative value set for numDepth, resorting to default(\(SortManager.defaultUrlDepth))")
      self.urlDepth = SortManager.defaultUrlDepth
    } else {
      self.urlDepth = urlDepth ?? SortManager.defaultUrlDepth
    }
  }

  func getListOfFiles(at path: String) -> [String] {
    return ((try? FileManager.default.contentsOfDirectory(atPath: path)) ?? [String]()).filter({
      var isDirectory: ObjCBool = false
      return FileManager.default.fileExists(atPath: "\(path)/\($0)", isDirectory: &isDirectory)
        && !isDirectory.boolValue
    }).map {
      path.appending("/").appending($0)
    }
  }

  func extractTargetFolder(_ input: [String]) -> String? {
    guard let first = input.first, let last = input.last else {
      return nil
    }

    if first.matchesRegex(.https) || first.matchesRegex(.ftps) {
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
                let suffixLength = suffix!.characters.count + 1 // (+1 to include dot)
                let endIndex = resultString.characters.index(resultString.endIndex, offsetBy: -suffixLength)
                let prefix = resultString.substring(with: resultString.startIndex ..< endIndex)
                resultString = [prefix, "suffix"].joined(separator: ".")
                break
              }
            }

            resultString = resultString.components(separatedBy: ".").suffix(self.urlDepth).joined(separator: ".")

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
    } else if first.matchesRegex(.email) {
      // Take first field (Full Name) for this
      return first.components(separatedBy: "<")[0]
    } else {
      return last
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
      !["crdownload", "opdownload"].contains(URL(fileURLWithPath: fileName).pathExtension)

    })
  }

  func analyze() -> String {
    let sourcePath = self.sourceFolder
    let targetPath = self.targetFolder

    // Reset Operation List
    self.operationList = [FileOperation]()

    var cleanFileList: [String] = filterRunningDownloads(getListOfFiles(at: sourcePath))

    // Filter dot files
    cleanFileList = cleanFileList.filter({ (filePath: String) -> Bool in
      let fileName = URL(fileURLWithPath: filePath).lastPathComponent
      return !fileName.hasPrefix(".")
    })

    for path in cleanFileList {
      let whereFroms = AttributeExtractor.getWhereFromsFromFile(at: path)

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
      let fileName = path.replacingOccurrences(of: sourcePath, with: "", options: [], range: nil)

      moveOperation.sourceFolder = sourcePath
      moveOperation.sourceFileName = fileName
      moveOperation.targetFolder = targetFolder
      moveOperation.targetFileName = fileName

      operationList.append(moveOperation)
    }

    var result = ""
    for fileOperation in operationList {
      result += "\n" + fileOperation.description
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
    if operationList.isEmpty {
      return "done"
    } else {
      return ""
    }
  }

  func undoOperations() -> String {

    let undoneOperations = Array(operationList.reversed())
      .filter { $0.state == OperationState.done }
      .filter { $0.undoOperation() }

    if undoneOperations.isEmpty {
      return "undone"
    } else {
      return ""
    }
  }
}

extension String {
  func matchesRegex(_ regex: KindDetectorRegex) -> Bool {
    let predicate: NSPredicate = NSPredicate(format: "SELF MATCHES '\(regex)'")
    return predicate.evaluate(with: self)
  }
}
