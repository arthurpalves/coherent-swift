//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation
import SwiftSyntax
import PathKit

class SwiftSyntaxParser: SyntaxVisitor {
    var classes: [Syntax: [ReportDefinition]] = [:]
    var definitions: [AnyHashable: ReportDefinition] = [:]
    var structs: [ReportDefinition] = []
    
    var fileDefinitions: [String: ReportDefinition] = [:]
    var currentDefintion: ReportDefinition?
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        var definition = ReportDefinition(name: node.identifier.text)
        var reportProperties: [ReportProperty] = []

        Logger.shared.logInfo("Class: ", item: definition.name, indentationLevel: 1, color: .purple)
        let properties = node.members.members.filter { $0.decl.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens, identation: 2)
            reportProperties.append(contentsOf: props)
        }
        definition.properties = reportProperties
        currentDefintion = definition
        fileDefinitions[definition.name] = definition
        
        return SyntaxVisitorContinueKind.visitChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard var definition = currentDefintion else { return .skipChildren }
        Logger.shared.logInfo("Method: ", item: node.identifier, indentationLevel: 2, color: .purple)
        var method = ReportMethod(name: node.identifier.text)
        
        let properties = node.body?.statements.filter { $0.item.is(VariableDeclSyntax.self) }
        properties?.forEach { (property) in
            let props = processProperties(property.tokens, identation: 3)
            method.properties.append(contentsOf: props)
        }
        
        method.contentString = node.body!.description
        let methodCohesion = Measurer.shared.generateCohesion(for: method, withinDefinition: definition)
        method.cohesion = methodCohesion.formattedCohesion()
        Logger.shared.logInfo("Cohesion: ", item: method.cohesion+"%%", indentationLevel: 3, color: .purple)
        
        definition.methods.append(method)
        
        currentDefintion = definition
        fileDefinitions[definition.name] = definition
        return SyntaxVisitorContinueKind.skipChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers?.contains(where: { $0.name.tokenKind == .publicKeyword }) == true {
            print("ExtensionDeclSyntax: ")
        }
        return SyntaxVisitorContinueKind.visitChildren
    }
    
    private func processProperties(_ tokens: TokenSequence, identation: Int = 0) -> [ReportProperty] {
        var properties: [ReportProperty] = []
        
        if tokens.contains(where: { (syntax) -> Bool in
            syntax.tokenKind == .letKeyword || syntax.tokenKind == .varKeyword
        }) {
            var keyword = ""
            var propertyName = ""
            var type: PropertyType = .instanceProperty

            tokens.forEach { (item) in
                switch item.tokenKind {
                case .identifier(let name):
                    propertyName = name
                case .letKeyword:
                    keyword = "let"
                case .varKeyword:
                    keyword = "var"
                case .staticKeyword:
                    type = .classProperty
                default:
                    break
                }
            }
            if !keyword.isEmpty, !propertyName.isEmpty {
                properties.append(ReportProperty(keyword: keyword,
                                                       name: propertyName,
                                                       propertyType: type))
                Logger.shared.logInfo("Property: ", item: propertyName, indentationLevel: identation, color: .purple)
            }
        }
        return properties
    }
}
