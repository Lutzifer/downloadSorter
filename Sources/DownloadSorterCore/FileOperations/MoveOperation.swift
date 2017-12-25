//
//  MoveOperation.swift
//  DownloadSorterSwift
//
//  Created by admin on 24.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

class MoveOperation: FileOperation {
  var state: OperationState = .todo

  var description: String {
    return "Will move \(sourcePath) to \(uniqueTargetPath)."
  }

  private let sourceFolder: String
  private let sourceFileName: String
  private let targetFolder: String
  private let targetFileName: String

  private var sourcePath: String {
    return String.path(from: [sourceFolder, sourceFileName])
  }

  private var uniqueTargetPath: String {
    var uniqueTargetPath = String.path(from: [targetFolder, targetFileName])

    // Add .2 to the name until it is unique
    while FileManager.default.fileExists(atPath: uniqueTargetPath) {
      let fileName = URL(fileURLWithPath: uniqueTargetPath).deletingPathExtension().lastPathComponent
      let fileExtension = URL(fileURLWithPath: uniqueTargetPath).pathExtension
      uniqueTargetPath = String.path(from: [targetFolder, "\(fileName).2.\(fileExtension)"])
    }

    return uniqueTargetPath
  }

  init(sourceFolder: String, targetFolder: String, fileName: String) {
    self.sourceFolder = sourceFolder
    self.sourceFileName = fileName
    self.targetFolder = targetFolder
    self.targetFileName = fileName
  }

  func doOperation() -> Bool {
    do {
      try FileManager.default.moveItem(atPath: sourcePath, toPath: uniqueTargetPath)
      state = OperationState.done
      return true
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      state = OperationState.failed
      return false
    }
  }
}
