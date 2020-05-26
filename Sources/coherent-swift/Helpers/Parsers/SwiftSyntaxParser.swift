//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation
import SwiftSyntax
import PathKit

class SwiftSyntaxParser: SyntaxVisitor {
    var extensions: [String: CSDefinition] = [:]
    var mainDefinitions: [String: CSDefinition] = [:]
    var currentDefintion: CSDefinition?
    
    let factory = SwiftFactory()
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let definition = CSDefinition(name: node.identifier.text, type: .Class)
        factory.process(definition: definition, withMembers: node.members.members) {
            (name, definition) in
            
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
}
