//
//  main.swift
//  downloadSorter
//
//  Created by Wolfgang Lutz on 05.10.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

let cli = CommandLine()

let sourcePath = StringOption(
  shortFlag: "s",
  longFlag: "sourcepath",
  helpMessage: "Path to the Folder which contains the files to process."
)

let destinationPath = StringOption(
  shortFlag: "t",
  longFlag: "targetpath",
  helpMessage: "Path to the Folder which where the files are processed to. "
    + "If not given, the sourcepath is used."
)

let help = BoolOption(
  shortFlag: "h",
  longFlag: "help",
  helpMessage: "Prints a help message."
)

let dryrun = BoolOption(
  shortFlag: "d",
  longFlag: "dry-run",
  helpMessage: "Print what will happen instead of doing it."
)

let urlDepth = IntOption(
  shortFlag: "u",
  longFlag: "urldepth",
  helpMessage: "Limits the depth of urls. "
    + "A value of 2 would shorten www.example.com to example.com. "
    + "Default is 0 (no limit). Negative values are interpreted as 0."
)

cli.addOptions(sourcePath, destinationPath, help, dryrun, urlDepth)

do {
  try cli.parse()
} catch {
  cli.printUsage(error)
  exit(EX_USAGE)
}

if help.value {
  cli.printUsage()
  exit(0)
}

if sourcePath.value == nil {
  _ = sourcePath.setValue(["."])
}

if let sourcePathString = sourcePath.value {
  var absoluteSourcePath: String

  if sourcePathString == "." {
    absoluteSourcePath = FileManager.default.currentDirectoryPath
  } else {
    absoluteSourcePath = sourcePathString
  }

  SortManager.sharedInstance.sourceFolder = absoluteSourcePath

  if let destinationPathString = destinationPath.value {
    var absoluteDestinationPath: String

    if destinationPathString == "." {
      absoluteDestinationPath = FileManager.default.currentDirectoryPath
    } else {
      absoluteDestinationPath = destinationPathString
    }

    SortManager.sharedInstance.targetFolder = absoluteDestinationPath
  } else {
    SortManager.sharedInstance.targetFolder = absoluteSourcePath
  }
}

if let urlDepthValue = urlDepth.value {
  if urlDepthValue < 0 {
    print("Negative value set for numDepth, resorting to default(\(SortManager.sharedInstance.urlDepth))")
  } else {
    SortManager.sharedInstance.urlDepth = urlDepthValue
  }
}

print(SortManager.sharedInstance.analyze())

if !dryrun.value {
  print(SortManager.sharedInstance.doOperations())
}
