//
//  CoherentSwift
//

import Foundation
import PathKit
import Yams

public class SpecHelper {
    public init(
        templatePath: Path = Path("coherent-swift-template.yml"),
        logger: Logger = Logger.shared,
        userInputHelper: UserInputHelper = UserInputHelper(logger: Logger.shared)
    ) {
        self.templatePath = templatePath
        self.logger = logger
        self.userInputHelper = userInputHelper
    }

    /// Generate Variants YAML spec from a template
    /// - Parameters:
    ///   - path: Path to the YAML spec template
    /// - Throws: Exception for any operation that goes wrong.
    public func generate(from path: Path) throws {
        guard path.absolute().exists else {
            throw RuntimeError("Couldn't find template path")
        }

        let sourcePath = Path(components: [path.absolute().string, templatePath.string])
        if coherentSwiftSpecPath.exists {
            if !userInputHelper.doesUserGrantPermissionToOverrideSpec(){
                return
            } else {
                try coherentSwiftSpecPath.delete()
            }
        }
        try sourcePath.copy(coherentSwiftSpecPath)
        logger.logInfo("📝  ", item: "CoherentSwift spec generated with success at path '\(coherentSwiftSpecPath)'")
    }
    
    /// Parse YAML spec or read user input from STDIN
    /// - Parameter path: Path to YAML spec
    /// - Throws: Parsing Error
    /// - Returns: Configuration
    public func parseSpec(from path: Path) throws -> Configuration? {
        var configuration: Configuration?
        if path.exists {
            let yamlParser = YamlParser(logger: logger)
            configuration = try yamlParser.extractConfiguration(from: path)
        } else {
            logger.logInfo("⚠️  ", item: """
                We couldn't find a YAML spec. Please provide the details below.

                """)
            configuration = userInputHelper.configurationFromUserInput()
        }
        
        let encoder = YAMLEncoder()
        let encoded = try encoder.encode(configuration)
        logger.logDebug("Loaded configuration:", item: "")
        logger.logDebug(
            item: """

            \(encoded)
            """,
            color: .purple
        )
        
        return configuration
    }
    
    let coherentSwiftSpecPath = Path("./coherent-swift.yml")
    let templatePath: Path
    let logger: Logger
    let userInputHelper: UserInputHelper
}
