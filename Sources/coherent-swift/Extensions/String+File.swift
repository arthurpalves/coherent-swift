//
//  coherent-swift
//
//  Created by Arthur Alves on 22/05/2020.
//

import Foundation
import PathKit

extension String {
    func appendLine(to file: Path) throws {
        try (self + "\n").appendToURL(fileURL: file.url)
    }
    
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        var data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
