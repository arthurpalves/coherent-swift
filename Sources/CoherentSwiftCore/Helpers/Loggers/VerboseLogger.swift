//
//  CoherentSwift
//

import Foundation

public enum ShellColor: String {
    case blue = "\u{001B}[0;34m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case cyan = "\u{001B}[0;36m"
    case purple = "\u{001B}[0;35m"
    case yellow = "\u{001B}[0;33m"
    case ios = "\u{001B}[0;49;36m"
    case android = "\u{001B}[0;49;33m"
    case neutral = "\u{001B}[0m"
    
    func bold() -> String {
        return self.rawValue.replacingOccurrences(of: "[0", with: "[1")
    }
}

public enum LogLevel: String {
    case info = "INFO  "
    case warning = "WARN  "
    case verbose = "DEBUG "
    case error = "ERROR "
    case none = "     "
}

protocol VerboseLogger {
    var verbose: Bool { get }
    var showTimestamp: Bool { get }
    func log(_ prefix: Any, item: Any, indentationLevel: Int, color: ShellColor, logLevel: LogLevel)
}

extension VerboseLogger {
    public func log(_ prefix: Any = "", item: Any, indentationLevel: Int = 0, color: ShellColor = .neutral, logLevel: LogLevel = .none) {
        if logLevel == .verbose {
            guard verbose else { return }
        }
        let indentation = String(repeating: "   ", count: indentationLevel)
        var command = ""
        var arguments: [String] = []
        
        if showTimestamp {
            arguments.append(contentsOf: [
                "\(logLevel.rawValue)",
                "[\(Date().logTimestamp())]: ▸ "
            ])
        }
        
        arguments.append(contentsOf: [
            "\(indentation)",
            "\(color.bold())\(prefix)",
            "\(color.rawValue)\(item)\(ShellColor.neutral.rawValue)"
        ])
        
        arguments.forEach { command.append($0) }
        var outputStream = StandardErrorOutputStream()
        Swift.print(command, to: &outputStream)
    }
    
    public func logBack(_ prefix: Any = "", item: Any, indentationLevel: Int = 0) -> String {
        let indentation = String(repeating: "   ", count: indentationLevel)
        var command = ""
        let arguments =  [
            "[\(Date().logTimestamp())]: ▸ ",
            "\(indentation)",
            "\(prefix)",
            "\(item)"
        ]
        arguments.forEach { command.append($0) }
        return command
    }
}


private struct StandardErrorOutputStream: TextOutputStream {
    let stderr = FileHandle.standardError

    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        stderr.write(data)
    }
}

