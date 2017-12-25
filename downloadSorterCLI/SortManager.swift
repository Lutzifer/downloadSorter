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

struct SortManager {
  static let defaultUrlDepth: Int = 0

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

  func getFiles(at path: String) -> [URL] {
    return ((try? FileManager.default.contentsOfDirectory(atPath: path)) ?? [String]())
      .map { String.path(from: [path, $0]) }
      .filter({
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: $0, isDirectory: &isDirectory)
          && !isDirectory.boolValue
      }).map {
        URL(fileURLWithPath: $0)
      }
  }

  func extractTargetFolder(_ input: [String]) -> String? {
    guard let first = input.first else {
      return nil
    }

    if first.matches(.https) || first.matches(.ftps) {
      // get Host
      return input
        .reversed()
        .map { $0.components(separatedBy: "/") }
        .filter { $0.count > 2 }
        .map { stringArray -> String in stringArray[2] }
        .map { string -> String in
          var resultString = string
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

          return resultString
        }
        .first(where: { $0 != "" })
    } else if first.matches(.email) {
      // Take first field (Full Name) for this
      return first.components(separatedBy: "<")[0]
    } else {
      return input.last
    }
  }

  func filterRunningDownloads(from list: [URL]) -> [URL] {
    // filter running Firefox downloads, which consist of the original file and the original file with extension ".part"

    // get all urls, which have a corresponding partFile
    let urlsWithPartFile = list.filter { $0.pathExtension == "part" }
      .map { URL(fileURLWithPath: $0.absoluteString.replacingOccurrences(of: ".part", with: "")) }

    return list.filter {
      // filter files, that have a part file, actual partfiles are filtered later
      !urlsWithPartFile.contains($0)
    }.filter {
      // filter running downloads for chrome, opera and safari (and firefox part files)
      // Safari .download files are actually folders, so they are ignored anyway
      !["crdownload", "opdownload", "part"].contains($0.pathExtension)
    }
  }

  private var operations: [FileOperation] {
    return filterRunningDownloads(from: getFiles(at: sourceFolder))
      // Filter dot files
      .filter { !$0.lastPathComponent.hasPrefix(".") }
      .flatMap { url -> [FileOperation] in
        var operations = [FileOperation]()

        let whereFroms = FileManager.getWhereFromsFromFile(at: url.path)

        let targetSubFolder: String

        if !whereFroms.isEmpty,
          let trimmedExtractedFolder = extractTargetFolder(whereFroms)?.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
          ) {
          targetSubFolder = trimmedExtractedFolder
        } else {
          targetSubFolder = "Unknown Source"
        }

        let targetFolderPath = String.path(from: [targetFolder, targetSubFolder])

        if !FileManager.default.fileExists(atPath: targetFolderPath) {
          operations.append(MakeDirectoriesOperation(directoryPath: targetFolderPath))
        }

        operations.append(MoveOperation(
          sourceFolder: sourceFolder,
          targetFolder: targetFolderPath,
          fileName: url.lastPathComponent
        ))

        return operations
      }
  }

  func analyze() -> String {
    let result =
      operations
      .map { $0.description }
      .joined(separator: "\n")

    if result == "" {
      return "Nothing to do"
    } else {
      return result
    }
  }

  func doOperations() -> String {
    return operations
      .filter {
        $0.state == OperationState.todo
      }.map {
        [$0.description, $0.doOperation() ? "done" : "failed"].joined(separator: ": ")
      }.joined(separator: "\n")
  }
}

extension String {
  func matches(_ regex: KindDetectorRegex) -> Bool {
    return self.range(of: regex.rawValue, options: .regularExpression, range: nil, locale: nil) != nil
  }
}
