//
//  coherent-swift
//
//  Created by Arthur Alves on 08/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

public class SwiftParser {
    let logger = Logger.shared
    static let shared = SwiftParser()
    
    func parseFile(filename: String, in path: Path, onSucces: (([ReportClass]) -> Void)? = nil) {
        let fileManager = FileManager.default
        let filePath = Path("\(path)/\(filename)")
        let fileData = fileManager.contents(atPath: filePath.absolute().description)
        
        guard
            let data = fileData,
            let stringData = String(data: data, encoding: .utf8),
            !stringData.isEmpty
        else { return }
        
        let classes = parseDefinition(stringContent: stringData)
        classes.forEach {
            logger.logDebug("Definition: ", item: $0.name, indentationLevel: 1, color: .cyan)
            $0.properties.forEach { (property) in
                logger.logDebug("Property: ", item: property.name, indentationLevel: 2, color: .cyan)
            }
            $0.methods.forEach { (method) in
                logger.logDebug("Method: ", item: method.name, indentationLevel: 2, color: .cyan)
                
                method.properties.forEach { (property) in
                    logger.logDebug("Property: ", item: property.name, indentationLevel: 3, color: .cyan)
                }
                
                logger.logDebug("Cohesion: ", item: method.cohesion, indentationLevel: 3, color: .cyan)
            }
            logger.logDebug("Cohesion: ", item: $0.cohesion, indentationLevel: 2, color: .cyan)
        }
        
        onSucces?(classes)
    }
    
    private func parseDefinition(stringContent: String) -> [ReportClass] {
        var finalDefinitions: [ReportClass] = []
        
        let type: ParseType = .definition
        let definitions = parseSwift(stringContent: stringContent, type: type)
        
        for iterator in 0...definitions.count-1 {
            let currentDefinition = definitions[iterator].item
            
            var reportDefinition: ReportClass = ReportClass(name: currentDefinition)
            let nextDefinition = iterator+1 > definitions.count-1 ? "\\}" : "(\(type.regex())) \(definitions[iterator+1].item)"

            let pattern = "(?s)(?<=\(currentDefinition)).*(?=\(nextDefinition))"
            if let range = stringContent.range(of: pattern, options: .regularExpression) {
                let text = String(stringContent[range])
                
                print("Class: \(text)")
                
                let methods = parseSwift(stringContent: text, type: .method)
                reportDefinition.methods = methods.map { ReportMethod(name: $0.item) }
                
                var tempProperties: [String: [ReportProperty]] = [:]
                methods.forEach { method in
                    
                    let internalRange = NSRange(location: method.range.location+method.range.length, length: stringContent.utf16.count-method.range.location)
                    
                    let start = String.Index(encodedOffset: method.range.location+method.range.length)
                    let end = String.Index(encodedOffset: stringContent.utf16.count-method.range.location)
                    let temporaryContent = String(stringContent[start..<end])

                    let internalP = parseSwift(stringContent: temporaryContent, type: .property)
                    let rProperty = internalP.map { ReportProperty(name: $0.item) }

                    tempProperties[method.item] = rProperty
                }
                
                for (index, _) in reportDefinition.methods.enumerated() {
                    print("Method: \(reportDefinition.methods[index].name), properties: \(tempProperties[reportDefinition.methods[index].name])")
                    reportDefinition.methods[index].properties = tempProperties[reportDefinition.methods[index].name] ?? []
                }
                
                let properties = parseSwift(stringContent: text, type: .property)
                reportDefinition.properties = properties.map { ReportProperty(name: $0.item) }
            }
            finalDefinitions.append(reportDefinition)
        }
        
        return finalDefinitions
    }
    
    private func parseMethods() -> [ReportMethod] {
        return []
    }
    
    private func parseSwift(stringContent: String, type: ParseType, specialRange: NSRange? = nil) -> [(item: String, range: NSRange)] {
        let range = specialRange ?? NSRange(location: 0, length: stringContent.utf16.count)
        let delimiter = type.delimiter()
        
        let regex = try! NSRegularExpression(pattern: "(?<=\(type.regex()) )(.*)(\(delimiter))")
        
        var finalResults: [(item: String, range: NSRange)] = []
        
        if specialRange == nil && delimiter == ParseType.property.delimiter() {
            var shouldKeepLooking = true
            
            var allLines: [String] = []
            stringContent.enumerateLines { (line, _) in
                allLines.append(line)
            }
            
            for line in 0...allLines.count-1 {
                let codeLine = allLines[line]
                
                let innerRegex = try! NSRegularExpression(pattern: "(?<=\(ParseType.method.regex()) )(.*)(\(ParseType.method.delimiter()))")
                let innerRange = NSRange(location: 0, length: codeLine.utf16.count)

                let tempResults = innerRegex.matches(in: codeLine, range: innerRange)
                shouldKeepLooking = tempResults.isEmpty
                
                if !shouldKeepLooking { break }
                
                let innerResults = regex.matches(in: codeLine, range: innerRange)
                innerResults.forEach { result in
                    if
                        let range = Range(result.range, in: codeLine),
                        let substring = String(codeLine[range]).split(separator: ":").first,
                        let finalSubstring = String(substring).split(separator: " ").first {
                        
                        finalResults.append((item: String(finalSubstring), range: result.range))
                    }
                }
            }
            
        } else {
            let results = regex.matches(in: stringContent, range: range)
            results.forEach { result in
                if
                    let range = Range(result.range, in: stringContent),
                    let substring = String(stringContent[range]).split(separator: ":").first,
                    let finalSubstring = String(substring).split(separator: " ").first {
                    
                    finalResults.append((item: String(finalSubstring), range: result.range))
                }
            }
            
        }
        return finalResults
    }
}


//public extension NSRange {
//    private init(string: String, lowerBound: String.Index, upperBound: String.Index) {
//        let utf16 = string.utf16
//
//        let lowerBound = lowerBound.samePosition(in: utf16)
//        let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
//        let length = utf16.distance(from: lowerBound, to: upperBound.samePosition(in: utf16))
//
//        self.init(location: location, length: length)
//    }
//
//    init(range: Range<String.Index>, in string: String) {
//        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
//    }
//
//    init(range: ClosedRange<String.Index>, in string: String) {
//        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
//    }
//}
