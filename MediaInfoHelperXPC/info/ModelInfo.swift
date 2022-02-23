//
//  ModelInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class ModelInfo: BaseInfo, FileInfo {
    class SubMesh: Encodable {
        enum CodingKeys: String, CodingKey {
            case name
            case material
            case geometryType
        }
        let name: String
        let material: String?
        let geometryType: Int
        
        init(name: String, material: String?, geometryType: Int) {
            self.name = name
            self.material = material
            self.geometryType = geometryType
        }
        
        required init?(coder: NSCoder) {
            guard let s = coder.decodeObject(of: NSString.self, forKey: "name") as String? else {
                return nil
            }
            self.name = s
            self.material = coder.decodeObject(of: NSString.self, forKey: "material") as String?
            self.geometryType = coder.decodeInteger(forKey: "geometryType")
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(self.name as NSString, forKey: "name")
            coder.encode(self.material as NSString?, forKey: "material")
            coder.encode(self.geometryType, forKey: "geometryType")
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: .name)
            try container.encode(self.material, forKey: .material)
            try container.encode(self.geometryType, forKey: .geometryType)
        }
        
        var imageName: String {
            switch self.geometryType {
            case 0: return "3d_points"
            case 1: return "3d_lines"
            case 2: return "3d_triangle"
            case 3: return "3d_triangle_stripe"
            case 4: return "3d_quads"
            case 5: return "3d_variable" 
            default:
                return "3d"
            }
        }
    }
    
    class Mesh: Encodable {
        enum CodingKeys: String, CodingKey {
            case name
            case vertexCount
            
            case hasNormals
            case hasTangent
            case hasTextureCoordinate
            case hasVertexColor
            case hasOcclusion
            case meshes
        }
        
        let name: String
        let vertexCount: Int
        
        let hasNormals: Bool
        let hasTangent: Bool
        let hasTextureCoordinate: Bool
        let hasVertexColor: Bool
        let hasOcclusion: Bool
        
        var meshes: [SubMesh] = []
        
        init(name: String, vertexCount: Int, hasNormals: Bool, hasTangent: Bool, hasTextureCoordinate: Bool, hasVertexColor: Bool, hasOcclusion: Bool) {
            self.name = name
            self.vertexCount = vertexCount
            self.hasNormals = hasNormals
            self.hasTangent = hasTangent
            self.hasTextureCoordinate = hasTextureCoordinate
            self.hasVertexColor = hasVertexColor
            self.hasOcclusion = hasOcclusion
        }
        
        required init?(coder: NSCoder) {
            guard let s = coder.decodeObject(of: NSString.self, forKey: "name") as String? else {
                return nil
            }
            self.name = s
            self.vertexCount = coder.decodeInteger(forKey: "vertexCount")
            self.hasNormals = coder.decodeBool(forKey: "hasNormals")
            self.hasTangent = coder.decodeBool(forKey: "hasTangent")
            self.hasTextureCoordinate = coder.decodeBool(forKey: "hasTextureCoordinate")
            self.hasVertexColor = coder.decodeBool(forKey: "hasVertexColor")
            self.hasOcclusion = coder.decodeBool(forKey: "hasOcclusion")
            
            self.meshes = []
            let n = coder.decodeInteger(forKey: "submeshesCount")
            for i in 0 ..< n {
                if let data = coder.decodeObject(of: NSData.self, forKey: "submesh_\(i)") as Data?, let c = try? NSKeyedUnarchiver(forReadingFrom: data) {
                    if let m = SubMesh(coder: c) {
                        meshes.append(m)
                    }
                    c.finishDecoding()
                }
            }
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(name, forKey: "name")
            
            coder.encode(vertexCount, forKey: "vertexCount")
            
            coder.encode(hasNormals, forKey: "hasNormals")
            coder.encode(hasTangent, forKey: "hasTangent")
            coder.encode(hasTextureCoordinate, forKey: "hasTextureCoordinate")
            coder.encode(hasVertexColor, forKey: "hasVertexColor")
            coder.encode(hasOcclusion, forKey: "hasOcclusion")
            
            coder.encode(self.meshes.count, forKey: "submeshesCount")
            for (i,m) in self.meshes.enumerated() {
                let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
                m.encode(with: c)
                coder.encode(c.encodedData, forKey: "submesh_\(i)")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: .name)
            try container.encode(self.vertexCount, forKey: .vertexCount)
            try container.encode(self.hasNormals, forKey: .hasNormals)
            try container.encode(self.hasTangent, forKey: .hasTangent)
            try container.encode(self.hasTextureCoordinate, forKey: .hasTextureCoordinate)
            try container.encode(self.hasVertexColor, forKey: .hasVertexColor)
            try container.encode(self.hasOcclusion, forKey: .hasOcclusion)
            try container.encode(self.meshes, forKey: .meshes)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case meshes
    }
    
    let file: URL
    let fileSize: Int64
    
    var meshes: [Mesh]
    var vertexCount: Int {
        return meshes.reduce(0, { $0 + $1.vertexCount })
    }
    
    var hasNormals: Bool {
        return meshes.first(where: { $0.hasNormals }) != nil
    }
    var hasTangent: Bool {
        return meshes.first(where: { $0.hasTangent }) != nil
    }
    var hasTextureCoordinate: Bool {
        return meshes.first(where: { $0.hasTextureCoordinate }) != nil
    }
    var hasVertexColor: Bool {
        return meshes.first(where: { $0.hasVertexColor }) != nil
    }
    var hasOcclusion: Bool {
        return meshes.first(where: { $0.hasOcclusion }) != nil
    }
    
    init(file: URL, meshes: [Mesh]) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        self.meshes = meshes
        super.init()
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.meshes = []
        let n = coder.decodeInteger(forKey: "meshCount")
        for i in 0 ..< n {
            if let data = coder.decodeObject(of: NSData.self, forKey: "mesh_\(i)") as Data?, let c = try? NSKeyedUnarchiver(forReadingFrom: data) {
                if let m = Mesh(coder: c) {
                    self.meshes.append(m)
                }
                c.finishDecoding()
            }
        }
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.meshes.count, forKey: "meshCount")
        for (i, m) in self.meshes.enumerated() {
            let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            m.encode(with: c)
            coder.encode(c.encodedData, forKey: "mesh_\(i)")
        }
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.meshes, forKey: .meshes)
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.modelsMenuItems, image: self.getImage(for: "3d"), withSettings: settings)
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[mesh]], [[vertex]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        switch placeholder {
            
        case "[[mesh-count]]":
            let n = self.meshes.count
            isFilled = n > 0
            if n == 0 && !useEmptyData {
                return ""
            }
            if n == 1 {
                return NSLocalizedString("1 Mesh", tableName: "LocalizableExt", comment: "")
            } else {
                return String(format: NSLocalizedString("%d Meshes", tableName: "LocalizableExt", comment: ""), n)
            }
        case "[[vertex]]":
            isFilled = self.vertexCount > 0
            if self.vertexCount == 0 && !useEmptyData {
                return ""
            }
            return String(format: NSLocalizedString("%@ Vertices", tableName: "LocalizableExt", comment: ""), Self.numberFormatter.string(from: NSNumber(value: self.vertexCount)) ?? "\(self.vertexCount)")
        case "[[normals]]":
            isFilled = self.hasNormals
            return NSLocalizedString(self.hasNormals ? "with normals" : "without normals", tableName: "LocalizableExt", comment: "")
        case "[[tangents]]":
            isFilled = self.hasTangent
            return NSLocalizedString(self.hasTangent ? "with tangents" : "without tangents", tableName: "LocalizableExt", comment: "")
        case "[[tex-coords]]":
            isFilled = self.hasTextureCoordinate
            return NSLocalizedString(self.hasTextureCoordinate ? "with texture coordinates" : "without texture coordinates", tableName: "LocalizableExt", comment: "")
        case "[[vertex-color]]":
            isFilled = self.hasVertexColor
            return NSLocalizedString(self.hasVertexColor ? "with vertex colors" : "without vertex colors", tableName: "LocalizableExt", comment: "")
        case "[[occlusion]]":
            isFilled = self.hasOcclusion
            return NSLocalizedString(self.hasOcclusion ? "with occlusion" : "without occlusion", tableName: "LocalizableExt", comment: "")
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "[[meshes]]" {
            guard !self.meshes.isEmpty else {
                return true
            }
            let n = self.meshes.count
            let title = n == 1 ? NSLocalizedString("1 Mesh", tableName: "LocalizableExt", comment: "") : String(format: NSLocalizedString("%d Meshes", comment: ""), n)
            let mnu = self.createMenuItem(title: title, image: "3D", settings: settings)
            let submenu = NSMenu(title: title)
            for mesh in self.meshes {
                let mesh_menu = n > 1 ? NSMenu() : submenu
                
                let m = createMenuItem(title: mesh.name.isEmpty ? mesh.name : "Mesh", image: mesh.meshes.first?.imageName, settings: settings)
                submenu.addItem(m)
                
                let t = String(format: NSLocalizedString("%@ Vertices", tableName: "LocalizableExt", comment: ""), Self.numberFormatter.string(from: NSNumber(value: mesh.vertexCount)) ?? "\(mesh.vertexCount)")
                mesh_menu.addItem(createMenuItem(title: t, image: nil, settings: settings))
                mesh_menu.addItem(NSMenuItem.separator())
                if mesh.hasNormals {
                    mesh_menu.addItem(createMenuItem(title: "with normals", image: "3d_normal", settings: settings))
                }
                if mesh.hasTangent {
                    mesh_menu.addItem(createMenuItem(title: "with tangents", image: "3d_tangent", settings: settings))
                }
                if mesh.hasVertexColor {
                    mesh_menu.addItem(createMenuItem(title: "with vertex colors", image: "3d_color", settings: settings))
                }
                if mesh.hasTextureCoordinate {
                    mesh_menu.addItem(createMenuItem(title: "with texture coordinates", image: "3d_uv", settings: settings))
                }
                if mesh.hasOcclusion {
                    mesh_menu.addItem(createMenuItem(title: "with occlusion", image: "3d_occlusion", settings: settings))
                }
                
                if n > 1 {
                    submenu.setSubmenu(mesh_menu, for: m)
                }
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
