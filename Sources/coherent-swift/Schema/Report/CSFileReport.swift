//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public struct CSFileReport: Codable {
    let filename: String
    let cohesion: String
    let meets_threshold: Bool
    let definitions: [CSDefinition]?
}
