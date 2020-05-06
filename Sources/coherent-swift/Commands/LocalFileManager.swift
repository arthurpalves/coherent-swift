//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation

public class LocalFileManager: ReportGenerator {
    public var reports_path: String = ""
    static let shared = LocalFileManager()
}
