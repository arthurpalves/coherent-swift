//
//  CoherentSwift
//

import Foundation
import PathKit

public class LocalFileManager: ReportFactory {
    public var reportsPath: Path = Path("./")
    public var badgeFilePath: Path = Path("coherent-badge.json")
    static let shared = LocalFileManager()
}
