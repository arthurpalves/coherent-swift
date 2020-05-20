//
//  coherent-swift
//
//  Created by Arthur Alves on 20/05/2020.
//

import Foundation

typealias DefinitionTuple = (name: String, content: String)

class InlineParser {
    static let shared = InlineParser()
    
    func parseFileContent(_ fileContent: String) -> [DefinitionTuple] {
        let definitionPrefixes = ["class ", "struct ","extension "]
        var rawDefinitions: [DefinitionTuple] = []
        
        let cleanFileContent = excludeCodeComments(from: fileContent)
        
        /*
         * Operands for the line parser
         */
        var openBracketCount = 0
        var definitionTemporaryContent = ""
        var definitionTemporaryName = ""
        
        /*
         * RegEx for finding a definition
         */
        let pattern = "(?<=\(ParseType.definition.regex()) )(.*)(\(ParseType.definition.delimiter()))"
        
        guard let regex = try? NSRegularExpression(pattern: pattern)
        else { return rawDefinitions }
        
        /*
         * Iterate over every line to determine which blocks
         * are definitions and their content
         */
        cleanFileContent.enumerateLines { (line, _) in
            
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if definitionPrefixes.contains(where: line.contains) {
                let matches = regex.matches(in: line, range: range)
                
                if
                    let firstMatch = matches.first,
                    let firstMarchRange = Range(firstMatch.range, in: line) {
                    
                    let rawDefinitionName = String(line[firstMarchRange])
                    if definitionTemporaryName.isEmpty, !matches.isEmpty {
                        openBracketCount += 1
                        definitionTemporaryName = rawDefinitionName
                    }
                    
                    let remainingNSRange = NSRange(location: firstMatch.range.location,
                                                   length: line.utf16.count-firstMatch.range.location)
                    if let remainingRange = Range(remainingNSRange, in: line) {
                        let remainingLine = String(line[remainingRange])

                        remainingLine.forEach { (char) in
                            if char == "{", openBracketCount > 1 { openBracketCount += 1 }
                            else if char == "}" { openBracketCount -= 1 }

                            if openBracketCount == 0 {
                                rawDefinitions.append((name: definitionTemporaryName,
                                                           content: definitionTemporaryContent))
                                definitionTemporaryName = ""
                                definitionTemporaryContent = ""
                            } else { definitionTemporaryContent.append(char) }
                        }
                        definitionTemporaryContent.append("\n")
                    }
                }
            } else if !definitionTemporaryName.isEmpty {
                line.forEach { (char) in
                    if char == "{" { openBracketCount += 1 }
                    else if char == "}" { openBracketCount -= 1 }

                    if openBracketCount == 0 {
                        rawDefinitions.append((name: definitionTemporaryName,
                                                   content: definitionTemporaryContent))
                        definitionTemporaryName = ""
                        definitionTemporaryContent = ""
                    } else { definitionTemporaryContent.append(char) }
                }
                definitionTemporaryContent.append("\n")
            }
        }
        
        return rawDefinitions
    }
    
    // MARK: - Private methods
    
    private func excludeCodeComments(from content: String) -> String {
        let range = NSRange(location: 0, length: content.utf16.count)
        let pattern = "(/\\*(.|\n)*?\\*/|//(.*?)\r?\n|@(\"[^\"]*\")+)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern)
        else { return content }
        
        var cleanContent = content
        let matches = regex.matches(in: content, range: range)
        matches.forEach { match in
            if let range = Range(match.range, in: content) {
                let commentedCode = String(content[range])
                cleanContent = cleanContent.replacingOccurrences(of: commentedCode, with: "")
            }
        }
        return cleanContent
    }
}
