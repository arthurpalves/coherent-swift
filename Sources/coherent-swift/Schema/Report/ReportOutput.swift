//
//  coherent-swift
//
//  Created by Arthur Alves on 06/05/2020.
//

import Foundation

public struct ReportOutput: Codable {
    var source: String = ""
    var minimum_threshold: String = ""
    var meets_threshold: Bool = false
    var report_date: String = ""
    var cohesion: String = ""
    var result: [CohesionReport] = []
    
    mutating func appendReport(_ report: CohesionReport) {
        result.append(report)
    }
}
