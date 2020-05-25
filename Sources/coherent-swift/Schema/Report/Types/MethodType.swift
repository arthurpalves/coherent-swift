//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation

public enum MethodType: String, Codable {
    case privateMethod = "private"
    case staticMethod = "static"
    case publicMethod = "public"
    case internalMethod = "internal"
}
