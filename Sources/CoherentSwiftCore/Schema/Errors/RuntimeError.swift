//
//  CoherentSwift
//

import Foundation

public struct RuntimeError: Error, CustomStringConvertible {
    public var description: String
    
    init(_ description: String) {
        self.description = "❌ "+description
    }
}
