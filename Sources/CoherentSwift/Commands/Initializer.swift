//
//  CoherenSwift
//

import Foundation
import CoherentSwiftCore
import ArgumentParser

struct Initializer: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Generate spec file 'coherent-swift.yml'"
    )
    
    @Flag(name: .shortAndLong, help: "Log tech details for nerds.")
    var verbose = false
    
    @Flag(name: [.long, .customShort("t")], help: "Show timestamps.")
    var showTimestamps = false
    
    func run() throws {
        let logger = Logger(verbose: verbose, showTimestamp: showTimestamps)
        logger.logSection("$ coherent-swift init", item: "", color: .purple)
        
        let path = try TemplateDirectory().path
        let specHelper = SpecHelper(logger: logger, userInputHelper: UserInputHelper(logger: logger))
        try specHelper.generate(from: path)
        logger.logInfo(item: " ")
    }
}
