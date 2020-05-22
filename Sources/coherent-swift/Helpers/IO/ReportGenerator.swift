//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation
import SwiftCLI
import PathKit

public enum ReportFormat: String {
    case json = "json"
    case plain = "plain"
}

public protocol ReportGenerator {
    var fileOutput: FileOutput { get }
    var reports_file: String { get }
    var badge_file: String { get set }
    var reports_path: String { get set }
    
    func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportDefinition], to report: ReportOutput) -> ReportOutput
    func generateReport(_ report: ReportOutput, format: ReportFormat) -> (Bool, Path?)
    func generateBadge(_ report: ReportOutput) -> (Bool, Path?)
}

extension ReportGenerator {
    public var fileOutput: FileOutput { FileOutput() }
    public var reports_file: String { "coherent-swift" }
    var badge_file: String { "coherent-badge.json" }
    var reports_path: String { "/tmp/coherent-swift/" }
    
    public func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [ReportDefinition], to report: ReportOutput) -> ReportOutput {
        let cohesionReport = CohesionReport(file: file, cohesion: cohesion, meets_threshold: meetsThreshold, classes: definitions)
        var reportCopy = report
        reportCopy.appendReport(cohesionReport)
        return reportCopy
    }
    
    public func generateReport(_ report: ReportOutput, format: ReportFormat = .json) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(reports_file).\(format.rawValue)")
        
        var reportCopy = report
        reportCopy.report_date = Date().logTimestamp()
        
        do {
            try Task.run(bash: "mkdir -p \(reports_path)")
            let _ = generateBadge(reportCopy)
            return fileOutput.write(reportCopy, toFile: path, format: format)
        } catch {
            return (false, nil)
        }

    }
    
    public func generateBadge(_ report: ReportOutput) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(badge_file)")
        let coherentBadge = CoherentBadge(schemaVersion: 1, label: "cohesion", message: report.cohesion, color: "blue")
        return fileOutput.write(coherentBadge, toFile: path)
    }
}
