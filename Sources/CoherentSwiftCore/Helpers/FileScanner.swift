//
//  CoherentSwift
//

import Foundation
import PathKit
import SwiftCLI
import SwiftSyntax

public class FileScanner {
    public init(
        factory: CSFactory = CSFactory(),
        logger: Logger = .shared,
        shouldOnlyScanChanges: Bool = false,
        defaultThreshold: Double
    ) {
        self.factory = factory
        self.logger = logger
        self.shouldOnlyScanChanges = shouldOnlyScanChanges
        self.defaultThreshold = defaultThreshold
    }

    public func parse(with configuration: Configuration, parentPath: Path) throws {
        let absoluteSourcePath = try parentPath.safeJoin(path: configuration.sourcePath())
        guard absoluteSourcePath.exists else {
            throw RuntimeError("Source folder '\(absoluteSourcePath.string)' doesn't exist")
        }
        
        let fileInputData = try readInputFiles(with: configuration,
                                               sourcePath: absoluteSourcePath)
        parse(with: fileInputData,
              configuration: configuration,
              sourcePath: absoluteSourcePath,
              threshold: defaultThreshold)
    }
    
    func readInputFiles(with configuration: Configuration, sourcePath: Path) throws -> FileInputData {
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
                                                "\(sourcePath.absolute().string)",
                                                "HEAD", "origin"])
                enumaratedString = result.stdout
                return (enumaratedString: enumaratedString, folderPath: sourcePath)
            } catch {
                logger.logError("Error: ",
                                item: "Failed to capture differences path. 'Source' is probably outside of this repository.")
                logger.logInfo("", item: "Proceed with entire source scan")
            }
        }
        
        /*
         * Scan all files within the specified source folder
         */
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: sourcePath.absolute().string)
        enumerator?.allObjects.compactMap { $0 as? String }.forEach({ (item) in
            enumaratedString.append(item)
            enumaratedString.append("\n")
        })
        
        return (enumaratedString: enumaratedString, folderPath: sourcePath)
    }
    
    func parse(with fileInputData: FileInputData,
               configuration: Configuration,
               sourcePath: Path,
               threshold: Double) {
        
        logger.logSection("Running Analysis", item: "")
        var accumulativeCohesion: Double = 0.0
        var fileAmount: Int = 0
        var report: CSReport = CSReport()
        
        fileInputData.enumaratedString.enumerateLines { [weak self] (fileName, _) in
            guard let self = self else { return }
            let filePath = self.processFilePath(filename: fileName, sourcePath: configuration.sourcePath())
            
            if filePath.exists, filePath.isFile,
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
                        
                        report = LocalFileManager.shared
                            .addToReport(file: filename,
                                         cohesion: cohesionString+"%",
                                         meetsThreshold: cohesionString.double >= threshold,
                                         definitions: definitions,
                                         to: report)

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
                               report: report) { [weak self] (finalReport, color) in
                     
            self?.logger.logError(
                "Analyzed \(finalReport.result.count) files with \(finalReport.cohesion)% overall cohesion. ",
                item: "Threshold is \(configuration.minimum_threshold)%%",
                color: color)
            
            LocalFileManager.shared.reportsPath = configuration.reportsPath()
            
            let reportFormat: Configuration.ReportFormat = configuration.report_format ?? .json
            let (success, reportPath) = LocalFileManager.shared.generateReport(finalReport, format: reportFormat)
            if success, let path = reportPath {
                self?.logger.logSection("Report: ", item: "\(path.absolute().description)")
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
    
    private let factory: CSFactory
    private let logger: Logger
    private let shouldOnlyScanChanges: Bool
    private let defaultThreshold: Double
}
