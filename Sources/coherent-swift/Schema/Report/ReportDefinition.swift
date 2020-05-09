//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct ReportDefinition: Codable {
    let name: String
    var cohesion: String
    var properties: [ReportProperty]
    var methods: [ReportMethod]
    
    init(name: String, cohesion: String = "", properties: [ReportProperty] = [], methods: [ReportMethod] = []) {
        self.name = name
        self.cohesion = cohesion
        self.properties = properties
        self.methods = methods
    }
}
