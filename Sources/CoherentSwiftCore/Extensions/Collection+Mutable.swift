//
//  coherent-swift
//
//  Created by Arthur Alves on 26/05/2020.
//

import Foundation

extension MutableCollection {
    mutating func mutateEach(_ body: (inout Element) throws -> Void) rethrows {
        for index in self.indices {
            try body(&self[index])
        }
    }
}
