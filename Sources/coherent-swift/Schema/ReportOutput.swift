//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation

public struct ReportOutput: Codable {
    var source: String = ""
    var minimum_threshold: String = ""
    var report_date: String = ""
    var cohesion: String = ""
    var result: [IndividualReport] = []
    
    mutating func appendReport(_ report: IndividualReport) {
        result.append(report)
    }
}

public struct IndividualReport: Codable {
    let file: String
    let cohesion: String
    let meets_threshold: Bool
    let classes: [ReportClass]?
}

public struct ReportClass: Codable {
    let name: String
    let cohesion: String
    let methods: [ReportMethod]
}

public struct ReportMethod: Codable {
    let name: String
    let cohesion: String
    let properties: [ReportProperties]
}

public struct ReportProperties: Codable {
    let name: String
    let present: Bool
}
