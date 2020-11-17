
import SwiftCLI

let cli = CLI(
    name: "coherent-swift",
    version: "0.5.2",
    description: "A command-line tool to analyze and report Swift code cohesion"
)

cli.commands = [
    Initializer(),
    Report()
]

_ = cli.go()
