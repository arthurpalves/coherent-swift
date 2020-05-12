//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation

public class LocalFileManager: ReportGenerator {
    public var reports_path: String = ""
    public var badge_file: String = "coherent-badge.json"
    static let shared = LocalFileManager()
}
