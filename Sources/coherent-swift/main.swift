
import SwiftCLI

let cli = CLI(
    name: "coherent-swift",
    version: "0.4.2",
    description: "A command-line tool to analyze and report Swift code cohesion"
)

cli.commands = [
    Report(),
    Syntaxy()
]

cli.globalOptions.append(VerboseFlag)
cli.globalOptions.append(DiffsFlag)

_ = cli.go()
