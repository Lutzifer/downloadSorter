
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
    var operationList = Array<FileOperation>()
    
    var sourceFolder = ""
    var targetFolder = ""
    
    var urlDepth = 0
    
    func getListOfFilesInFolder(path: String) -> Array<String> {
        let fileManager = NSFileManager.defaultManager()
        var error: NSError?
        
        var fileFolderList: [AnyObject]?
        do {
            fileFolderList = try fileManager.contentsOfDirectoryAtPath(path)
        } catch let error1 as NSError {
            error = error1
            fileFolderList = nil
        }
        
        if(error != nil) {
            print("Error: \(error?.localizedDescription)")
            return []
        } else {
            var fileList = Array<String>()
            for file in fileFolderList as! Array<String> {
                var isDirectory: ObjCBool = false
                if(fileManager.fileExistsAtPath("\(path)/\(file)", isDirectory: &isDirectory)){
                    if(!isDirectory){
                        fileList.append("\(path)/\(file)")
                    }
                }
            }
            return fileList
        }
    }
    
    func extractTargetFolder(input: Array<AnyObject>) -> String {
        let isHTTP : NSPredicate = NSPredicate(format: "SELF MATCHES '^https?://.*'")
        let isFTP : NSPredicate = NSPredicate(format: "SELF MATCHES '^ftps?://.*'")
        let isEmail : NSPredicate = NSPredicate(format: "SELF MATCHES '.*<.*@.*>.*'")
        
        if( isHTTP.evaluateWithObject(input.first as! String) || isFTP.evaluateWithObject(input.first as! String) ){
            // get Host
            for result in Array(input.reverse()) {
                var resultArray = (result as! String).componentsSeparatedByString("/")

                if(resultArray.count > 2) {
                    var resultString : String = ""

                    // if URLDepth is set to value larger then 0, limit depth of hosts
                    if(self.urlDepth > 0) {
                        resultString = getLast(resultArray[2].splitByCharacter("."), count: self.urlDepth).joinWithSeparator(".")
                    } else {
                        resultString = resultArray[2]
                    }
                    
                    if(resultString != ""){
                        return resultString
                    }
                }
            }
            
            return ""
        } else if (isEmail.evaluateWithObject(input.first as! String)){
            // Take first field (Full Name) for this
            return (input.first as! String).componentsSeparatedByString("<")[0]
        } else {
            return input.last as! String
        }
    }
    
    func filterRunningDownloads(fileList: Array<String>) -> Array<String> {
        // filter running Firefox downloads, which consist of the original file and the original file with extension ".part"
        
        let partFiles = fileList.filter { (fileName) -> Bool in
            if let fileExtension = NSURL(fileURLWithPath: fileName).pathExtension {
                return fileExtension == "part"
            } else {
                return false
            }
        }
        
        var mutableFileList = fileList
        
        for partFile in partFiles {
            if let fileName = NSURL(fileURLWithPath: partFile).URLByDeletingPathExtension?.path,
                let partFileIndex = fileList.indexOf(partFile),
                let fileIndex = fileList.indexOf(fileName) {
                    let reverseIndices = [partFileIndex, fileIndex].sort{$0 > $1}

                    for index in reverseIndices {
                        mutableFileList.removeAtIndex(index)
                    }
            }
        }
        
        return mutableFileList.filter({ (fileName) -> Bool in
            // filter running downloads for chrome, opera and safari
            if let fileExtension = NSURL(fileURLWithPath: fileName).pathExtension {
                // Safari .download files are actually folders, so they are ignored anyway
                return !["crdownload", "opdownload"].contains(fileExtension)
            } else {
                return false
            }
        })
    }
    
    func analyze() -> String {
        let sourcePath = self.sourceFolder
        let targetPath = self.targetFolder
        
        // Reset Operation List
        self.operationList = Array<FileOperation>()
        
        let cleanFileList = filterRunningDownloads(getListOfFilesInFolder(sourcePath))
        
        for file in cleanFileList {
            let whereFroms : Array<AnyObject>? = AttributeExtractor.getWhereFromForPath(file)
            
                let fileManager = NSFileManager.defaultManager()
            
                var targetFolder : String
            
                if(whereFroms != nil) {
                    let extractedFolder = extractTargetFolder(whereFroms!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    targetFolder = "\(targetPath)/\(extractedFolder)"
                } else {
                    targetFolder = "Unknown Source"
                }
                
                if(!fileManager.fileExistsAtPath(targetFolder)){
                    let directoryOperation = MakeDirectoriesOperation()
                    directoryOperation.directoryPath = targetFolder
                    operationList.append(directoryOperation)
                }
                
                let moveOperation = MoveOperation()
                let fileName = file.stringByReplacingOccurrencesOfString(sourcePath, withString: "", options: [], range: nil)
                
                moveOperation.sourceFolder = sourcePath
                moveOperation.sourceFileName = fileName
                moveOperation.targetFolder = targetFolder
                moveOperation.targetFileName = fileName
                
                operationList.append(moveOperation)
            }

        
        var result  = ""
        for fileOperation in operationList {
            result = result + "\n" + fileOperation.describe()
        }
        
        return result
        
    }
    
    func doOperations() -> String {
        for fileOperation in operationList {
            if(fileOperation.state != OperationState.todo){
                break
            } else {
                if(!fileOperation.doOperation()){
                    return "failed";
                }
            }
        }

        return "done";
    }
    
    func undoOperations() -> String {
        for fileOperation in Array(operationList.reverse()) {
            if(fileOperation.state == OperationState.done){
                fileOperation.undoOperation()
            }
        }
        return "undone";
    }

    // http://stackoverflow.com/questions/31007643/in-swift-whats-the-cleanest-way-to-get-the-last-two-items-in-an-array
    func getLast<T>(array: [T], count: Int) -> [T] {
        if count >= array.count {
            return array
        }
        let first = array.count - count
        return Array(array[first..<first+count])
    }

}