//
//  FileOperation.swift
//  DownloadSorterSwift
//
//  Created by Wolfgang Lutz on 25.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Cocoa

enum OperationState {
  case todo
  case done
  case undone
  case failed
}

protocol FileOperation: CustomStringConvertible {
  var state: OperationState { get set }

  func doOperation() -> Bool
  func undoOperation() -> Bool
}
