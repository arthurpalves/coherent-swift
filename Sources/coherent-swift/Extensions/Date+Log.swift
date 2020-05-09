//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

extension Date {
    func logTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
