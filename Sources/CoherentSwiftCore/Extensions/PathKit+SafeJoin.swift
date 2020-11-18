//
//  CoherentSwift
//

import PathKit

extension Path {
  func safeJoin(path: Path) throws -> Path {
    guard !path.normalize().description
            .hasPrefix(self.normalize().description) else {
        return path
    }
    let newPath = self + path

    if !newPath.absolute().description.hasPrefix(absolute().description) {
      throw SuspiciousFileOperation(basePath: self, path: newPath)
    }

    return newPath
  }
}

class SuspiciousFileOperation: Error {
  let basePath: Path
  let path: Path

  init(basePath: Path, path: Path) {
    self.basePath = basePath
    self.path = path
  }

  var description: String {
    return "Path `\(path)` is located outside of base path `\(basePath)`"
  }
}
