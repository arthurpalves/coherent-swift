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
    var badge_file: String { get set }
    var reports_path: String { get set }
    
    func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportDefinition], to report: ReportOutput) -> ReportOutput
    func generateReport(_ report: ReportOutput) -> (Bool, Path?)
    func generateBadge(_ report: ReportOutput) -> (Bool, Path?)
}

extension ReportGenerator {
    public var reports_file: String { "coherent-swift.json" }
    var badge_file: String { "coherent-badge.json" }
    var reports_path: String { "/tmp/coherent-swift/" }
    
    public func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportDefinition], to report: ReportOutput) -> ReportOutput {
        let cohesionReport = CohesionReport(file: file, cohesion: cohesion, meets_threshold: meetsThreshold, classes: definitions)
        var reportCopy = report
        reportCopy.appendReport(cohesionReport)
        return reportCopy
    }
    
    public func generateReport(_ report: ReportOutput) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(reports_file)")
        
        var reportCopy = report
        reportCopy.report_date = Date().logTimestamp()
        
        do {
            try Task.run(bash: "mkdir -p \(reports_path)")
            let _ = generateBadge(reportCopy)
            return write(reportCopy, toFile: path)
        } catch {
            return (false, nil)
        }

    }
    
    public func generateBadge(_ report: ReportOutput) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(badge_file)")
        let coherentBadge = CoherentBadge(schemaVersion: 1, label: "cohesion", message: report.cohesion, color: "blue")
        return write(coherentBadge, toFile: path)
    }
    
    private func write<T>(_ encodableObject: T, toFile file: Path) -> (Bool, Path?) where T : Encodable {
        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            try Task.run(bash: "touch \(file.absolute().description)")
            
            let encoded = try encoder.encode(encodableObject)
            guard let encodedJSONString = String(data: encoded, encoding: .utf8) else { return (false, nil) }
            try encodedJSONString.write(toFile: file.absolute().description, atomically: true, encoding: .utf8)
            
            return (true, file)
            
        } catch {
            return (false, nil)
        }
    }
}
