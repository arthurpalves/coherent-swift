//
//  CoherentSwift
//

import Foundation
import CoherentSwiftCore
import ArgumentParser
import PathKit

struct Report: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "report",
        abstract: "Generate a report on Swift code cohesion"
    )
    
    @Option(name: .shortAndLong, help: "Use a different yaml configuration spec")
    var spec: String = "coherent-swift.yml"
    
    @Flag(name: .shortAndLong, help: "Only scan modified files.")
    var diffs = false
    
    @Flag(name: [.long, .customShort("t")], help: "Show timestamps.")
    var showTimestamps = false
    
    @Flag(name: .shortAndLong, help: "Log tech details for nerds.")
    var verbose = false
    
    func run() throws {
        let logger = Logger(verbose: verbose, showTimestamp: showTimestamps)
        logger.logSection("$ coherent-swift report", item: "", color: .purple)
        
        let specsPath = Path(spec)
        let specHelper = SpecHelper(logger: logger, userInputHelper: UserInputHelper(logger: logger))
        guard let configuration = try specHelper.parseSpec(from: specsPath) else {
            throw RuntimeError("Couldn't load configuration")
        }
        
        let fileScanner = FileScanner(logger: logger, shouldOnlyScanChanges: diffs, defaultThreshold: configuration.threshold() ?? 100)
        try fileScanner.parse(with: configuration, parentPath: specsPath.parent())
        logger.logInfo(item: " ")
    }
}
