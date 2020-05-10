//
//  coherent-swift
//
//  Created by Arthur Alves on 08/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

typealias ParsedItem = (item: String, range: NSRange)

public class SwiftParser {
    let logger = Logger.shared
    static let shared = SwiftParser()
    
    func parseFile(filename: String, in path: Path, onSucces: (([ReportDefinition]) -> Void)? = nil) {
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
                
                logger.logDebug("Cohesion: ", item: method.cohesion+"%%", indentationLevel: 3, color: .cyan)
            }
            logger.logDebug("Cohesion: ", item: $0.cohesion, indentationLevel: 2, color: .cyan)
        }
        
        onSucces?(classes)
    }
    
    func method(_ method: ReportMethod, containsProperty property: ReportProperty, numberOfOccasions: Int = 1) -> Bool {
        let range = NSRange(location: 0, length: method.contentString.utf16.count)
        let regex = try! NSRegularExpression(pattern: property.name)
        let matches = regex.matches(in: method.contentString, range: range)
        return matches.count >= numberOfOccasions
    }
    
    // MARK: - Private methods
    
    private func parseDefinition(stringContent: String) -> [ReportDefinition] {
        var definitions: [ReportDefinition] = []
    
        let parseType: ParseType = .definition
        
        let rawDefinitions = parseSwift(stringContent: stringContent, type: parseType)
        if rawDefinitions.isEmpty { return [] }
        
        for iterator in 0...rawDefinitions.count-1 {
            let definitionName = rawDefinitions[iterator].item
            var definition: ReportDefinition = ReportDefinition(name: definitionName)
            
            let delimiter = iterator+1 > rawDefinitions.count-1 ? "\\}" : "(\(parseType.regex())) \(rawDefinitions[iterator+1].item)"
            let regexPattern = "(?s)(?<=\(definitionName)).*(?=\(delimiter))"
            
            if let range = stringContent.range(of: regexPattern, options: .regularExpression) {
                let definitionContent = String(stringContent[range])
                
                definition.properties = parseSwiftProperties(stringContent: definitionContent)
                definition.methods = parseSwiftMethod(stringContent: definitionContent, withinDefinition: definition)
                
                var cohesion: Double = 0
                if !definition.methods.isEmpty {
                    cohesion = Cohesion.main.generateCohesion(for: definition)
                    
                } else {
                    /*
                     * if a definition doesn't contain properties nor methods, its
                     * still considered to have high cohesion
                     */
                    cohesion = 100
                }
                definition.cohesion = cohesion.formattedCohesion()
            }
            definitions.append(definition)
        }
        
        return definitions
    }
    
    private func parseSwiftProperties(stringContent: String) -> [ReportProperty] {
        var properties: [ReportProperty] = []
        let rawProperties = parseSwift(stringContent: stringContent, type: .property)
        properties = rawProperties.map { ReportProperty(name: $0.item) }
        return properties
    }
    
    private func parseSwiftMethod(stringContent: String, withinDefinition definition: ReportDefinition) -> [ReportMethod] {
        var methods: [ReportMethod] = []
        let rawMethods = parseSwift(stringContent: stringContent, type: .method)
        
        if rawMethods.isEmpty { return [] }
        
        for iterator in 0...rawMethods.count-1 {
            let methodName = rawMethods[iterator].item
            let processedForRegex = processedMethodName(methodName)
            
            var method: ReportMethod = ReportMethod(name: methodName)
            let delimiter = iterator+1 > rawMethods.count-1 ? "\\}" : "\(ParseType.method.regex())"
            let regexPattern = "(?s)(?<=\(processedForRegex)).*(\(delimiter))"
            
            if let range = stringContent.range(of: regexPattern, options: .regularExpression) {
                let methodContent = String(stringContent[range])
                method.contentString = methodContent
                method.properties = parseSwiftProperties(stringContent: methodContent)
                
                let methodCohesion = Cohesion.main.generateCohesion(for: method, withinDefinition: definition)
                method.cohesion = methodCohesion.formattedCohesion()
            }
            
            methods.append(method)
        }
        return methods
    }
    
    private func parseSwift(stringContent: String, type: ParseType) -> [ParsedItem] {
        let range = NSRange(location: 0, length: stringContent.utf16.count)
        let regex = try! NSRegularExpression(pattern: "(?<=\(type.regex()) )(.*)(\(type.delimiter()))")
        var parsedItems: [ParsedItem] = []
        
        switch type {
        case .property:
            propertyLineParsing(stringContent: stringContent).forEach {
                parsedItems.append($0)
            }
        default:
            let matches = regex.matches(in: stringContent, range: range)
            
            processParsedItems(with: matches, in: stringContent, type: type).forEach {
                parsedItems.append($0)
            }
        }
        return parsedItems
    }
    
    private func propertyLineParsing(stringContent: String) -> [ParsedItem] {
        var parsedItems: [ParsedItem] = []
        let regex = try! NSRegularExpression(pattern: "(?<=\(ParseType.property.regex()) )(.*)(\(ParseType.property.delimiter()))")
        var dictionaryContent: [String] = []
        
        stringContent.enumerateLines { (line, _) in
            dictionaryContent.append(line)
        }
        
        for lineCount in 0...dictionaryContent.count-1 {
            let lineContent = dictionaryContent[lineCount]
            
            let methodRegex = try! NSRegularExpression(pattern: "(?<=\(ParseType.method.regex()) )(.*)(\(ParseType.method.delimiter()))")
            let range = NSRange(location: 0, length: lineContent.utf16.count)

            let methodMatches = methodRegex.matches(in: lineContent, range: range)
            if !methodMatches.isEmpty { break }
            
            let matches = regex.matches(in: lineContent, range: range)
            
            processParsedItems(with: matches, in: lineContent, type: .property).forEach {
                parsedItems.append($0)
            }
        }
        
        return parsedItems
    }
    
    private func processParsedItems(with regexMatches: [NSTextCheckingResult], in contentString: String, type: ParseType) -> [ParsedItem] {
        var parsedItems: [ParsedItem] = []
        
        regexMatches.forEach { match in
            if let range = Range(match.range, in: contentString) {
                
                switch type {
                case .method:
                    guard
                        let methodSubstring = String(contentString[range]).split(separator: "{").first
                        else { return }
                    let finalString = String(methodSubstring).trimmingCharacters(in: [" "])
                    parsedItems.append((item: finalString, range: match.range))
                default:
                    guard
                        let substringNoColons = String(contentString[range]).split(separator: ":").first,
                        let finalString = String(substringNoColons).split(separator: " ").first
                        else { return }
                    parsedItems.append((item: String(finalString), range: match.range))
                }
            }
        }
        return parsedItems
    }
    
    private func processedMethodName(_ name: String) -> String {
        guard let cleanSubstring = name.split(separator: "(").first
        else { return name }
        return String(cleanSubstring)
    }
}
