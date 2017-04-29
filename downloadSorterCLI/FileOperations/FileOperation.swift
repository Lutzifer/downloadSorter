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

class FileOperation: NSObject {
    var state : OperationState = OperationState.todo
    
    func doOperation() -> Bool { return false }

    func undoOperation() -> Bool { return false }
    
    func describe() -> String { return "undefined" }
}
