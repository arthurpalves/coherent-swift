//
//  coherent-swift
//
//  Created by Arthur Alves on 09/05/2020.
//

import Foundation

public class Cohesion {
    let parser = SwiftParser()
    static let main = Cohesion()
    
    func generateCohesion(for method: ReportMethod,
                          withinDefinition definition: ReportDefinition) -> Double {
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
                containsPropertyCount += parser.content(method.contentString,
                                                        hasOccuranceOf: $0.name)
                    ? 1 : 0
            }
        }
        
        method.properties.forEach {
            containsPropertyCount += parser.content(method.contentString,
                                                    hasOccuranceOf: $0.name,
                                                    numberOfOccasions: 2)
                ? 1 : 0
        }
        
        return (Double(containsPropertyCount) / Double(combinedPropertyCount)) * Double(100)
    }
    
    func generateCohesion(for definition: ReportDefinition) -> Double {
        let methodsCount = definition.methods.count
        let accumulatedCohesion = definition.methods
            .compactMap { Double(input: $0.cohesion) }
            .reduce(0) { $0 + $1 }
        
        let accumulatedMethodsCohesion = accumulatedCohesion / Double(methodsCount)
        
        let privateMethods = definition.methods.filter { $0.methodType == .privateMethod }
        guard !privateMethods.isEmpty
        else { return accumulatedMethodsCohesion }
        /*
         * If private methods exist within this definition
         * the usage of this method contributes to the overall
         * cohesion.
         *
         * - This method is then added to the usage count.
         * - It's cohesion can be either 100 or 0, used or not.
         */
        var privateMethodsCohesion: Double = 0
        privateMethods.forEach { (privateMethod) in
            privateMethodsCohesion += parser.content(definition.contentString,
                                                     hasOccuranceOf: Cleaner.shared.cleanMethodName(privateMethod.name),
                                                     numberOfOccasions: 2)
                ? 100 : 0
        }
        
        return (privateMethodsCohesion + accumulatedMethodsCohesion) / (Double(privateMethods.count)+1)
    }
    
    func generateCohesion(for definitions: [ReportDefinition]) -> Double {
        let definitionsCount = definitions.count
        let accumulatedCohesion = definitions
            .compactMap { Double(input: $0.cohesion) }
            .reduce(0) { $0 + $1 }
        return accumulatedCohesion / Double(definitionsCount)
    }
}
