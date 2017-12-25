//
//  MakeDirectoriesOperation.swift
//  DownloadSorterSwift
//
//  Created by admin on 25.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Cocoa

class MakeDirectoriesOperation: FileOperation {
  var state: OperationState = .todo
  let directoryPath: String

  var description: String {
    return "Will create directory \(directoryPath)"
  }

  init(directoryPath: String) {
    self.directoryPath = directoryPath
  }

  // create all Directories needed
  func doOperation() -> Bool {
    do {
      try FileManager.default.createDirectory(
        atPath: directoryPath,
        withIntermediateDirectories: true
      )
      self.state = OperationState.done
      return true
    } catch let error as NSError {
      print("Error: \(error.localizedDescription)")
      self.state = OperationState.failed
      return false
    }
  }
}
