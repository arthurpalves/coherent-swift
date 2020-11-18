//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation
import PathKit
import SwiftCLI
import SwiftSyntax

typealias FinalCohesion = (overall: Double, accumulative: Double, fileCount: Int)
typealias StepCohesionHandler = (String, Double?, [CSDefinition], Bool) -> Void
public typealias FileInputData = (enumaratedString: String, folderPath: Path)

let DiffsFlag = Flag("-d", "--diffs", description: "Only scan modified files")

public protocol IOOperations {
    var logger: Logger { get }
    var defaultThreshold: Double { get set }
    var shouldOnlyScanChanges: Bool { get }
    var factory: CSFactory { get }
    
    func readInputFiles(with configuration: Configuration,
                        configurationPath: Path) throws -> FileInputData
    func parse(with fileInputData: FileInputData,
               configuration: Configuration,
               configurationPath: Path, threshold: Double)
    
}

public extension IOOperations {
    var logger: Logger { Logger.shared }
    var shouldOnlyScanChanges: Bool { DiffsFlag.value }
    
    var factory: CSFactory { CSFactory() }
    
    func readInputFiles(with configuration: Configuration, configurationPath: Path) throws -> FileInputData {
        let path = Path("\(configurationPath)/\(configuration.sourcePath().abbreviate())")
        guard path.absolute().exists else {
            throw CLI.Error(message: "Couldn't find source folder")
        }

        var enumaratedString = ""
        
        if shouldOnlyScanChanges {
            /*
             * Scan only files whose contents have been modified
             * from the origin
             */
            logger.logInfo("Only scanning modified files", item: "")
            do {
                let result = try Task.capture("git",
                                              arguments: [
                                                "diff", "--name-only", "--",
                                                "\(path.absolute().description)",
                                                "HEAD", "origin"])
                enumaratedString = result.stdout
                return (enumaratedString: enumaratedString, folderPath: path)
            } catch {
                logger.logError("Error: ", item: "Failed to capture differences path. 'Source' is probably outside of this repository.")
                logger.logInfo("", item: "Proceed with entire source scan")
            }
        }
        
        /*
         * Scan all files within the specified source folder
         */
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: path.absolute().description)
        enumerator?.allObjects.compactMap { $0 as? String }.forEach({ (item) in
            enumaratedString.append(item)
            enumaratedString.append("\n")
        })
        
        return (enumaratedString: enumaratedString, folderPath: path)
    }
    
    func parse(with fileInputData: FileInputData,
               configuration: Configuration,
               configurationPath: Path,
               threshold: Double) {
        
        logger.logSection("Running Analysis", item: "")
        var accumulativeCohesion: Double = 0.0
        var fileAmount: Int = 0
        var report: CSReport = CSReport()
        
        fileInputData.enumaratedString.enumerateLines { (fileName, _) in
            let filePath = self.processFilePath(filename: fileName, sourcePath: configuration.sourcePath())
            
            if filePath.exists,
               filePath.isFile,
               filePath.extension == "swift" {
                
                let parser = SwiftParser()
                parser.parse(filename: fileName,
                             in: fileInputData.folderPath,
                             threshold: self.defaultThreshold) {
                                (filename, cohesion, definitions, validFile) in
                    switch validFile {
                    case false:
                        break
                    case true:
                        let cohesion = cohesion ?? Double(0)
                        let cohesionString = cohesion.formattedCohesion()
                        
                        report = LocalFileManager.shared.addToReport(file: filename, cohesion: cohesionString+"%", meetsThreshold: cohesionString.double >= threshold, definitions: definitions, to: report)

                        accumulativeCohesion += cohesion
                        fileAmount += 1
                    }
                }
            } else if !filePath.isDirectory {
                self.logger.logDebug("⚠️  Ignoring: ",
                                     item: "\(filePath) - Not a .swift file",
                                    color: .purple)
            }
        }
        
        Measurer.shared.processOverallCohesion(configuration: configuration,
                               finalCohesion: (0, accumulativeCohesion, fileAmount),
                               threshold: threshold,
                               report: report) { (finalReport, color) in
                     
            self.logger.logError(
                "Analyzed \(finalReport.result.count) files with \(finalReport.cohesion)% overall cohesion. ",
                item: "Threshold is \(configuration.minimum_threshold)%%",
                color: color)
                                
            let reportsFolder = Path("\(configurationPath)/\(configuration.reportsPath().abbreviate())")
            LocalFileManager.shared.reports_path = reportsFolder.absolute().description
            
            let reportFormat: Configuration.ReportFormat = configuration.report_format ?? .json
            let (success, reportPath) = LocalFileManager.shared.generateReport(finalReport, format: reportFormat)
            if success, let path = reportPath {
                self.logger.logSection("Report: ", item: "\(path.absolute().description)")
            }
            
            if !configuration.ignore_output_result && !finalReport.meets_threshold {
                exit(1)
            }
        }
    }
    
    // MARK: - Private
    
    private func processFilePath(filename: String, sourcePath: Path) -> Path {
        guard let filePath = try? sourcePath.safeJoin(path: Path(filename)) else {
            return Path(filename)
        }
        return filePath
    }
}


extension Path {
  func safeJoin(path: Path) throws -> Path {
    let newPath = self + path

    if !newPath.absolute().description.hasPrefix(absolute().description) {
      throw SuspiciousFileOperation(basePath: self, path: newPath)
    }

    return newPath
  }
}

class SuspiciousFileOperation: Error {
  let basePath: Path
  let path: Path

  init(basePath: Path, path: Path) {
    self.basePath = basePath
    self.path = path
  }

  var description: String {
    return "Path `\(path)` is located outside of base path `\(basePath)`"
  }
}
