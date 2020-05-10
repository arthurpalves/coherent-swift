//
//  coherent-swift
//
//  Created by Arthur Alves on 05/05/2020.
//

import Foundation
import SwiftCLI
import Yams

public protocol YamlParser {
    func extractConfiguration(from configurationPath: String) throws -> Configuration
}

extension YamlParser {
    public func extractConfiguration(from configurationPath: String) throws -> Configuration {
        let decoder = YAMLDecoder()
        let encoder = YAMLEncoder()
        
        let logger = Logger.shared
        
        do {
            let encodedYAML = try String(contentsOfFile: configurationPath, encoding: .utf8)
            let decoded: Configuration = try decoder.decode(Configuration.self, from: encodedYAML)
            
            logger.log("Loaded configuration:", item: "", logLevel: .verbose)
            let encoded = try encoder.encode(decoded)
            let nsString = encoded as NSString
            nsString.enumerateLines { (stringLine, _) in
                logger.log(item: stringLine, indentationLevel: 1, color: .purple, logLevel: .verbose)
            }
            
            return decoded
            
        } catch {
            logger.logError(item: "Error reading configuration file \(configurationPath)")
            throw CLI.Error(message: error.localizedDescription)
        }
    }
}
