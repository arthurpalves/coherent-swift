//
//  CoherentSwift
//

import Foundation
import PathKit

func readSTDIN() -> String? {
    var input: String?
    input = readLine()
    return input
}

public class SpecHelper {
    public init(
        templatePath: Path = Path("coherent-swift-template.yml"),
        logger: Logger = Logger.shared
    ) {
        self.templatePath = templatePath
        self.logger = logger
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
            if !shouldOverrideSpec(input: nil) {
                return
            } else {
                try coherentSwiftSpecPath.delete()
            }
        }
        try sourcePath.copy(coherentSwiftSpecPath)
        logger.logInfo("📝  ", item: "CoherentSwift spec generated with success at path '\(coherentSwiftSpecPath)'")
    }

    func shouldOverrideSpec(input: String?) -> Bool {
        let userResponse = input ?? ""
        if ["y", "yes".lowercased()].contains(userResponse.lowercased()) {
            return true
        } else if ["n", "no".lowercased()].contains(userResponse.lowercased()) {
            return false
        }
        logger.logInfo("⚠️  ", item: "'\(coherentSwiftSpecPath)' already exists! Should we override it?")
        logger.logInfo("[Y]yes / [N]no", item: "")
        return shouldOverrideSpec(input: readSTDIN())
    }
    
    let coherentSwiftSpecPath = Path("./coherent-swift.yml")
    let templatePath: Path
    let logger: Logger
}
