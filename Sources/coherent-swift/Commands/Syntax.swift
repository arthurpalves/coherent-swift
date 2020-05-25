//
//  File.swift
//  
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation
import PathKit
import SwiftCLI
import SwiftSyntax

final class Syntaxy: Command, IOOperations {
    
    // --------------
    // MARK: Command information
    
    let name: String = "syntax"
    let shortDescription: String = "Generate a report on Swift code cohesion"
    
    // --------------
    // MARK: Configuration Properties
    @Key("-s", "--spec", description: "Use a yaml configuration file")
    var specs: String?
    
    var configurationPath: String = "coherent-swift.yml"
    var defaultThreshold: Double = 100.0
    var report: ReportOutput = ReportOutput()
    
    var reports_path: String = "/tmp/coherent-swift/" {
        willSet {}
    }
    
    var logger: Logger = Logger.shared
    
    public func execute() throws {
        logger.logSection("$ ", item: "coherent-swift syntax", color: .ios)
    
        if let spec = specs {
            configurationPath = spec
        }
        let specsPath = Path(configurationPath)
        
        do {
            guard let configuration = try decode(configuration: specsPath) else { return }
            try readDefinitions(configuration: configuration,
                          configurationPath: Path(configurationPath).parent(),
                          threshold: defaultThreshold)
        } catch {
            guard
                let cliError = error as? CLI.Error,
                let message = cliError.message
            else { return }
            logger.logError(item: message)
            throw cliError
        }
    }
    
    private func readDefinitions(configuration: Configuration, configurationPath: Path, threshold: Double) throws {
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
            if filename.hasSuffix(".swift"), filename.contains("ViewController") {
                self.processNewFile(filename: filename, in: path) { (filename, cohesion, definitions, validFile) in
                    let filePath = Path("\(path.absolute())/\(filename)")
                    let url = filePath.absolute().url
                    do {
                        let sourceFile = try SyntaxParser.parse(url)
                        let parser = SwiftSyntaxParser()
                        parser.walk(sourceFile)
//                        dump(parser.currentDefintion)
                        
                        print(parser.fileDefinitions.count)
                    } catch {}
                }
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
    
    private func processNewFile(filename: String, in path: Path, onSuccess: StepCohesionHandler) {
        logger.logInfo("File: ", item: filename, color: .purple)
        onSuccess(filename, nil, [], true)
    }
}

extension Syntaxy: YamlParser {
    private func decode(configuration: Path) throws -> Configuration? {
        logger.logInfo("Configuration path: ", item: configuration.absolute().description)
        guard configuration.absolute().exists else {
            throw CLI.Error(message: "Couldn't find specs path. Specify with parameter -s | --spec or use default at ./coherent-swift.yml")
        }
        
        do {
            let configuration = try extractConfiguration(from: configuration.absolute().description)
            defaultThreshold = configuration.threshold() ?? 100.0
            return configuration
        } catch {
            throw CLI.Error(message: error.localizedDescription)
        }
    }
}
