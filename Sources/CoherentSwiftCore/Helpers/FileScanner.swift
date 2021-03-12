//
//  CoherentSwift
//

import Foundation
import PathKit
import SwiftSyntax

typealias FinalCohesion = (overall: Double, accumulative: Double, fileCount: Int)
typealias StepCohesionHandler = (String, Double?, [CSDefinition], Bool) -> Void
typealias FileInputData = (enumaratedString: String, folderPath: Path)

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
        let absoluteSourcePaths = configuration.sourcePaths()
            .flatMap { $0.glob("") }
            .compactMap { try? parentPath.safeJoin(path: $0) }
            .filter { $0.exists }

        guard !absoluteSourcePaths.isEmpty else {
            throw RuntimeError("Source folders '\(absoluteSourcePaths)' doesn't exist")
        }

        for absoluteSourcePath in absoluteSourcePaths {
            let fileInputData = try readInputFiles(with: configuration,
                                                   sourcePath: absoluteSourcePath)
            parse(with: fileInputData,
                  configuration: configuration,
                  sourcePath: absoluteSourcePath,
                  threshold: defaultThreshold)
        }
    }
    
    func readInputFiles(with configuration: Configuration, sourcePath: Path) throws -> FileInputData {
        if shouldOnlyScanChanges {
            /*
             * Scan only files whose contents have been modified
             * from the origin
             */
            logger.logInfo("*  ", item: "Only scanning modified files")
            do {
                
                if let originHEAD = try Bash.Command(command: "git", arguments: ["remote", "show", "origin"])
                    .pipe(Bash.Command(command: "grep", arguments: ["HEAD branch"]))
                    .pipe(Bash.Command(command: "cut", arguments: ["-d", ":", "-f", "2"]))
                    .run() {
                    
                    let defaultBranch = originHEAD.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                    if let changes = try Bash.Command(command: "git",
                                                      arguments: ["diff",
                                                                  "HEAD..origin/\(defaultBranch)",
                                                                  "--name-only", "--",
                                                                  "\(sourcePath.absolute().description)"]).run() {
                        return (enumaratedString: changes, folderPath: sourcePath)
                    }
                    
                }
            } catch {}
            logger.logError("Error: ",
                            item: "Failed to capture differences path. 'Source' is probably outside of this repository.")
            logger.logInfo("", item: "Proceed with entire source scan")
        }
        
        /*
         * Scan all files within the specified source folder
         */
        let enumaratedString = FileManager.default
            .enumerator(atPath: sourcePath.absolute().string)?
            .allObjects
            .compactMap { $0 as? String }
            .joined(separator: "\n") ?? ""
        return (enumaratedString: enumaratedString, folderPath: sourcePath)
    }
    
    func parse(with fileInputData: FileInputData,
               configuration: Configuration,
               sourcePath: Path,
               threshold: Double) {
        
        logger.logInfo("*  ", item:
                        """
                        Running Analysis

                        """)
        var accumulativeCohesion: Double = 0.0
        var fileAmount: Int = 0
        var report: CSReport = CSReport()
        
        fileInputData.enumaratedString.enumerateLines { [weak self] (fileName, _) in
            guard let self = self else { return }
            let filePath = self.processFilePath(filename: fileName, sourcePath: sourcePath)
            
            if filePath.exists, filePath.isFile,
               filePath.extension == "swift" {
                
                let parser = SwiftParser(logger: self.logger, factory: self.factory)
                parser.parse(file: filePath,
                             threshold: self.defaultThreshold) {
                                (filename, cohesion, definitions, validFile) in
                    switch validFile {
                    case false:
                        self.logger.logDebug("Oops! ", item: "Invalid file")
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
                self.logger.logDebug("⚠️  Ignoring: ", item: "\(filePath) - Not a .swift file")
            }
        }
        
        Measurer.shared.processOverallCohesion(configuration: configuration,
                               finalCohesion: (0, accumulativeCohesion, fileAmount),
                               threshold: threshold,
                               report: report) { [weak self] (finalReport, color) in
                     
            self?.logger.logError(
                "Analyzed \(finalReport.result.count) files with \(finalReport.cohesion) overall cohesion. ",
                item: "Threshold is \(self?.defaultThreshold ?? configuration.minimum_threshold.double)%",
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
        let filePath = Path(filename)
        return processFilePath(filePath: filePath, sourcePath: sourcePath)
    }

    private func processFilePath(filePath: Path, sourcePath: Path) -> Path {
        guard let processedFilePath = try? sourcePath.safeJoin(path: filePath) else {
            return filePath
        }
        return processedFilePath
    }

    private let factory: CSFactory
    private let logger: Logger
    private let shouldOnlyScanChanges: Bool
    private let defaultThreshold: Double
}
