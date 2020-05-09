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
                
                logger.logDebug("Cohesion: ", item: method.cohesion, indentationLevel: 3, color: .cyan)
            }
            logger.logDebug("Cohesion: ", item: $0.cohesion, indentationLevel: 2, color: .cyan)
        }
        
        onSucces?(classes)
    }
    
    private func parseDefinition(stringContent: String) -> [ReportDefinition] {
        var definitions: [ReportDefinition] = []
    
        let parseType: ParseType = .definition
        
        let rawDefinitions = parseSwift(stringContent: stringContent, type: parseType)
        for iterator in 0...rawDefinitions.count-1 {
            let definitionName = rawDefinitions[iterator].item
            var definition: ReportDefinition = ReportDefinition(name: definitionName)
            
            let delimiter = iterator+1 > rawDefinitions.count-1 ? "\\}" : "(\(parseType.regex())) \(rawDefinitions[iterator+1].item)"
            let regexPattern = "(?s)(?<=\(definitionName)).*(?=\(delimiter))"
            
            if let range = stringContent.range(of: regexPattern, options: .regularExpression) {
                let definitionContent = String(stringContent[range])
                
                definition.properties = parseSwiftProperties(stringContent: definitionContent)
                definition.methods = parseSwiftMethod(stringContent: definitionContent, definitionProperties: definition.properties)
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
    
    private func parseSwiftMethod(stringContent: String, definitionProperties: [ReportProperty]) -> [ReportMethod] {
        var methods: [ReportMethod] = []
        let rawMethods = parseSwift(stringContent: stringContent, type: .method)
        
        if rawMethods.isEmpty { return [] }
        
        for iterator in 0...rawMethods.count-1 {
            let methodName = rawMethods[iterator].item
            var method: ReportMethod = ReportMethod(name: methodName)
            let delimiter = iterator+1 > rawMethods.count-1 ? "\\}" : "\(ParseType.method.regex())"
            let regexPattern = "(?s)(?<=\(methodName)).*(\(delimiter))"
            
            if let range = stringContent.range(of: regexPattern, options: .regularExpression) {
                let methodContent = String(stringContent[range])
                method.properties = parseSwiftProperties(stringContent: methodContent)
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
            
            processParsedItems(with: matches, in: stringContent).forEach {
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
            
            processParsedItems(with: matches, in: lineContent).forEach {
                parsedItems.append($0)
            }
        }
        
        return parsedItems
    }
    
    private func processParsedItems(with regexMatches: [NSTextCheckingResult], in contentString: String) -> [ParsedItem] {
        var parsedItems: [ParsedItem] = []
        
        regexMatches.forEach { match in
            if
                let range = Range(match.range, in: contentString),
                let substringNoColons = String(contentString[range]).split(separator: ":").first,
                let substringNoSpaces = String(substringNoColons).split(separator: " ").first {
                
                parsedItems.append((item: String(substringNoSpaces), range: match.range))
            }
        }
        return parsedItems
    }
}
