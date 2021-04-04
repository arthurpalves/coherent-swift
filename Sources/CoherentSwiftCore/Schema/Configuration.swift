//
//  CoherentSwift
//

import Foundation
import PathKit

public struct Configuration: Codable {
    let sources: [String]
    let minimum_threshold: String
    let reports_folder: String
    let ignore_output_result: Bool
    let report_format: ReportFormat?
    
    public func threshold() -> Double? {
        return Double(minimum_threshold)
    }
    
    func sourcePaths() -> [Path] {
        return sources.map { Path($0) }
    }
    
    func reportsPath() -> Path {
        return Path(reports_folder)
    }
    
    public enum ReportFormat: String, Codable {
        case json
        case plain
    }
}
