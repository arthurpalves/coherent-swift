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

let DiffsFlag = Flag("-d", "--diffs", description: "Only scan modified files")

public enum ParseType: String {
    case definition = "definition"
    case method = "method"
    case property = "property"
    
    func regex() -> String {
        switch self {
        case .definition:
            return "class |struct |extension"
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
    var shouldOnlyScanChanges: Bool { get }
    
    func readSpecs(configuration: Configuration, configurationPath: Path, threshold: Double) throws
}

extension IOOperations {
    var logger: Logger { Logger.shared }
    var swiftParser: SwiftParser { SwiftParser.shared }
    var localFileManager: LocalFileManager { LocalFileManager.shared }
    var shouldOnlyScanChanges: Bool { DiffsFlag.value }
    
    func readSpecs(configuration: Configuration, configurationPath: Path, threshold: Double) throws {
        let path = Path("\(configurationPath)/\(configuration.sourcePath().abbreviate())")
        guard path.absolute().exists else {
            throw CLI.Error(message: "Couldn't find source folder")
        }

        var enumaratedString = ""
        var accumulativeCohesion: Double = 0.0
        var fileAmount: Int = 0
        var report: ReportOutput = ReportOutput()
        
        if shouldOnlyScanChanges {
            /*
             * Scan only files whose contents have been modified
             * from the origin
             */
            logger.logInfo("Only scanning modified files", item: "")
            do {
                let result = try Task.capture("git", arguments: ["diff", "--name-only", "--",
                                                                 "\(path.absolute().description)", "HEAD", "origin"])
                enumaratedString = result.stdout
            } catch {
                logger.logError("Error: ", item: "Failed to capture differences path. 'Source' is probably outside of this repository.")
                logger.logInfo("", item: "Proceed with entire source scan")
            }
        } else {
            /*
             * Scan all files within the specified source folder
             */
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(atPath: path.absolute().description)
            enumerator?.allObjects.compactMap { $0 as? String }.forEach({ (item) in
                enumaratedString.append(item)
                enumaratedString.append("\n")
            })
        }

        logger.logSection("Running Analysis", item: "")
        enumaratedString.enumerateLines { (line, _) in
            let filename = self.processFilePath(filename: line, sourcePath: configuration.sourcePath().lastComponent)
            if filename.hasSuffix(".swift") {
                self.processFile(filename: filename, in: path) { (filename, cohesion, definitions, validFile) in
                    switch validFile {
                    case false:
                        break
                    case true:
                        let cohesion = cohesion ?? Double(0)
                        let cohesionString = cohesion.formattedCohesion()
                        
                        report = self.localFileManager.addToReport(file: filename, cohesion: cohesionString+"%", meetsThreshold: cohesionString.double >= threshold, definitions: definitions, to: report)
                        
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
            
            let reportFormat: ReportFormat = ReportFormat(rawValue: configuration.report_format ?? "json") ?? .json                                
            let (success, reportPath) = self.localFileManager.generateReport(finalReport, format: reportFormat)
            if success, let path = reportPath {
                self.logger.logSection("Report: ", item: "\(path.absolute().description)")
            }
            
            if !configuration.ignore_output_result && !finalReport.meets_threshold {
                exit(1)
            }
        }
    }
    
    private func processFilePath(filename: String, sourcePath: String) -> String {
        var filepath = filename
        if filepath.contains(sourcePath) {
            filepath = filepath.replacingOccurrences(of: sourcePath, with: "")
            filepath = filepath.starts(with: "/") ? String(filepath.dropFirst()) : filepath
        }
        return filepath
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
        let color = Labeler.shared.printColor(for: cohesion, threshold: defaultThreshold)
        let cohesionString = cohesion.formattedCohesion()
        
        logger.logInfo("Cohesion: ", item: cohesionString+"%%", indentationLevel: 1, color: color)
        
        onSuccess(filename, cohesion, finalDefinitions, true)
    }
    
    private func processOverallCohesion(configuration: Configuration, finalCohesion: FinalCohesion, threshold: Double, report: ReportOutput, onSuccess: ((ReportOutput) -> Void)? = nil) {
        let overallCohesion = finalCohesion.accumulative / Double(finalCohesion.fileCount)
        let color = Labeler.shared.printColor(for: overallCohesion, threshold: threshold, fallback: .green)
        let cohesionString = overallCohesion.formattedCohesion()
        
        logger.logInfo("Analyzed \(finalCohesion.fileCount) files with \(cohesionString)%% overall cohesion. ", item: "Threshold is \(configuration.minimum_threshold)%%", color: color)

        var finalReport = report
        
        finalReport.minimum_threshold = configuration.minimum_threshold+"%"
        finalReport.source = configuration.source
        finalReport.cohesion = cohesionString+"%"
        finalReport.meets_threshold = overallCohesion >= threshold
        
        onSuccess?(finalReport)
    }
}
