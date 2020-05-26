//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation

class Labeler {
    static let shared = Labeler()
    
    func methodType(_ name: String, lineContent: String) -> MethodType {
        let methodsCleanName = Cleaner.shared.cleanMethodName(name)
        var methodType: MethodType = .publicMethod
        let lineItems = lineContent
            .replacingOccurrences(of: "\t", with: "")
            .split(separator: " ")
        
        for item in lineItems {
            if methodsCleanName.contains(item) { break }
            if let type = MethodType(rawValue: String(item)) {
                methodType = type
                break
            }
        }
        return methodType
    }
    
    func printColor(for cohesion: Double, threshold: Double, fallback: ShellColor = .purple) -> ShellColor {
        if cohesion < threshold {
            return .red
        }
        return fallback
    }
}
