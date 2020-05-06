//
//  coherent-swift
//
//  Created by Arthur Alves on 05/05/2020.
//

import Foundation
import PathKit

public struct Configuration: Codable {
    let source: String
    let minimum_threshold: String
    let reports_folder: String
    
    func threshold() -> Double? {
        return Double(input: minimum_threshold)
    }
    
    func sourcePath() -> Path {
        return Path(source)
    }
    
    func reportsPath() -> Path {
        return Path(reports_folder)
    }
}
