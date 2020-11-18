//
//  CoherentSwift
//

import Foundation

public class Logger: VerboseLogger {
    public static let shared = Logger()
    
    public init(verbose: Bool = false, showTimestamp: Bool = false) {
        self.isVerbose = verbose
        self.shouldShowTimestamp = showTimestamp
    }
    
    var verbose: Bool { return isVerbose }
    var showTimestamp: Bool { return shouldShowTimestamp }
    
    public func logError(_ prefix: Any = "", item: Any, color: ShellColor = .red) {
        divider(logLevel: .error)
        log(prefix, item: item, color: color, logLevel: .error)
        divider(logLevel: .error)
    }
    
    func logWarning(_ prefix: Any = "⚠️  ", item: Any, indentationLevel: Int = 0, color: ShellColor = .yellow) {
        log(prefix, item: item, indentationLevel: indentationLevel, color: color, logLevel: .warning)
    }
    
    public func logInfo(_ prefix: Any = "", item: Any, indentationLevel: Int = 0, color: ShellColor = .neutral) {
        log(prefix, item: item, indentationLevel: indentationLevel, color: color, logLevel: .info)
    }
    
    public func logDebug(_ prefix: Any = "", item: Any, indentationLevel: Int = 0, color: ShellColor = .neutral) {
        log(prefix, item: item, indentationLevel: indentationLevel, color: color, logLevel: .verbose)
    }
    
    public func logSection(_ prefix: Any = "", item: Any, color: ShellColor = .neutral) {
        divider(logLevel: .info)
        log(prefix, item: item, color: color, logLevel: .info)
        divider(logLevel: .info)
    }
    
    // MARK: - Private
    
    private func divider(logLevel: LogLevel) {
        log(item: " ", logLevel: logLevel)
    }
    
    private let isVerbose: Bool
    private let shouldShowTimestamp: Bool
}
