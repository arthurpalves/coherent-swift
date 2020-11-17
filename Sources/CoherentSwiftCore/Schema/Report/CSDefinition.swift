//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public enum CSDefinitionType: String, Codable {
    case Class
    case Struct
    case Enum
    case Extension
}

public struct CSDefinition: Codable {
    let name: String
    let type: CSDefinitionType
    var cohesion: String
    var properties: [CSProperty]
    var methods: [CSMethod]
    var contentString: String = ""
    
    init(name: String, type: CSDefinitionType = .Class,
         cohesion: String = "", properties: [CSProperty] = [], methods: [CSMethod] = []) {
        self.name = name
        self.type = type
        self.cohesion = cohesion
        self.properties = properties
        self.methods = methods
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, type, cohesion, properties, methods
    }
}
