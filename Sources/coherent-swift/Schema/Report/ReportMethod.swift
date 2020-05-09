//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct ReportMethod: Codable {
    let name: String
    var cohesion: String
    var properties: [ReportProperty]
    
    init(name: String, cohesion: String = "", properties: [ReportProperty] = []) {
        self.name = name
        self.cohesion = cohesion
        self.properties = properties
    }
}
