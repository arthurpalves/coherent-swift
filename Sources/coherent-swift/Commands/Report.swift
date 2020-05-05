//
//  coherent-swift
//
//  Created by Arthur Alves on 05/05/2020.
//

import Foundation
import PathKit
import SwiftCLI



final class Report: Command, VerboseLogger {
    // --------------
    // MARK: Command information
    
    let name: String = "report"
    let shortDescription: String = "Generate a report on Swift code cohesion"
    
    // --------------
    // MARK: Configuration Properties
    
    @Param var specs: String
    
    public func execute() throws {
        log("--------------------------------------------", force: true)
        log("Running: coherent-swift report", force: true)
        
        let specsPath = Path(specs)
        log("Specs: \(specs)")
        log("--------------------------------------------", force: true)
        
        do {
            try readSpecs(path: specsPath)
        } catch {
            log("Error: ", color: .red, force: true)
            throw CLI.Error(message: error.localizedDescription)
        }
    }
    
    private func readSpecs(path: Path) throws {
        guard path.absolute().exists else {
            log("--------------------------------------------", force: true)
            log("Error: Parameter not specified: -s | --spec = path to your coherent-swift.yml \n", color: .red)
            throw CLI.Error(message: "Couldn't find specs path")
        }
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: path.absolute().description)
        while let filename = enumerator?.nextObject() as? String {
            log(prefix: "Analysing:", item: "\(filename)\n", indentationLevel: 1, color: .purple, force: true)
        }
    }
}
