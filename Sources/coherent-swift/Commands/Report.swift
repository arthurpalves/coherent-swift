//
//  coherent-swift
//
//  Created by Arthur Alves on 05/05/2020.
//

import Foundation
import PathKit
import SwiftCLI


final class Report: Command, IOOperations {
    
    // --------------
    // MARK: Command information
    
    let name: String = "report"
    let shortDescription: String = "Generate a report on Swift code cohesion"
    
    var overallCohesion: Double = 0.0
    var accumulativeCohesion: Double = 0.0
    var fileAmount: Int = 0
    
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
    
    public func execute() throws {
        logger.logSection("$ ", item: "coherent-swift report", color: .ios)
    
        if let spec = specs {
            configurationPath = spec
        }
        let specsPath = Path(configurationPath)
        
        do {
            guard let configuration = try decode(configuration: specsPath) else { return }
            try readSpecs(configuration: configuration, configurationPath: Path(configurationPath).parent(), threshold: defaultThreshold)
        } catch {
            guard
                let cliError = error as? CLI.Error,
                let message = cliError.message
            else { return }
            logger.logError(item: message)
            throw cliError
        }
    }
}


extension Report: YamlParser {
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
