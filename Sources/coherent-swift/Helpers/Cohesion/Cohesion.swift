//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation
import SwiftSyntax

public class Measurer {
    static let shared = Measurer()
    let parser = SwiftParser()
    
    func generateCohesion(for method: ReportMethod, withinDefinition definition: ReportDefinition) -> Double {
        var shouldProcessParentProperties = true
        let parentProperties = definition.properties.filter { $0.propertyType != .classProperty }
        
        var containsPropertyCount = 0
        var combinedPropertyCount = method.properties.count
        if !parentProperties.isEmpty {
            shouldProcessParentProperties = true
            combinedPropertyCount = (parentProperties + method.properties).count
        }
        
        guard combinedPropertyCount > 0 else { return Double(100) }
        
        if shouldProcessParentProperties {
            parentProperties.forEach {
                containsPropertyCount += parser.method(method, containsProperty: $0)
                    ? 1
                    : 0
            }
        }
        
        method.properties.forEach {
            containsPropertyCount += parser.method(method, containsProperty: $0, numberOfOccasions: 2)
                ? 1
                : 0
        }
        
        return (Double(containsPropertyCount) / Double(combinedPropertyCount)) * Double(100)
    }
}

public class Cohesion {
    let parser = SwiftParser()
    static let main = Cohesion()
    
    func generateCohesion(for method: ReportMethod, withinDefinition definition: ReportDefinition) -> Double {
        var shouldProcessParentProperties = true
        let parentProperties = definition.properties.filter { $0.propertyType != .classProperty }
        
        var containsPropertyCount = 0
        var combinedPropertyCount = method.properties.count
        if !parentProperties.isEmpty {
            shouldProcessParentProperties = true
            combinedPropertyCount = (parentProperties + method.properties).count
        }
        
        guard combinedPropertyCount > 0 else { return Double(100) }
        
        if shouldProcessParentProperties {
            parentProperties.forEach {
                containsPropertyCount += parser.method(method, containsProperty: $0)
                    ? 1
                    : 0
            }
        }
        
        method.properties.forEach {
            containsPropertyCount += parser.method(method, containsProperty: $0, numberOfOccasions: 2)
                ? 1
                : 0
        }
        
        return (Double(containsPropertyCount) / Double(combinedPropertyCount)) * Double(100)
    }
    
    func generateCohesion(for definition: ReportDefinition) -> Double {
        let methodsCount = definition.methods.count
        let accumulatedCohesion = definition.methods
            .compactMap { Double(input: $0.cohesion) }
            .reduce(0) { $0 + $1 }
        return accumulatedCohesion / Double(methodsCount)
    }
    
    func generateCohesion(for definitions: [ReportDefinition]) -> Double {
        let definitionsCount = definitions.count
        let accumulatedCohesion = definitions
            .compactMap { Double(input: $0.cohesion) }
            .reduce(0) { $0 + $1 }
        return accumulatedCohesion / Double(definitionsCount)
    }
}
