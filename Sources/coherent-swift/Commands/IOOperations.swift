//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

typealias FinalCohesion = (overall: Double, accumulative: Double, fileCount: Int)
typealias StepCohesionHandler = (String, Double, [ReportClass]) -> Void

public enum ParseType: String {
    case definition = "Definition"
    case method = "Method"
    case property = "Property"
    
    func regex() -> String {
        switch self {
        case .definition:
            return "class|struct"
        case .method:
            return "func"
        case .property:
            return "(var|let)"
        }
    }
    
    func delimiter() -> String {
        switch self {
        case .definition:
            return "?=:"
        case .method:
            return "?=\\{"
        case .property:
            return "( |:)"//(\\=|:)"
        }
    }
}

public protocol IOOperations {
    var logger: Logger { get }
    var swiftParser: SwiftParser { get }
    var localFileManager: LocalFileManager { get }
    var defaultThreshold: Double { get set }
    
    func readSpecs(configuration: Configuration, configurationPath: Path, threshold: Double) throws
}

extension IOOperations {
    var logger: Logger { Logger.shared }
    var swiftParser: SwiftParser { SwiftParser.shared }
    var localFileManager: LocalFileManager { LocalFileManager.shared }
    
    func readSpecs(configuration: Configuration, configurationPath: Path, threshold: Double) throws {
        let path = Path("\(configurationPath)/\(configuration.sourcePath().abbreviate())")
        guard path.absolute().exists else {
            throw CLI.Error(message: "Couldn't find source folder")
        }
        
        logger.logSection("Running Analysis", item: "")
        
        var accumulativeCohesion: Double = 0.0
        var fileAmount: Int = 0
        var report: ReportOutput = ReportOutput()
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: path.absolute().description)
        while let filename = enumerator?.nextObject() as? String {
            if filename.hasSuffix(".swift") {
                processFile(filename: filename, in: path) { (filename, cohesion, definitions) in
                    let cohesionString = String(format: "%.2f", cohesion)
                    
                    report = localFileManager.addToReport(file: filename, cohesion: cohesionString+"%", meetsThreshold: cohesionString.double >= threshold, definitions: definitions, to: report)
                    
                    accumulativeCohesion += cohesion
                    fileAmount += 1
                }
            }
        }
        
        processOverallCohesion(configuration: configuration,
                               finalCohesion: (0, accumulativeCohesion, fileAmount),
                               threshold: threshold,
                               report: report) { (finalReport) in
                                
                                let reportsFolder = Path("\(configurationPath)/\(configuration.reportsPath().abbreviate())")
                                self.localFileManager.reports_path = reportsFolder.absolute().description
                                
                                let (success, reportPath) = self.localFileManager.generateReport(finalReport)
                                if success, let path = reportPath {
                                    self.logger.logSection("Report: ", item: "\(path.absolute().description)")
                                }
        }
    }
    
    private func processFile(filename: String, in path: Path, onSuccess: StepCohesionHandler) {
        logger.logInfo("File: ", item: filename, color: .purple)
        
        var finalDefinitions: [ReportClass] = []
    
        swiftParser.parseFile(filename: filename, in: path) { (definitions) in
            finalDefinitions = definitions
        }
        
        let cohesion = Double.random(in: 0.0 ..< 100.0)
        let cohesionString = String(format: "%.2f", cohesion)
        let color = printColor(for: cohesion, threshold: defaultThreshold)
        
        logger.logInfo("Cohesion: ", item: cohesionString+"%%", indentationLevel: 1, color: color)
        
        onSuccess(filename, cohesion, finalDefinitions)
    }
    
    private func processOverallCohesion(configuration: Configuration, finalCohesion: FinalCohesion, threshold: Double, report: ReportOutput, onSuccess: ((ReportOutput) -> Void)? = nil) {
        let overallCohesion = finalCohesion.accumulative / Double(finalCohesion.fileCount)
        let color = printColor(for: overallCohesion, threshold: threshold, fallback: .green)
        let cohesionString = String(format: "%.2f", overallCohesion)
        
        logger.logInfo("Analyzed \(finalCohesion.fileCount) files with \(cohesionString)%% overall cohesion", item: "", color: color)

        var finalReport = report
        
        finalReport.minimum_threshold = configuration.minimum_threshold+"%"
        finalReport.source = configuration.source
        finalReport.cohesion = cohesionString+"%"
        
        onSuccess?(finalReport)
    }
    
    private func printColor(for cohesion: Double, threshold: Double, fallback: ShellColor = .purple) -> ShellColor {
        if cohesion < threshold {
            return .red
        }
        return fallback
    }
}
