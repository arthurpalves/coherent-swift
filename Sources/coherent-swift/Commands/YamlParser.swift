//
//  coherent-swift
//
//  Created by Arthur Alves on 05/05/2020.
//

import Foundation
import SwiftCLI
import Yams

public protocol YamlParser: VerboseLogger {
    var verbose: Bool { get }
    func extractConfiguration(from configurationPath: String) throws -> Configuration
}

extension YamlParser {
    public var verbose: Bool { VerboseFlag.value }
    
    public func extractConfiguration(from configurationPath: String) throws -> Configuration {
        let decoder = YAMLDecoder()
        let encoder = YAMLEncoder()
        
        do {
            let encodedYAML = try String(contentsOfFile: configurationPath, encoding: .utf8)
            let decoded: Configuration = try decoder.decode(Configuration.self, from: encodedYAML)
            
            log("Configuration:", item: "", logLevel: .verbose)
            let encoded = try encoder.encode(decoded)
            let nsString = encoded as NSString
            nsString.enumerateLines { [self] (stringLine, _) in
                self.log(item: stringLine, indentationLevel: 1, color: .purple, logLevel: .verbose)
            }
            
            return decoded
            
        } catch {
            log(item: "--------------------------------------------------------------------------------------", logLevel: .error)
            log(item: "Error reading configuration file \(configurationPath)", logLevel: .error)
            log(item: "--------------------------------------------------------------------------------------", logLevel: .error)
            throw CLI.Error(message: error.localizedDescription)
        }
    }
}
