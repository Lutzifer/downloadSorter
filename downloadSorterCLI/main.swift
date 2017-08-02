//
//  main.swift
//  downloadSorter
//
//  Created by Wolfgang Lutz on 05.10.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Foundation

let cli = CommandLine()

let sourcePathOption = StringOption(
  shortFlag: "s",
  longFlag: "sourcepath",
  helpMessage: "Path to the folder which contains the files to process."
)

let destinationPathOption = StringOption(
  shortFlag: "t",
  longFlag: "targetpath",
  helpMessage: "Path to the folder to which the files are processed to. "
    + "If not given, the sourcepath is used."
)

let helpOption = BoolOption(
  shortFlag: "h",
  longFlag: "help",
  helpMessage: "Prints a help message."
)

let dryrunOption = BoolOption(
  shortFlag: "d",
  longFlag: "dry-run",
  helpMessage: "Print what will happen instead of actually doing it."
)

let urlDepthOption = IntOption(
  shortFlag: "u",
  longFlag: "urldepth",
  helpMessage: "Limits the depth of urls. "
    + "A value of 2 would shorten www.example.com to example.com. "
    + "Default is 0 (no limit). Negative values are interpreted as 0."
)

cli.addOptions(sourcePathOption, destinationPathOption, helpOption, dryrunOption, urlDepthOption)

do {
  try cli.parse()
} catch {
  cli.printUsage(error)
  exit(EX_USAGE)
}

if helpOption.value {
  cli.printUsage()
  exit(0)
}

let sortManager = SortManager(
  sourceFolder: sourcePathOption.value,
  targetFolder: destinationPathOption.value,
  urlDepth: urlDepthOption.value
)

if !dryrunOption.value {
  print(sortManager.doOperations())
} else {
  print(sortManager.analyze())
}
