//
//  MakeDirectoriesOperation.swift
//  DownloadSorterSwift
//
//  Created by Wolfgang Lutz on 25.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Cocoa

class MakeDirectoriesOperation: FileOperation {
    var directoryPath : String = ""
    
    override func describe() -> String { return "Will create directory \(directoryPath)" }
    
    override func doOperation() -> Bool {
        // create all Directories needed
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
            self.state = OperationState.done
            return true
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            self.state = OperationState.failed
            return false
        }
    }
    
    override func undoOperation() -> Bool {
        let fileManager = NSFileManager.defaultManager()        
        // Delete Directories, if they are empty
        
        var isEmpty = false;
        var path = NSURL(fileURLWithPath: directoryPath);
        
        repeat{
            isEmpty = (try! fileManager.contentsOfDirectoryAtPath(path.absoluteString)).count == 0
            if(isEmpty) {
                print("Remove Directory \(path)")
                do {
                    try fileManager.removeItemAtPath(path.absoluteString)
                    // remove last dir for next round
                    path = path.URLByDeletingLastPathComponent!
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
