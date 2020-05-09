//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct ReportMethod: Codable {
    let name: String
    var cohesion: String
    var contentString: String = ""
    var properties: [ReportProperty]
    
    init(name: String, cohesion: String = "", contentString: String = "", properties: [ReportProperty] = []) {
        self.name = name
        self.cohesion = cohesion
        self.contentString = contentString
        self.properties = properties
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, cohesion, properties
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        cohesion = try container.decode(String.self, forKey: .cohesion)
        properties = try container.decode([ReportProperty].self, forKey: .properties)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(cohesion, forKey: .cohesion)
        try container.encode(properties, forKey: .properties)
    }
}
