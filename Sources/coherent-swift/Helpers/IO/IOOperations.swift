//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

typealias FinalCohesion = (overall: Double, accumulative: Double, fileCount: Int)
typealias StepCohesionHandler = (String, Double?, [ReportDefinition], Bool) -> Void

public enum ParseType: String {
    case definition = "definition"
    case method = "method"
    case property = "property"
    
    func regex() -> String {
        switch self {
        case .definition:
            return "class|struct|extension"
        case .method:
            return "func"
        case .property:
            return "(var|let)"
        }
    }
    
    func delimiter() -> String {
        switch self {
        case .definition:
            return "?=(:|\\{)"
        case .method:
            return "?=\\{"
        case .property:
            return "( |:)"
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
                processFile(filename: filename, in: path) { (filename, cohesion, definitions, validFile) in
                    
                    switch validFile {
                    case false:
                        break
                    case true:
                        let cohesion = cohesion ?? Double(0)
                        let cohesionString = cohesion.formattedCohesion()
                        
                        report = localFileManager.addToReport(file: filename, cohesion: cohesionString+"%", meetsThreshold: cohesionString.double >= threshold, definitions: definitions, to: report)
                        
                        accumulativeCohesion += cohesion
                        fileAmount += 1
                    }
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
                                
                                if !configuration.ignore_output_result && !finalReport.meets_threshold {
                                    exit(1)
                                }
        }
    }
    
    private func processFile(filename: String, in path: Path, onSuccess: StepCohesionHandler) {
        logger.logInfo("File: ", item: filename, color: .purple)
        
        var finalDefinitions: [ReportDefinition] = []
    
        swiftParser.parseFile(filename: filename, in: path) { (definitions) in
            finalDefinitions = definitions
        }
        
        if finalDefinitions.isEmpty {
            logger.logInfo("Ignored: ", item: "No implementation found", indentationLevel: 1, color: .purple)
            onSuccess(filename, nil, [], false)
            return
        }
        
        let cohesion = Cohesion.main.generateCohesion(for: finalDefinitions)
        let color = printColor(for: cohesion, threshold: defaultThreshold)
        let cohesionString = cohesion.formattedCohesion()
        
        logger.logInfo("Cohesion: ", item: cohesionString+"%%", indentationLevel: 1, color: color)
        
        onSuccess(filename, cohesion, finalDefinitions, true)
    }
    
    private func processOverallCohesion(configuration: Configuration, finalCohesion: FinalCohesion, threshold: Double, report: ReportOutput, onSuccess: ((ReportOutput) -> Void)? = nil) {
        let overallCohesion = finalCohesion.accumulative / Double(finalCohesion.fileCount)
        let color = printColor(for: overallCohesion, threshold: threshold, fallback: .green)
        let cohesionString = overallCohesion.formattedCohesion()
        
        logger.logInfo("Analyzed \(finalCohesion.fileCount) files with \(cohesionString)%% overall cohesion. ", item: "Threshold is \(configuration.minimum_threshold)%%", color: color)

        var finalReport = report
        
        finalReport.minimum_threshold = configuration.minimum_threshold+"%"
        finalReport.source = configuration.source
        finalReport.cohesion = cohesionString+"%"
        finalReport.meets_threshold = overallCohesion >= threshold
        
        onSuccess?(finalReport)
    }
    
    private func printColor(for cohesion: Double, threshold: Double, fallback: ShellColor = .purple) -> ShellColor {
        if cohesion < threshold {
            return .red
        }
        return fallback
    }
}
