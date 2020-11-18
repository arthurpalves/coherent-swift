//
//  CoherentSwift
//

import Foundation
import PathKit

public struct TemplateDirectory {
    public var path: Path

    public init(
        directories: [String] = [
            "/usr/local/lib/coherent-swift/templates",
            "./Templates"
        ]
    ) throws {
        let firstDirectory = directories
            .map(Path.init(stringLiteral:))
            .first(where: \.exists)

        guard let path = firstDirectory else {
            let dirs = directories.joined(separator: " or ")
            throw RuntimeError("❌ Templates folder not found in \(dirs)")
        }

        self.path = path
    }

    public init(path: Path) {
        self.path = path
    }
}
