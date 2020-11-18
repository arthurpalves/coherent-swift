//
//  CoherentSwift
//

import Foundation
import Yams
import PathKit

public class YamlParser {
    public init (
        logger: Logger = Logger.shared,
        decoder: YAMLDecoder = YAMLDecoder(),
        encoder: YAMLEncoder = YAMLEncoder()
    ) {
        self.logger = logger
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public func extractConfiguration(from configurationPath: Path) throws -> Configuration {
        do {
            let encodedYAML = try String(contentsOfFile: configurationPath.absolute().string, encoding: .utf8)
            let decoded: Configuration = try decoder.decode(Configuration.self, from: encodedYAML)
            return decoded
            
        } catch {
            logger.logError(item: "Error reading configuration file \(configurationPath)")
            throw RuntimeError(error.localizedDescription)
        }
    }
    
    let logger: Logger
    let decoder: YAMLDecoder
    let encoder: YAMLEncoder
}
