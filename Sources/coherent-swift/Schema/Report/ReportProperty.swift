//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct ReportProperty: Codable {
    let keyword: String
    let name: String
    let propertyType: PropertyType
    
    init(keyword: String = "", name: String, propertyType: PropertyType) {
        self.keyword = keyword
        self.name = name
        self.propertyType = propertyType
    }
}
