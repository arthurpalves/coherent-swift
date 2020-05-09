//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation
import SwiftCLI
import PathKit

public protocol ReportGenerator {
    var reports_file: String { get }
    var reports_path: String { get set }
    
    func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportClass], to report: ReportOutput) -> ReportOutput
    func generateReport(_ report: ReportOutput) -> (Bool, Path?)
}

extension ReportGenerator {
    public var reports_file: String { "coherent-swift.json" }
    var reports_path: String { "/tmp/coherent-swift/" }
    
    public func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportClass], to report: ReportOutput) -> ReportOutput {
        let individualReport = IndividualReport(file: file, cohesion: cohesion, meets_threshold: meetsThreshold, classes: definitions)
        var reportCopy = report
        reportCopy.appendReport(individualReport)
        return reportCopy
    }
    
    public func generateReport(_ report: ReportOutput) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(reports_file)")
        
        var reportCopy = report
        reportCopy.report_date = currentTimestamp()

        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            try Task.run(bash: "mkdir -p \(reports_path)")
            try Task.run(bash: "touch \(path.absolute().description)")
            
            let encoded = try encoder.encode(reportCopy)
            guard let encodedJSONString = String(data: encoded, encoding: .utf8) else { return (false, nil) }
            try encodedJSONString.write(toFile: path.absolute().description, atomically: true, encoding: .utf8)
            
            return (true, path)
        } catch {
            return (false, nil)
        }
    }
    
    private func currentTimestamp() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
