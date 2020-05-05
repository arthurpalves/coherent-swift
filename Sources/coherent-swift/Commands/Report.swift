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
    
    var overallCohesion: Double = 0.0
    var accumulativeCohesion: Double = 0.0
    var fileAmount: Int = 0
    
    // --------------
    // MARK: Configuration Properties
    
    @Param var specs: String
    
    @Param var defaultThreshold: Double
    
    public func execute() throws {
        log("--------------------------------------------", force: true)
        log(prefix: "coherent-swift", item: "report\n", force: true)
        
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
            if filename.hasSuffix(".swift") {
                processFile(filename: filename, in: path)
            }
        }
        processOverallCohesion()
    }
        
    private func processFile(filename: String, in path: Path) {
        log(prefix: "Analysing:", item: "\(filename)\n", indentationLevel: 1, color: .purple, force: true)
        let cohesion = Double.random(in: 0.0 ..< 100.0)
        var color = printColor(for: cohesion, threshold: defaultThreshold)
        log(prefix: "Cohesion:", item: "\(String(format: "%.2f", cohesion))%%\n", indentationLevel: 2, color: color, force: true)
        
        accumulativeCohesion += cohesion
        fileAmount += 1
    }
    
    private func processOverallCohesion() {
        overallCohesion = accumulativeCohesion / Double(fileAmount)
        var color = printColor(for: overallCohesion, threshold: defaultThreshold)
        log(prefix: "Analyzed \(fileAmount) files with \(String(format: "%.2f", overallCohesion))%% overall cohesion", item: "\n", indentationLevel: 1, color: color, force: true)
    }
    
    private func printColor(for cohesion: Double, threshold: Double) -> ShellColor {
        if cohesion < threshold {
            return .red
        }
        return .purple
    }
}
