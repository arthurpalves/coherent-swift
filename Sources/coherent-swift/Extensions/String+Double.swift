//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation

extension String {
    var double: Double {
        guard let doubleValue = Double(input: self) else { return 0.0 }
        return doubleValue
    }
}
