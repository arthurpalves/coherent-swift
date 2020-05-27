//
//  coherent-swift
//
//  Created by Arthur Alves on 26/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

final class Initializer: Command, VerboseLogger {
    // --------------
    // MARK: Command information
    
    let name: String = "init"
    let shortDescription: String = "Generate specs (.yml) file"
    
    let logger = Logger.shared
    
    public func execute() throws {
        logger.logSection("$ ", item: "coherent-swift init", color: .ios)
        let templateFolder = "/usr/local/lib/coherent-swift/templates"
        do {
            logger.logInfo("Generating specs file in: ", item: "./coherent-swift.yml")
            try generateConfig(path: Path(templateFolder))
        } catch {
            logger.logError("Error: ", item: "", color: .red)
            throw CLI.Error(message: "Couldn't generate YAML specs")
        }
    }
    
    private func generateConfig(path: Path) throws {
        guard path.absolute().exists else {
            throw CLI.Error(message: "Couldn't find template path")
        }
        try Task.run(bash: "cp \(path.absolute())/coherent-swift-template.yml ./coherent-swift.yml", directory: nil)
        logger.logSection("Specs file generated successfully!", item: "")
    }
}
