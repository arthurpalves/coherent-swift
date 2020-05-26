//
//  coherent-swift
//
//  Created by Arthur Alves on 08/05/2020.
//

import Foundation
import PathKit
import SwiftCLI

typealias ParsedItem = (item: String, range: NSRange, type: String)

public class SwiftParser {
    let logger = Logger.shared
    let inlineParser = InlineParser.shared
    let cleaner = Cleaner.shared
    
    static let shared = SwiftParser()
    
    func parseFile(filename: String, in path: Path, onSucces: (([ReportDefinition]) -> Void)? = nil) {
        let fileManager = FileManager.default
        let filePath = Path("\(path)/\(filename)")
        let fileData = fileManager.contents(atPath: filePath.absolute().description)
        
        guard
            let data = fileData,
            let string = String(data: data, encoding: .utf8),
            !string.isEmpty
        else { return }
        
        let definitions = inlineParser.parseFileContent(string)
        let classes: [ReportDefinition] = parseDefinitions(rawDefinitions: definitions)
        
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
            logger.logDebug("Cohesion: ", item: $0.cohesion+"%%", indentationLevel: 2, color: .cyan)
        }
        
        onSucces?(classes)
    }
    
    func content(_ contentString: String, hasOccuranceOf name: String, numberOfOccasions: Int = 1) -> Bool {
        let range = NSRange(location: 0, length: contentString.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: name) else { return false }
        let matches = regex.matches(in: contentString, range: range)
        return matches.count >= numberOfOccasions
    }
    
    // MARK: - Private methods
    
    private func parseDefinitions(rawDefinitions: [DefinitionTuple]) -> [ReportDefinition] {
        var definitions: [ReportDefinition] = []
    
        rawDefinitions.forEach { (rawDefinition) in
            var definition: ReportDefinition = ReportDefinition(name: rawDefinition.name)
            definition.contentString = rawDefinition.content
            
            definition.properties = parseSwiftProperties(stringContent: rawDefinition.content)
            definition.methods = parseSwiftMethod(stringContent: rawDefinition.content, withinDefinition: definition)
            
            var cohesion: Double = 0
            if !definition.methods.isEmpty {
                cohesion = Cohesion.main.generateCohesion(for: definition)
            } else {
                /*
                 * if a definition doesn't contain properties nor methods, its
                 * still considered as highly cohesive
                 */
                cohesion = 100
            }
            definition.cohesion = cohesion.formattedCohesion()
            definitions.append(definition)
        }
        return definitions
    }
    
    private func parseSwiftProperties(stringContent: String) -> [ReportProperty] {
        var properties: [ReportProperty] = []
        let rawProperties = parseSwift(stringContent: stringContent, type: .property)
        properties = rawProperties.map { ReportProperty(name: $0.item,
                                                        propertyType: PropertyType(rawValue: $0.type) ?? .instanceProperty) }
        return properties
    }
    
    private func parseSwiftMethod(stringContent: String, withinDefinition definition: ReportDefinition) -> [ReportMethod] {
        var methods: [ReportMethod] = []
        let rawMethods = parseSwift(stringContent: stringContent, type: .method)
        if rawMethods.isEmpty { return [] }

        for iterator in 0...rawMethods.count-1 {
            let methodName = rawMethods[iterator].item
            let processedForRegex = cleaner.cleanMethodName(methodName)
            
            var method: ReportMethod = ReportMethod(name: methodName, methodType: MethodType(rawValue: rawMethods[iterator].type) ?? .publicMethod)
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
        var parsedItems: [ParsedItem] = []
        switch type {
        case .definition:
            break
        default:
            lineParsing(stringContent: stringContent, type: type).forEach {
                parsedItems.append($0)
            }
        }
        return parsedItems
    }
    
    private func lineParsing(stringContent: String, type: ParseType) -> [ParsedItem] {
        var parsedItems: [ParsedItem] = []
        
        let pattern = "(?<=\(type.regex()) )(.*)(\(type.delimiter()))"
        guard let regex = try? NSRegularExpression(pattern: pattern)
        else {
            logger.logError("Couldn't create NSRegularExpression with: ", item: pattern)
            return parsedItems
        }
        
        var dictionaryContent: [String] = []
        stringContent.enumerateLines { (lineContent, _) in dictionaryContent.append(lineContent) }

        let methodType = ParseType.method
        let methodPattern = "(?<=\(methodType.regex()) )(.*)(\(methodType.delimiter()))"
        guard let methodRegex = try? NSRegularExpression(pattern: methodPattern)
        else {
            logger.logError("Couldn't create NSRegularExpression with: ", item: methodPattern)
            return parsedItems
        }
        
        for lineCount in 0...dictionaryContent.count-1 {
            let lineContent = dictionaryContent[lineCount]
            let range = NSRange(location: 0, length: lineContent.utf16.count)

            if
                type == .property,
                !methodRegex.matches(in: lineContent, range: range).isEmpty {
                break
            }

            let matches = regex.matches(in: lineContent, range: range)
            processParsedItems(with: matches, in: lineContent, type: type).forEach {
                parsedItems.append($0)
            }
        }
        
        return parsedItems
    }
    
    private func processParsedItems(with regexMatches: [NSTextCheckingResult], in contentString: String, type: ParseType) -> [ParsedItem] {
        var parsedItems: [ParsedItem] = []
        regexMatches.forEach { match in
            if let range = Range(match.range, in: contentString) {
                var finalType = ""
                switch type {
                case .method:
                    guard
                        let methodSubstring = String(contentString[range]).split(separator: "{").first
                        else { return }
                    let finalString = String(methodSubstring).trimmingCharacters(in: [" "])
                    
                    let methodType = Labeler.shared.methodType(String(methodSubstring), lineContent: contentString)
                    parsedItems.append((item: finalString, range: match.range, type: methodType.rawValue))
                    
                case .property:
                    finalType = PropertyType.instanceProperty.rawValue
                    if contentString.contains(PropertyType.classProperty.rawValue) {
                        finalType = PropertyType.classProperty.rawValue
                    }
                    
                    var propertiesInLine: [String] = []
                    if contentString.contains("let (") || contentString.contains("var (") {
                        propertiesInLine = cleaner.cleanTuple(in: String(contentString[range]))
                    } else if let processedPropertyName = cleaner.cleanPropertyName(in: String(contentString[range])) {
                        propertiesInLine.append(processedPropertyName)
                    }
                    
                    propertiesInLine.forEach { property in
                        parsedItems.append((item: property, range: match.range, type: finalType))
                    }
                    
                default:
                    finalType = type.rawValue
                    guard
                        let substringNoColons = String(contentString[range]).split(separator: ":").first,
                        let finalString = String(substringNoColons).split(separator: " ").first
                    else { return }
                    parsedItems.append((item: String(finalString), range: match.range, type: finalType))
                }
            }
        }
        return parsedItems
    }
}
