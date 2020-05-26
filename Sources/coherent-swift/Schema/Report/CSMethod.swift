//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct CSMethod: Codable {
    let name: String
    var cohesion: String
    var contentString: String = ""
    var methodType: CSMethodType
    var properties: [CSProperty]
    
    init(name: String, cohesion: String = "", contentString: String = "",
         methodType: CSMethodType = .Public, properties: [CSProperty] = []) {
        self.name = name
        self.cohesion = cohesion
        self.contentString = contentString
        self.methodType = methodType
        self.properties = properties
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, cohesion, properties, methodType
    }
}
