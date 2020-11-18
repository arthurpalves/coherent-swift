//
//  CoherentSwift
//

import Foundation
import SwiftSyntax
import PathKit

typealias ParsingDefition = [String: CSDefinition]

class SwiftParser: SyntaxVisitor {
    var extensions: ParsingDefition = [:]
    var mainDefinitions: ParsingDefition = [:]
    var currentDefintion: CSDefinition?
    
    init(
        logger: Logger = .shared,
        factory: CSFactory = CSFactory()
    ) {
        self.logger = logger
        self.factory = factory
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let definition = CSDefinition(name: node.identifier.text, type: .Class)
        factory.process(definition: definition, withMembers: node.members.members) {
            (name, definition) in

            definition.contentString = "\(node._syntaxNode)"
            self.mainDefinitions[name] = definition
            self.currentDefintion = definition
        }
        return .visitChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let definition = CSDefinition(name: node.identifier.text, type: .Struct)
        factory.process(definition: definition, withMembers: node.members.members) {
            (name, definition) in
            self.mainDefinitions[name] = definition
        }
        return .visitChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard var definition = currentDefintion else { return .skipChildren }
        factory.process(node: node) { (method) in
            if !method.contentString.isEmpty {
                let methodCohesion = Measurer.shared.generateCohesion(for: method, withinDefinition: definition)
                method.cohesion = methodCohesion.formattedCohesion()
            }
        
            definition.methods.append(method)
            self.currentDefintion = definition
            
            switch definition.type {
            case .Extension:
                self.extensions[definition.name] = definition
            default:
                self.mainDefinitions[definition.name] = definition
            }
        }
        return .skipChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = String("\(node.extendedType)".split(separator: ".").first ?? "\(node.extendedType)")
        if let existingDefinition = mainDefinitions[name] {
            currentDefintion = existingDefinition
        } else {
            let definition = CSDefinition(name: name, type: .Extension)
            currentDefintion = definition
            extensions[name] = definition
        }
        return .visitChildren
    }
    
    let logger: Logger
    let factory: CSFactory
}

extension SwiftParser {
    func parse(file path: Path, threshold: Double, onSuccess: StepCohesionHandler) {
        logger.logInfo("File: ", item: path.description, color: .purple)
        var finalDefinitions: [CSDefinition] = []
        var cohesion: Double = 0
        
        let url = path.absolute().url
        do {
            let sourceFile = try SyntaxParser.parse(url)
            walk(sourceFile)
            
            let definitions = self.factory.mapExtensions(self.extensions, to: self.mainDefinitions)
            finalDefinitions = definitions.map { $0.value }
            
            definitions.forEach { (key, value) in
                self.logger.logDebug("\(value.type): ", item: value.name, indentationLevel: 1, color: .cyan)
                value.properties.forEach { (property) in
                    self.logger.logDebug("Property: ", item: "\(property.name), type: \(property.propertyType.rawValue), keyword: \(property.keyword)",
                        indentationLevel: 2, color: .cyan)
                }
                value.methods.forEach { (method) in
                    self.logger.logDebug("Method: ", item: method.name, indentationLevel: 2, color: .cyan)
                    
                    method.properties.forEach { (property) in
                        self.logger.logDebug("Property: ", item: "\(property.name), type: \(property.propertyType.rawValue), keyword: \(property.keyword)",
                            indentationLevel: 3, color: .cyan)
                    }
                    
                    self.logger.logDebug("Cohesion: ", item: method.cohesion+"%", indentationLevel: 3, color: .cyan)
                }
                self.logger.logDebug("Cohesion: ", item: value.cohesion+"%", indentationLevel: 2, color: .cyan)
            }
            
            cohesion = Measurer.shared.generateCohesion(for: definitions.map { $0.value })
            if cohesion.isNaN {
                self.logger.logInfo("Ignored: ", item: "No implementation found in this file", indentationLevel: 1, color: .purple)
                onSuccess(path.description, nil, [], false)
                return
            } else {
                let color = Labeler.printColor(for: cohesion, threshold: threshold)
                let cohesionString = cohesion.formattedCohesion()
                
                self.logger.logInfo("Cohesion: ", item: cohesionString+"%", indentationLevel: 1, color: color)
            }
            onSuccess(path.description, cohesion, finalDefinitions, true)
            
        } catch {
            self.logger.logError(item: error.localizedDescription)
            onSuccess(path.description, nil, finalDefinitions, false)
            return
        }
    }
}

extension SwiftParser {
    func content(_ contentString: String, hasOccuranceOf name: String, numberOfOccasions: Int = 1) -> Bool {
        let range = NSRange(location: 0, length: contentString.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: name) else { return false }
        let matches = regex.matches(in: contentString, range: range)
        return matches.count >= numberOfOccasions
    }
}
