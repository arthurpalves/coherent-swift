//
//  File.swift
//  
//
//  Created by Arthur Alves on 20/05/2020.
//

import Foundation

class Cleaner {
    static let shared = Cleaner()
    
    func simpleMethodName(_ name: String) -> String {
        guard let cleanSubstring = name.split(separator: "(").first
        else { return name }
        return String(cleanSubstring)
    }
    
    func methodName(_ name: String) -> String {
        var finalName = ""
        name.enumerateLines(invoking: { (line, _) in
            let newLine = line
                .trimmingCharacters(in: [" "])
                .replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "\n", with: "")
            finalName.append(newLine)
            finalName.append(" ")
        })
        return finalName
    }
    
    func cleanTuple(in contentString: String) -> [String] {
        let cleanString = contentString
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "=", with: "")
        guard
            let substringNoColons = cleanString.split(separator: ":").first
        else { return [] }
        
        let allStrings = String(substringNoColons).split(separator: ",")
        return allStrings.map { String($0) }
    }
    
    func cleanPropertyName(in contentString: String) -> String? {
        let cleanString = contentString
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        guard
            let substringNoColons = cleanString.split(separator: ":").first,
            let substringNoClosure = String(substringNoColons).split(separator: "=").first,
            let finalString = String(substringNoClosure).split(separator: " ").last
        else { return nil }
        return String(finalString)
    }
}
