//
//  CoherentSwift
//

import Foundation

extension String {
    var double: Double {
        guard let doubleValue = Double(self) else { return 0.0 }
        return doubleValue
    }
}
