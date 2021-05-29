//
//  MediaInfoHelperXPC.swift
//  MediaInfoHelperXPC
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

class MediaInfoHelperXPC: MediaInfoSettingsXPC, MediaInfoHelperXPCProtocol {
    func getInfo(for item: URL, type: String, withReply reply: @escaping (NSData?)->Void) {
        switch type {
        case "image":
            getImageInfo(for: item, withReply: reply)
        case "video":
            getVideoInfo(for: item, withReply: reply)
        case "audio":
            getAudioInfo(for: item, withReply: reply)
        
        case "pdf":
            getPDFInfo(for: item, withReply: reply)
        
        case "doc":
            getWordInfo(for: item, withReply: reply)
        case "xls":
            getExcelInfo(for: item, withReply: reply)
        case "ppt":
            getPowerpointInfo(for: item, withReply: reply)
        
        case "odt":
            getOpenDocumentInfo(for: item, withReply: reply)
        case "ods":
            getOpenSpreadsheetInfo(for: item, withReply: reply)
        case "odp":
            getOpenPresentationInfo(for: item, withReply: reply)
        default:
            reply(nil)
        }
    }
    
    func getImageInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let image_info: ImageInfo
        if let info = getCGImageInfo(forFile: item) {
            image_info = info
        } else {
            guard let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
                reply(nil)
                return
            }
            if UTTypeConformsTo(uti as CFString, "public.pbm" as CFString), let info = getNetPBMImageInfo(forFile: item) {
                image_info = info
            } else if UTTypeConformsTo(uti as CFString, "public.webp" as CFString), let info = getWebPImageInfo(forFile: item) {
                image_info = info
            } /*else if UTTypeConformsTo(uti as CFString, "fr.whine.bpg" as CFString) || item.pathExtension == "bpg", let info = getBPGImageInfo(forFile: item) {
                image_info = info
            } */else if UTTypeConformsTo(uti as CFString, "public.svg-image" as CFString), let info = getSVGImageInfo(forFile: item) {
                image_info = info
            } else if let info = getFFMpegImageInfo(forFile: item) {
                image_info = info
            } else if let info = getMetadataImageInfo(forFile: item) {
                image_info = info
            } else {
                reply(nil)
                return
            }
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        image_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getVideoInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
    
        var video: VideoInfo?
        for engine in settings.engines {
            switch engine {
            case .coremedia:
                if let v = getCMVideoInfo(forFile: item) {
                    video = v
                }
            case .ffmpeg:
                /*
                if let v = getFFMpegVideoInfo(forFile: item) {
                    video = v
                }*/ break
            case .metadata:
                /*if let v = getMetadataVideoInfo(forFile: item) {
                    video = v
                }*/ break
            }
            if video != nil {
                break
            }
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        video?.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getAudioInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        
        var audio: AudioInfo?
        for engine in settings.engines {
            switch engine {
            case .coremedia:
                if let a = getCMAudioInfo(forFile: item) {
                    audio = a
                }
            case .ffmpeg:
                /*
                if let a = getFFMpegAudioInfo(forFile: item) {
                    audio = a
                }*/
            break
            case .metadata:
                /*
                if let a = getMetadataAudioInfo(forFile: item) {
                    audio = a
                }*/
                break
            }
            if audio != nil {
                break
            }
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        audio?.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getPDFInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        guard let pdf = CGPDFDocument(item as CFURL) else {
            reply(nil)
            return
        }
        let pdf_info = PDFInfo(file: item, pdf: pdf)
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        pdf_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getWordInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let doc_info = WordInfo(docx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        doc_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getExcelInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let xls_info = ExcelInfo(xlsx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        xls_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getPowerpointInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let xppt_info = PowerpointInfo(pptx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        xppt_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getOpenDocumentInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let odt_info = WordInfo(odt: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        odt_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getOpenSpreadsheetInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let ods_info = ExcelInfo(ods: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        ods_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
    
    func getOpenPresentationInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let odp_info = PowerpointInfo(odp: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        odp_info.encode(with: coder)
        reply(coder.encodedData as NSData)
    }
}