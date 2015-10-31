//
//  MoveOperation.swift
//  DownloadSorterSwift
//
//  Created by Wolfgang Lutz on 24.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

class MoveOperation : FileOperation {
    var sourceFolder : String = ""
    var sourceFileName : String = ""
    var targetFolder : String = ""
    var targetFileName : String = ""
    
    func sourcePath() -> String {
        return NSString.pathWithComponents([sourceFolder, sourceFileName])
    }
    
    func targetPath() -> String {
        return NSString.pathWithComponents([targetFolder, targetFileName])
    }
    
    override func describe() -> String {
        return "Will move \(sourcePath()) to \(targetPath())."
    }
    
    override func doOperation() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        
        // Add .2 to the name until it is unique
        while(fileManager.fileExistsAtPath(targetPath())){
            let fileExtension = NSURL(fileURLWithPath: targetPath()).pathExtension
            let fileName = NSURL(fileURLWithPath: targetPath()).URLByDeletingPathExtension?.lastPathComponent
            guard (fileName != nil) else {
                self.state = OperationState.failed
                return false
            }
            
            guard (fileExtension != nil) else {
                self.state = OperationState.failed
                return false
            }
        
            targetFileName = "\(fileName!).2.\(fileExtension!)"
        }
        
        do {
            try fileManager.moveItemAtPath(sourcePath(), toPath: targetPath())
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
        var error: NSError?
        
        do {
            try fileManager.moveItemAtPath(targetPath(), toPath: sourcePath())
        } catch let error1 as NSError {
            error = error1
        }
    
        if(error != nil) {
            print("Error: \(error?.localizedDescription)")
            self.state = OperationState.failed
            return false
        } else {
            self.state = OperationState.undone
            return true
        }
    }
}
