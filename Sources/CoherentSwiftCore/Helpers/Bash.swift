//
//  CoherentSwift
//

import Foundation

public struct Bash {
    public struct Command {
        let command: String
        let arguments: [String]
        
        public init(command: String, arguments: [String]) {
            self.command = command
            self.arguments = arguments
        }
    }
    
    func pipe(_ command: String, arguments: [String], inputPipe: Pipe? = nil) throws -> Pipe {
        guard var bashCommand = try execute(command: "/bin/bash",
                                            arguments: ["-l", "-c", "which \(command)"])
        else {
            throw RuntimeError("\(command) not found")
        }
        bashCommand = bashCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        return try getPipe(for: bashCommand, arguments: arguments, inputPipe: inputPipe)
    }
    
    // MARK: - Private
    
    private func execute(command: String, arguments: [String] = []) throws -> String? {
        let pipe = try getPipe(for: command, arguments: arguments)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        return output
    }
    
    private func getPipe(for command: String, arguments: [String] = [], inputPipe: Pipe? = nil) throws -> Pipe {
        let process = Process()
        let outputPipe = Pipe()
        process.arguments = arguments
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        
        if #available(OSX 10.13, *) {
            process.executableURL = URL(fileURLWithPath: command)
            try process.run()
        } else {
            process.launchPath = command
            process.launch()
        }
        return outputPipe
    }
}

public extension Bash.Command {
    @discardableResult
    func pipe(_ bashCommand: Bash.Command) throws -> Pipe {
        return try Bash()
            .pipe(self.command, arguments: self.arguments)
            .pipe(bashCommand)
    }

    @discardableResult
    func run() throws -> String? {
        return try Bash().pipe(self.command,
                               arguments: self.arguments).run()
    }
}

public extension Pipe {
    @discardableResult
    func pipe(_ bashCommand: Bash.Command) throws -> Pipe {
        return try Bash().pipe(bashCommand.command,
                               arguments: bashCommand.arguments,
                               inputPipe: self)
    }
    
    @discardableResult
    func run() throws -> String? {
        let data = self.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
