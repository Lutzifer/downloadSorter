//
//  ViewController.swift
//  DownloadSorterGUI
//
//  Created by Wolfgang Lutz on 28.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var analyzeButton: NSButton!
//    @IBOutlet weak var undoButton: NSButton!
    @IBOutlet weak var sortButton: NSButton!
    
    @IBOutlet weak var chooseTargetFolderButton: NSButton!
    @IBOutlet weak var chooseSourceFolderButton: NSButton!
    @IBOutlet var logView: NSTextView!
    
    @IBOutlet weak var sourcePathControl: NSPathControl!
    @IBOutlet weak var targetPathControl: NSPathControl!
    @IBOutlet weak var analyzeCheckbox: NSButton!

    @IBOutlet weak var folderSelectTextfield: NSTextField!
    @IBOutlet weak var folderModePopUpButton: NSPopUpButton!
    @IBAction func analyzeButtonPressed(sender: NSButton) {
        if(targetPathControl.URL != nil || sourcePathControl.URL != nil){
            let al = NSAlert()
            al.informativeText = "Please choose a Source Folder first"
            al.messageText = "We will look in this folder for files to sort."
            al.showsHelp = false
            al.runModal()
            
            return
        }else {
        
        SortManager.sharedInstance.targetFolder = targetPathControl.URL!.path!
        
        SortManager.sharedInstance.sourceFolder = sourcePathControl.URL!.path!
        
        let result = SortManager.sharedInstance.analyze()
        if( result != "") {
            self.logView.string = result
            sortButton.enabled = true
        } else {
            self.logView.string = "No suitable files found to sort!"
            sortButton.enabled = false
        }
        }
//        undoButton.enabled = false
    }
    
    @IBAction func chooseSourceFolderButtonClicked(sender: NSButton) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.sourcePathControl.URL = openPanel.URL
                self.targetPathControl.URL = openPanel.URL
            }
        }
    }

    @IBAction func chooseTargetFolderButtonClicked(sender: NSButton) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.targetPathControl.URL = openPanel.URL
            }
        }

    }
    
    @IBAction func analyzeCheckboxChanged(sender: NSButton) {
        NSUserDefaults.standardUserDefaults().setBool((sender.state == NSOnState), forKey:"analyzeBeforeSort")
        self.setupAnalyze()
    }
    
    @IBAction func undoButtonPressed(sender: NSButton) {
        self.logView.string = SortManager.sharedInstance.undoOperations()
    }
    
    @IBAction func sortButtonPressed(sender: NSButton) {

        if(targetPathControl.URL != nil || sourcePathControl.URL != nil){
        let al = NSAlert()
        al.informativeText = "Please choose a Source Folder first"
        al.messageText = "We will look in this folder for files to sort."
        al.showsHelp = false
        al.runModal()
        
        return
    }else {
        
        SortManager.sharedInstance.targetFolder = targetPathControl.URL!.path!
        
        SortManager.sharedInstance.sourceFolder = sourcePathControl.URL!.path!
        
    if(NSUserDefaults.standardUserDefaults().boolForKey("analyzeBeforeSort")){
        let result = SortManager.sharedInstance.analyze()

        if( result != "") {
            self.logView.string = result
            sortButton.enabled = true
        } else {
            self.logView.string = "No suitable files found to sort!"
            sortButton.enabled = false
        }
    } else {

    
        self.logView.string = SortManager.sharedInstance.doOperations()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourcePathControl.URL = NSURL(fileURLWithPath: SortManager.sharedInstance.sourceFolder)
        
        targetPathControl.URL = NSURL(fileURLWithPath: SortManager.sharedInstance.targetFolder)
        
        self.setupAnalyze()
        self.setupTargetFolder()
    }
    
    func setupAnalyze() {
    if(NSUserDefaults.standardUserDefaults().boolForKey("analyzeBeforeSort")){
            self.analyzeCheckbox.state = NSOnState
            self.sortButton.title = "Analyze"
    } else {
        self.analyzeCheckbox.state = NSOffState
        self.sortButton.title = "Sort"
        }
    }

    func setupTargetFolder() {
        if(NSUserDefaults.standardUserDefaults().boolForKey("useSourceFolderAsTargetFolder")){
            self.folderModePopUpButton.selectItemWithTag(0)
                self.targetPathControl.hidden = true
                self.chooseTargetFolderButton.hidden = true
            self.folderSelectTextfield.stringValue = "folder."
        } else {
            self.folderModePopUpButton.selectItemWithTag(1)
            self.targetPathControl.hidden = false
            self.chooseTargetFolderButton.hidden = false
                        self.folderSelectTextfield.stringValue = "folder, namely"
        }
    }
    
    @IBAction func didChangeFolderMode(sender: NSPopUpButton) {
        NSUserDefaults.standardUserDefaults().setBool((sender.selectedTag() == 0), forKey:"useSourceFolderAsTargetFolder")
        self.setupTargetFolder()
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

