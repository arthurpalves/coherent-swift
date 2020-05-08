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
    var cohesion: String
    var properties: [ReportProperty]
    var methods: [ReportMethod]
    
    init(name: String, cohesion: String = "", properties: [ReportProperty] = [], methods: [ReportMethod] = []) {
        self.name = name
        self.cohesion = cohesion
        self.properties = properties
        self.methods = methods
    }
}

public struct ReportMethod: Codable {
    let name: String
    var cohesion: String
    var properties: [ReportProperty]
    
    init(name: String, cohesion: String = "", properties: [ReportProperty] = []) {
        self.name = name
        self.cohesion = cohesion
        self.properties = properties
    }
}

public struct ReportProperty: Codable {
    let name: String
}
