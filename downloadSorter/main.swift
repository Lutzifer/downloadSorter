//
//  main.swift
//  downloadSorter
//
//  Created by Wolfgang Lutz on 05.10.15.
//  Copyright © 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

let cli = CommandLine()

let sourcePath = StringOption(shortFlag: "s", longFlag: "sourcepath", required: true,
    helpMessage: "Path to the Folder which contains the files to process.")
let destinationPath = StringOption(shortFlag: "t", longFlag: "targetpath",
    helpMessage: "Path to the Folder which where the files are processed to. If not given, the sourcepath is used.")
let help = BoolOption(shortFlag: "h", longFlag: "help",
    helpMessage: "Prints a help message.")
let dryrun = BoolOption(shortFlag: "d", longFlag: "dry-run",
    helpMessage: "Print what will happen instead of doing it.")

cli.addOptions(sourcePath, destinationPath, help, dryrun)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

// Sourcepath is required, so this should always work
if let sourcePathString = sourcePath.value {
    SortManager.sharedInstance.sourceFolder = sourcePathString
    if let destinationPathString = destinationPath.value {
        SortManager.sharedInstance.targetFolder = destinationPathString
    } else {
        SortManager.sharedInstance.targetFolder = sourcePathString
    }
}

if(dryrun.value) {
    print(SortManager.sharedInstance.analyze())
} else {
    print(SortManager.sharedInstance.analyze())
    print(SortManager.sharedInstance.doOperations())
}
