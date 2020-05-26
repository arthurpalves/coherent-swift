//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct CSProperty: Codable {
    let keyword: String
    let name: String
    let propertyType: CSPropertyType
    
    init(keyword: String = "", name: String, propertyType: CSPropertyType) {
        self.keyword = keyword
        self.name = name
        self.propertyType = propertyType
    }
}
