//
//  CoherentSwift
//

import Foundation
import PathKit

public protocol ReportFactory {
    var fileOutput: FileOutput { get }
    var reportsFileName: String { get }
    var badgeFilePath: Path { get set }
    var reportsPath: Path { get set }
    
    func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [CSDefinition], to report: CSReport) -> CSReport
    func generateReport(_ report: CSReport, format: Configuration.ReportFormat) -> (Bool, Path?)
    func generateBadge(_ report: CSReport) -> (Bool, Path?)
}

extension ReportFactory {
    public var fileOutput: FileOutput { FileOutput() }
    public var reportsFileName: String { "coherent-swift" }
    var badgeFilePath: Path { Path("coherent-badge.json") }
    var reportsPath: Path { Path("/tmp/coherent-swift/") }
    
    public func addToReport(file: String, cohesion: String, meetsThreshold: Bool, definitions: [CSDefinition], to report: CSReport) -> CSReport {
        let fileReport = CSFileReport(filename: file, cohesion: cohesion, meets_threshold: meetsThreshold, definitions: definitions)
        var overallReportCopy = report
        overallReportCopy.appendReport(fileReport)
        return overallReportCopy
    }
    
    public func generateReport(_ report: CSReport, format: Configuration.ReportFormat = .json) -> (Bool, Path?) {
        do {
            if !reportsPath.isDirectory {
                try reportsPath.mkpath()
            }
            
            let path = try reportsPath.safeJoin(path: Path("\(reportsFileName).\(format.rawValue)"))
            
            var overallReportCopy = report
            overallReportCopy.report_date = Date().logTimestamp()
            let _ = generateBadge(overallReportCopy)
            
            return fileOutput.write(overallReportCopy, toFile: path, format: format)
        } catch {
            return (false, nil)
        }
    }
    
    public func generateBadge(_ report: CSReport) -> (Bool, Path?) {
        guard let path = try? reportsPath.safeJoin(path: badgeFilePath) else { return (false, nil) }
        let badge = CSBadge(schemaVersion: 1, label: "cohesion", message: report.cohesion, color: "blue")
        return fileOutput.write(badge, toFile: path)
    }
}
