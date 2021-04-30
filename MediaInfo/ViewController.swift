//
//  ViewController.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync

class ViewController: NSViewController {
    @objc dynamic var isImageHandled: Bool = true {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
        }
    }
    @objc dynamic var isPrintedSizeHidden: Bool = false
    @objc dynamic var isCustomDPIHidden: Bool = false  {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
        }
    }
    @objc dynamic var customDPI: Int = 300
    @objc dynamic var unit: Int = 0
    @objc dynamic var isColorHidden: Bool = false
    @objc dynamic var isDepthHidden: Bool = false
    @objc dynamic var isImageIconHidden: Bool = false
    @objc dynamic var isImageInfoOnSubmenu: Bool = true
    @objc dynamic var isImageInfoOnMainItem: Bool = false
    @objc dynamic var isMediaInfoOnMainItem: Bool = false
    
    @objc dynamic var isDPIEnabled: Bool {
        return isImageHandled && !isCustomDPIHidden
    }
    
    @objc dynamic var isVideoHandled: Bool = true
    @objc dynamic var isFramesHidden: Bool = false
    @objc dynamic var isCodecHidden: Bool = false
    @objc dynamic var isBPSHidden: Bool = false
    @objc dynamic var isTracksGrouped: Bool = false
    @objc dynamic var isMediaIconHidden: Bool = false
    @objc dynamic var isMediaInfoOnSubmenu: Bool = true
    
    @objc dynamic var isExtensionEnabled: Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
    
    var folders: [URL] = []
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = Settings.shared
        
        self.isImageHandled = settings.isImagesHandled
        self.isPrintedSizeHidden = settings.isPrintHidden
        self.isCustomDPIHidden = settings.isCustomPrintHidden
        self.isColorHidden = settings.isColorHidden
        self.isDepthHidden = settings.isDepthHidden
        self.customDPI = settings.customDPI
        self.unit = settings.unit.rawValue
        self.isImageIconHidden = settings.isImageIconsHidden
        self.isImageInfoOnSubmenu = settings.isImageInfoOnSubMenu
        self.isImageInfoOnMainItem = settings.isImageInfoOnMainItem
        
        self.isVideoHandled = settings.isMediaHandled
        self.isFramesHidden = settings.isFramesHidden
        self.isCodecHidden = settings.isCodecHidden
        self.isBPSHidden = settings.isBPSHidden
        self.isTracksGrouped = settings.isTracksGrouped
        self.isMediaIconHidden = settings.isMediaIconsHidden
        self.isMediaInfoOnSubmenu = settings.isMediaInfoOnSubMenu
        self.isMediaInfoOnMainItem = settings.isMediaInfoOnMainItem
        
        self.folders = settings.folders.sorted(by: { $0.path < $1.path })
        
        DispatchQueue.main.async {
            if !FIFinderSyncController.isExtensionEnabled {
                let p = NSAlert()
                p.messageText = NSLocalizedString("Finder extension not enabled", comment: "")
                // p.informativeText = "The finder sync extension is not enabled."
                p.alertStyle = .warning
                p.addButton(withTitle: NSLocalizedString("Enable", comment: ""))
                p.addButton(withTitle: NSLocalizedString("Ignore", comment: ""))
                if p.runModal() == .alertFirstButtonReturn {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func doAddFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        // dialog.title                   = "Choose an archive file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        // dialog.allowedFileTypes        = ["txt"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url {
                self.folders.append(result)
                self.folders.sort(by: { $0.path < $1.path })
                self.tableView.reloadData()
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func doRemoveFolder(_ sender: Any) {
        guard tableView.selectedRow >= 0 else {
            return
        }
        self.folders.remove(at: tableView.selectedRow)
        self.tableView.reloadData()
    }

    @IBAction func doSave(_ sender: Any) {
        let folders = Array(Set(self.folders))
        if folders.isEmpty {
            let p = NSAlert()
            p.messageText = NSLocalizedString("No folders selected to be monitored", comment: "")
            p.informativeText = NSLocalizedString("Are you sure you want to continue?", comment: "")
            p.alertStyle = .warning
            p.addButton(withTitle: NSLocalizedString("Continue", comment: "")).keyEquivalent="\r"
            p.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}" // esc
            let r = p.runModal()
            if r == .alertSecondButtonReturn {
                return
            }
        }
        
        let settings = Settings.shared
        
        let current_folders = settings.folders
        
        settings.folders = folders
        settings.isImagesHandled = self.isImageHandled
        settings.isPrintHidden = self.isPrintedSizeHidden
        settings.isCustomPrintHidden = self.isCustomDPIHidden
        settings.isColorHidden = self.isColorHidden
        settings.isDepthHidden = self.isDepthHidden
        settings.customDPI = self.customDPI
        settings.unit = PrintUnit(rawValue: self.unit) ?? .cm
        settings.isImageIconsHidden = self.isImageIconHidden
        settings.isImageInfoOnSubMenu = self.isImageInfoOnSubmenu
        settings.isImageInfoOnMainItem = self.isImageInfoOnMainItem
        
        settings.isMediaHandled = self.isVideoHandled
        settings.isFramesHidden = self.isFramesHidden
        settings.isCodecHidden = self.isCodecHidden
        settings.isBPSHidden = self.isBPSHidden
        settings.isTracksGrouped = self.isTracksGrouped
        settings.isMediaIconsHidden = self.isMediaIconHidden
        settings.isMediaInfoOnSubMenu = self.isMediaInfoOnSubmenu
        settings.isMediaInfoOnMainItem = self.isMediaInfoOnMainItem
        
        settings.synchronize()
        
        if current_folders != folders && FIFinderSyncController.isExtensionEnabled {
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "MediaInfoMonitoredFolderChanged"), object: Bundle.main.bundleIdentifier, userInfo: nil, options: [.deliverImmediately])
        }
    
        self.view.window?.orderOut(sender)
    }

    @IBAction func doClose(_ sender: Any) {
        self.view.window?.orderOut(sender)
    }
    
    @IBAction func openSystemPreferences(_ sender: Any) {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.folders[row].path
    }
}

extension ViewController: NSTableViewDelegate {
    
}

