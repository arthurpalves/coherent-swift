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
    
    func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [CSDefinition], to report: CSReport) -> CSReport
    func generateReport(_ report: CSReport, format: ReportFormat) -> (Bool, Path?)
    func generateBadge(_ report: CSReport) -> (Bool, Path?)
}

extension ReportGenerator {
    public var fileOutput: FileOutput { FileOutput() }
    public var reports_file: String { "coherent-swift" }
    var badge_file: String { "coherent-badge.json" }
    var reports_path: String { "/tmp/coherent-swift/" }
    
    public func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [CSDefinition], to report: CSReport) -> CSReport {
        let fileReport = CSFileReport(filename: file, cohesion: cohesion, meets_threshold: meetsThreshold, definitions: definitions)
        var overallReportCopy = report
        overallReportCopy.appendReport(fileReport)
        return overallReportCopy
    }
    
    public func generateReport(_ report: CSReport, format: ReportFormat = .json) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(reports_file).\(format.rawValue)")
        
        var overallReportCopy = report
        overallReportCopy.report_date = Date().logTimestamp()
        
        do {
            try Task.run(bash: "mkdir -p \(reports_path)")
            let _ = generateBadge(overallReportCopy)
            return fileOutput.write(overallReportCopy, toFile: path, format: format)
        } catch {
            return (false, nil)
        }
    }
    
    public func generateBadge(_ report: CSReport) -> (Bool, Path?) {
        let path = Path("\(reports_path)/\(badge_file)")
        let coherentBadge = CoherentBadge(schemaVersion: 1, label: "cohesion", message: report.cohesion, color: "blue")
        return fileOutput.write(coherentBadge, toFile: path)
    }
}
