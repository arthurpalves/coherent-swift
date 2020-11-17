//
//  coherent-swift
//
//  Created by Arthur Alves on 12/05/2020.
//

import Foundation

public struct CSBadge: Codable {
    let schemaVersion: Int
    let label: String
    let message: String
    let color: String
}
