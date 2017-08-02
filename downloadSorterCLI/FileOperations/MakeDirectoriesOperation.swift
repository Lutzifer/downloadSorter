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
  var directoryPath: String = ""

  var description: String {
    return "Will create directory \(directoryPath)"
  }

  func doOperation() -> Bool {
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
}
