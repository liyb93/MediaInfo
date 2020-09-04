//
//  FinderSync.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    let numberFormatter = NumberFormatter()
    let byteCountFormatter = ByteCountFormatter()
    
    override init() {
        super.init()
        
        let settings = Settings.shared
        
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        
        // Set up the directory we are syncing.
        
        NSLog("FinderSync() watching folders:\n %@", settings.folders.map({ $0.path }).joined(separator: "\n"))
        FIFinderSyncController.default().directoryURLs = Set(settings.folders)
        
        // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.colorPanelName)!, label: "Status One" , forBadgeIdentifier: "One")
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.cautionName)!, label: "Status Two", forBadgeIdentifier: "Two")
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleFolderChanged(_:)), name: NSNotification.Name(rawValue: "MediaInfoMonitoredFolderChanged"), object: nil)
    }
    
    @objc func handleFolderChanged(_ notification: Notification) {
        let settings = Settings.shared
        settings.refresh()
        
        NSLog("FinderSync() watching folders:\n %@", settings.folders.map({$0.path}).joined(separator: "\n"))
        FIFinderSyncController.default().directoryURLs = Set(settings.folders)
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    
    override func endObservingDirectory(at url: URL) {
        // The user is no longer seeing the container's contents.
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    /*
    override func requestBadgeIdentifier(for url: URL) {
        NSLog("requestBadgeIdentifierForURL: %@", url.path as NSString)
        
        // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
        let whichBadge = abs(url.path.hash) % 3
        let badgeIdentifier = ["", "One", "Two"][whichBadge]
        FIFinderSyncController.default().setBadgeIdentifier(badgeIdentifier, for: url)
    }
    */
    
    // MARK: - Menu and toolbar item support
    
    /*
    override var toolbarItemName: String {
        return "FinderSy"
    }
    
    override var toolbarItemToolTip: String {
        return "FinderSy: Click the toolbar item for a menu."
    }
    
    override var toolbarItemImage: NSImage {
        return NSImage(named: NSImage.cautionName)!
    }
    */
    
    func formatTime(_ time: TimeInterval) -> String {
        var m = Int(time / 60)
        let h = Int(TimeInterval(m) / 60)
        m -= h * 60
        let s = Int(time) - (m * 60) - (h * 3600)
        // let ms = time - TimeInterval(s + m * 60 + h * 3600)
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        if menuKind == .contextualMenuForItems {
            let settings = Settings.shared
            
            if let items = FIFinderSyncController.default().selectedItemURLs(), items.count == 1, let item = items.first, let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                                
                if settings.isImagesHandled && UTTypeConformsTo(uti as CFString, kUTTypeImage), let menu = getMenuForImage(atURL: item) {
                    return menu
                } else if settings.isMediaHandled && UTTypeConformsTo(uti as CFString, kUTTypeMovie), let menu = getMenuForVideo(atURL: item) {
                    return menu
                } else if settings.isMediaHandled && UTTypeConformsTo(uti as CFString, kUTTypeAudio), let menu = getMenuForAudio(atURL: item) {
                    return menu
                }
            }
        }
        
        // // Produce a menu for the extension.
        // menu.addItem(withTitle: "Example Menu Item", action: #selector(sampleAction(_:)), keyEquivalent: "")
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        return menu
    }
    
    func getMenuForImage(atURL item: URL) -> NSMenu? {
        let image_info: ImageInfo
        if let info = getCGImageInfo(forFile: item) {
            image_info = info
        } else {
            guard let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
                return nil
            }
            
            if UTTypeConformsTo(uti as CFString, "public.pbm" as CFString), let info = getNetPBMImageInfo(forFile: item) {
                image_info = info
            } else if UTTypeConformsTo(uti as CFString, "public.webp" as CFString), let info = getWebPImageInfo(forFile: item) {
                image_info = info
            } else if UTTypeConformsTo(uti as CFString, "fr.whine.bpg" as CFString) || item.pathExtension == "bpg", let info = getBPGImageInfo(forFile: item) {
                image_info = info
            } else if UTTypeConformsTo(uti as CFString, "public.svg-image" as CFString), let info = getSVGImageInfo(forFile: item) {
                image_info = info
            } else if let info = getFFMpegImageInfo(forFile: item) {
                image_info = info
            } else if let info = getMetadataImageInfo(forFile: item) {
                image_info = info
            } else {
                return nil
            }
        }
        
        guard image_info.width > 0 || image_info.height > 0 else {
            return nil
        }
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let settings = Settings.shared
        settings.refresh()
        
        let use_submenu  = settings.isImageInfoOnSubMenu
        let icon_hidden  = settings.isImageIconsHidden
        let print_hidden = settings.isPrintHidden
        
        // FIXME: NSImage named with a pdf image don't respect dark theme!
        // FIXME: The image set for a NSMenuItem in the extension do not preserve the template rendering mode.
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "Media info", action: #selector(sampleAction(_:)), keyEquivalent: "")
            info_mnu.image = NSImage(named: type == "Dark" ? "image_w" : "image")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        var colors: [String] = []
        if !settings.isColorHidden && !image_info.colorMode.isEmpty {
            colors.append(image_info.colorMode)
        }
        if !settings.isDepthHidden && image_info.depth > 0 {
            colors.append("\(image_info.depth) bit")
        }
        
        var title = "\(image_info.width) × \(image_info.height) px"
        
        if !use_submenu && !colors.isEmpty {
            title += " " + colors.joined(separator: " ")
        }
        if print_hidden && image_info.dpi > 0 {
            title += " (\(image_info.dpi) dpi)"
        }
        let mnu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mnu.image = icon_hidden ? nil : NSImage(named: type == "Dark" ? "image_w" : "image")
        mnu.isEnabled = false
        (use_submenu ? info_sub_menu : menu).addItem(mnu)
        
        if use_submenu && !colors.isEmpty {
            let mnu = info_sub_menu.addItem(withTitle: colors.joined(separator: " "), action: nil, keyEquivalent: "")
            mnu.isEnabled = false
            mnu.image = icon_hidden ? nil : NSImage(named: type == "Dark" ? "color_w" : "color")
        }
        
        let unit = settings.unit
        
        let scale: Double
        let unit_label: String
        switch unit {
        case .cm:
            scale = 2.54 // cm
            unit_label = NSLocalizedString(" cm", comment: "")
        case .mm:
            scale = 25.4 // mm
            unit_label = NSLocalizedString(" mm", comment: "")
        case .inch:
            scale = 1 // inch
            unit_label = NSLocalizedString(" inch", comment: "")
        }
        
        if !print_hidden && image_info.dpi != 0, let w_cm = numberFormatter.string(from: NSNumber(value: Double(image_info.width) / Double(image_info.dpi) * scale)), let h_cm = numberFormatter.string(from: NSNumber(value: Double(image_info.height) / Double(image_info.dpi) * scale)) {
            
            let mnu = NSMenuItem(title: "\(w_cm) × \(h_cm)\(unit_label) (\(image_info.dpi) dpi)", action: nil, keyEquivalent: "")
            mnu.image = icon_hidden ? nil : NSImage(named: type == "Dark" ? "print_w" : "print")
            mnu.isEnabled = false
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        
        if !settings.isCustomPrintHidden, settings.customDPI > 0 && (image_info.dpi != settings.customDPI || print_hidden), let w_cm = numberFormatter.string(from: NSNumber(value:Double(image_info.width) / Double(settings.customDPI) * scale)), let h_cm = numberFormatter.string(from: NSNumber(value:Double(image_info.height) / Double(settings.customDPI) * scale)) {
            let mnu = NSMenuItem(title: "\(w_cm) × \(h_cm)\(unit_label) (\(settings.customDPI) dpi)", action: nil, keyEquivalent: "")
            mnu.image = icon_hidden ? nil : NSImage(named: type == "Dark" ? "print_w" : "print")
            mnu.isEnabled = false
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        return menu
    }
    
    func getMenuForVideo(atURL item: URL) -> NSMenu? {
        var streams: [StreamType] = getCMVideoInfo(forFile: item)
        if streams.isEmpty {
            streams = getFFMpegInfo(forFile: item)
        }
        if streams.isEmpty {
            streams = getMetadataVideoInfo(forFile: item)
        }
        guard !streams.isEmpty else {
            return nil
        }
        
        let settings = Settings.shared
        settings.refresh()
        
        let use_submenu   = settings.isMediaInfoOnSubMenu
        let group_tracks  = settings.isTracksGrouped
        let codec_hidden  = settings.isCodecHidden
        let frames_hidden = settings.isFramesHidden
        let bps_hidden    = settings.isBPSHidden
        let icon_hidden   = settings.isMediaIconsHidden
        
        // FIXME: NSImage named with a pdf image don't respect dark theme!
        // FIXME: The image set for a NSMenuItem in the extension do not preserve the template rendering mode.
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "Media info", action: nil, keyEquivalent: "")
            info_mnu.image = NSImage(named: type == "Dark" ? "video_w" : "video")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        
        let mnu_video = NSMenu(title: "Video")
        let mnu_audio = NSMenu(title: "Audio")
        let mnu_text  = NSMenu(title: "Subtitle")
        
        for stream in streams {
            switch stream {
            case .video(let width, let height, let duration, let codec, _, let lang, let bit_rate, let frames):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(width) × \(height), \(t)"
                if frames > 0 && !frames_hidden {
                    title += " (\(frames) frames)"
                }
                if bit_rate > 0 && !bps_hidden {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                let mnu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                mnu.isEnabled = false
                mnu.image = (group_tracks || icon_hidden) ? nil : NSImage(named: type == "Dark" ? "video_w" : "video")
                (group_tracks ? mnu_video : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                
            case .audio(let duration, let codec, let lang, let bit_rate):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(t)"
                if !bps_hidden && bit_rate > 0 {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                
                let mnu = NSMenuItem(title:title, action: nil, keyEquivalent: "")
                mnu.isEnabled = false
                
                mnu.image = (group_tracks || icon_hidden) ? nil : NSImage(named: type == "Dark" ? "audio_w" : "audio")
                
                (group_tracks ? mnu_audio : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                
            case .subtitle(let t, let lang):
                var title = ""
                if let t = t {
                    title += t
                }
                if let lang = lang, !lang.isEmpty {
                    title += title.isEmpty ? "(\(lang.uppercased()))" : " " + lang.uppercased()
                }
                if !title.isEmpty {
                    let mnu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                    mnu.isEnabled = false
                    mnu.image = (group_tracks || icon_hidden) ? nil : NSImage(named: type == "Dark" ? "txt_w" : "txt")
                                           
                    (group_tracks ? mnu_text : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                }
                break
            default:
                break
            }
        }
        if mnu_video.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Video", comment: ""), action: nil, keyEquivalent: "")
            m.image = NSImage(named: type == "Dark" ? "video_w" : "video")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_video, for: m)
        }
        if mnu_audio.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Audio", comment: ""), action: nil, keyEquivalent: "")
            m.image = NSImage(named: type == "Dark" ? "audio_w" : "audio")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_audio, for: m)
        }
        if mnu_text.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Subtitle", comment: ""), action: nil, keyEquivalent: "")
            m.image = NSImage(named: type == "Dark" ? "txt_w" : "txt")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_text, for: m)
        }
        
        return menu
    }
    
    func getMenuForAudio(atURL item: URL) -> NSMenu? {
        var streams: [StreamType] = getCMVideoInfo(forFile: item)
        if streams.isEmpty {
            streams = getFFMpegInfo(forFile: item)
        }
        if streams.isEmpty {
            streams = getMetadataVideoInfo(forFile: item)
        }
        guard !streams.isEmpty else {
            return nil
        }
        
        let settings = Settings.shared
        settings.refresh()
        
        let use_submenu   = settings.isMediaInfoOnSubMenu
        let codec_hidden  = settings.isCodecHidden
        let bps_hidden    = settings.isBPSHidden
        let icon_hidden   = settings.isMediaIconsHidden
        
        // FIXME: NSImage named with a pdf image don't respect dark theme!
        // FIXME: The image set for a NSMenuItem in the extension do not preserve the template rendering mode.
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "Media info", action: nil, keyEquivalent: "")
            info_mnu.image = NSImage(named: type == "Dark" ? "audio_w" : "audio")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        
        for stream in streams {
            switch stream {
            case .audio(let duration, let codec, let lang, let bit_rate):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(t)"
                if !bps_hidden && bit_rate > 0 {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                
                let mnu = NSMenuItem(title:title, action: nil, keyEquivalent: "")
                mnu.isEnabled = false
                mnu.image = icon_hidden ? nil : NSImage(named: type == "Dark" ? "audio_w" : "audio")
                (use_submenu ? info_sub_menu : menu).addItem(mnu)
            default:
                break
            }
        }
        
        return menu
    }
    
    @IBAction func sampleAction(_ sender: AnyObject?) {
        /*
        let target = FIFinderSyncController.default().targetedURL()
        let items = FIFinderSyncController.default().selectedItemURLs()
        
        let item = sender as! NSMenuItem
        NSLog("sampleAction: menu item: %@, target = %@, items = ", item.title as NSString, target!.path as NSString)
        for obj in items! {
            NSLog("    %@", obj.path as NSString)
        }
        */
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
