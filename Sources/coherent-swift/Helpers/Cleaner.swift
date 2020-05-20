//
//  File.swift
//  
//
//  Created by Arthur Alves on 20/05/2020.
//

import Foundation

class Cleaner {
    static let shared = Cleaner()
    
    func cleanMethodName(_ name: String) -> String {
        guard let cleanSubstring = name.split(separator: "(").first
        else { return name }
        return String(cleanSubstring)
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
            .replacingOccurrences(of: " ", with: "")
        
        guard
            let substringNoColons = cleanString.split(separator: ":").first,
            let substringNoClosure = String(substringNoColons).split(separator: "=").first,
            let finalString = String(substringNoClosure).split(separator: " ").first
        else { return nil }
        return String(finalString)
    }
}
