//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public enum DefinitionType: String, Codable {
    case Class
    case Struct
    case Enum
    case Extension
}

public struct ReportDefinition: Codable {
    let name: String
    let type: DefinitionType
    var cohesion: String
    var properties: [ReportProperty]
    var methods: [ReportMethod]
    var contentString: String = ""
    
    init(name: String, type: DefinitionType = .Class,
         cohesion: String = "", properties: [ReportProperty] = [], methods: [ReportMethod] = []) {
        self.name = name
        self.type = type
        self.cohesion = cohesion
        self.properties = properties
        self.methods = methods
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, cohesion, properties, methods
    }
}
