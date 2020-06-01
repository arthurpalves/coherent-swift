//
//  coherent-swift
//
//  Created by Arthur Alves on 26/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

typealias DoesFileExist = (exists: Bool, path: Path?)

final class Initializer: Command, VerboseLogger {
    // --------------
    // MARK: - Command information
    
    let name: String = "init"
    let shortDescription: String = "Generate specs (.yml) file"
    
    let logger = Logger.shared
    
    public func execute() throws {
        logger.logSection("$ ", item: "coherent-swift init", color: .ios)
        
        let result = doesTemplateExist()
        guard result.exists, let path = result.path
        else {
            self.logger.logError("Error: ", item: "Templates folder not found on '/usr/local/lib/coherent-swift/templates' or './Templates'", color: .red)
            exit(1)
        }
        
        do {
            self.logger.logInfo("Generating specs file in: ", item: "./coherent-swift.yml")
            
            try self.generateConfig(path: path)
        } catch {
            logger.logError("Error: ", item: "Couldn't generate YAML specs", color: .red)
            throw CLI.Error(message: "")
        }
    }
    
    // MARK: - Private
    
    private func doesTemplateExist() -> DoesFileExist {
        var path: Path?
        var exists = true
        
        let libTemplates = Path("/usr/local/lib/coherent-swift/templates")
        let localTemplates = Path("./Templates")
        
        if libTemplates.exists {
            path = libTemplates
        } else if localTemplates.exists {
            path = localTemplates
        } else {
            exists = false
        }
        
        return (exists: exists, path: path)
    }
    
    private func generateConfig(path: Path) throws {
        guard path.absolute().exists else {
            throw CLI.Error(message: "Couldn't find template path")
        }
        try Task.run(bash: "cp \(path.absolute())/coherent-swift-template.yml ./coherent-swift.yml", directory: nil)
        logger.logSection("Specs file generated successfully!", item: "")
    }
}
