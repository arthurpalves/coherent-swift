//
//  CoherenSwift
//

import ArgumentParser

struct CoherentSwift: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "coherent-swift",
        abstract: "A command-line tool to analyze and report Swift code cohesion",
        version: "0.5.10",
        subcommands: [
            Initializer.self,
            Report.self
        ]
    )
}

CoherentSwift.main()
