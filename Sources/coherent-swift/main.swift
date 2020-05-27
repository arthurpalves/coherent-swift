
import SwiftCLI

let cli = CLI(
    name: "coherent-swift",
    version: "0.5.0",
    description: "A command-line tool to analyze and report Swift code cohesion"
)

cli.commands = [
    Initializer(),
    Report()
]

cli.globalOptions.append(VerboseFlag)
cli.globalOptions.append(DiffsFlag)

_ = cli.go()
