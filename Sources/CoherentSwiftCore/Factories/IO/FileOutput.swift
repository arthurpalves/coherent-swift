//
//  CoherentSwift
//

import Foundation
import PathKit

public class FileOutput {
    func write<T>(_ encodableObject: T, toFile file: Path, format: Configuration.ReportFormat = .json) -> (Bool, Path?) where T : Encodable {
        switch format {
        case .json:
            return writeJSON(encodableObject, toFile: file)
        default:
            return writePlain(encodableObject, toFile: file)
        }
    }
    
    private func writeJSON<T>(_ encodableObject: T, toFile file: Path) -> (Bool, Path?) where T : Encodable {
        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            try createFile(file)
            
            let encoded = try encoder.encode(encodableObject)
            guard let encodedJSONString = String(data: encoded, encoding: .utf8) else { return (false, nil) }
            try encodedJSONString.write(toFile: file.absolute().description, atomically: true, encoding: .utf8)
            
            return (true, file)
            
        } catch {
            return (false, nil)
        }
    }
    
    private func writePlain<T>(_ encodableObject: T, toFile file: Path) -> (Bool, Path?) where T : Encodable {
        guard let report = encodableObject as? CSReport else { return (false, nil) }
        do {
            
            try createFile(file)
            
            let logger = Logger.shared
            try report.result.forEach { (cohesionReport) in
                
                try logger.logBack("File: ", item: cohesionReport.filename, indentationLevel: 0)
                    .appendLine(to: file)
                
                try cohesionReport.definitions?.forEach {
                    try logger.logBack("\($0.type): ", item: $0.name, indentationLevel: 1)
                        .appendLine(to: file)
                    
                    try $0.properties.forEach { (property) in
                        try logger.logBack("Property: ",
                                           item: "\(property.name), type: \(property.propertyType.rawValue), keyword: \(property.keyword)",
                            indentationLevel: 2)
                            .appendLine(to: file)
                    }
                    
                    try $0.methods.forEach { (method) in
                        try logger.logBack("Method: ", item: method.name, indentationLevel: 2)
                        .appendLine(to: file)
                        
                        try method.properties.forEach { (property) in
                            try logger.logBack("Property: ",
                                               item: "\(property.name), type: \(property.propertyType.rawValue), keyword: \(property.keyword)",
                                indentationLevel: 3)
                                .appendLine(to: file)
                        }
                        
                        try logger.logBack("Cohesion: ", item: method.cohesion+"%", indentationLevel: 3)
                            .appendLine(to: file)
                    }
                    try logger.logBack("Cohesion: ", item: $0.cohesion+"%", indentationLevel: 2)
                        .appendLine(to: file)
                }
                
                try logger.logBack("Cohesion: ", item: cohesionReport.cohesion, indentationLevel: 1)
                    .appendLine(to: file)
            }
            return (true, file)
            
        } catch {
            return (false, nil)
        }
    }
    
    private func createFile(_ path: Path) throws {
        if path.exists && path.isFile {
            try path.delete()
        }
        try path.write("")
    }
}
