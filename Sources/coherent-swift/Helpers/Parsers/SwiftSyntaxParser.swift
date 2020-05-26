//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import AppKit
import SwiftSyntax
import PathKit

class SwiftSyntaxParser: SyntaxVisitor {
    var extensions: [String: ReportDefinition] = [:]
    var mainDefinitions: [String: ReportDefinition] = [:]
    var currentDefintion: ReportDefinition?
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        var definition = ReportDefinition(name: node.identifier.text, type: .Class)
        processHighLevelDefinition(&definition,
                                   withMembers: node.members.members,
                                   markAsCurrentDefinition: true)
        
//        var reportProperties: [ReportProperty] = []
//        let properties = node.members.members.filter { $0.decl.is(VariableDeclSyntax.self) }
//        properties.forEach { (property) in
//            let props = processProperties(property.tokens)
//            reportProperties.append(contentsOf: props)
//        }
//        definition.properties = reportProperties
//        currentDefintion = definition
//        mainDefinitions[definition.name] = definition
//
        return .visitChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        var definition = ReportDefinition(name: node.identifier.text, type: .Struct)
        var reportProperties: [ReportProperty] = []

        let properties = node.members.members.filter { $0.decl.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens)
            reportProperties.append(contentsOf: props)
        }
        definition.properties = reportProperties
        mainDefinitions[definition.name] = definition

        return .visitChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard var definition = currentDefintion else { return .skipChildren }
        var method = ReportMethod(name: node.identifier.description+node.signature.description)
        
        let properties = node.body?.statements.filter { $0.item.is(VariableDeclSyntax.self) }
        properties?.forEach { (property) in
            let props = processProperties(property.tokens)
            method.properties.append(contentsOf: props)
        }
        
        if let body = node.body?.description {
            method.contentString = node.body!.description
            let methodCohesion = Measurer.shared.generateCohesion(for: method, withinDefinition: definition)
            method.cohesion = methodCohesion.formattedCohesion()
        } else {
            method.cohesion = "0.00"
        }
        
        definition.methods.append(method)
        
        currentDefintion = definition
        if definition.type == .Extension {
            extensions[definition.name] = definition
        } else {
            mainDefinitions[definition.name] = definition
        }
        return .skipChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = "\(node.extendedType)"
        if let existingDefinition = mainDefinitions[name] {
            currentDefintion = existingDefinition
        } else {
            let definition = ReportDefinition(name: name, type: .Extension)
            currentDefintion = definition
            extensions[name] = definition
        }
        return .visitChildren
    }
    
    private func processHighLevelDefinition(_ definition: inout ReportDefinition,
                                            withMembers members: MemberDeclListSyntax,
                                            markAsCurrentDefinition: Bool = false) {
        var reportProperties: [ReportProperty] = []
        
        let properties = members.filter { $0.decl.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens)
            reportProperties.append(contentsOf: props)
        }
        definition.properties = reportProperties
        mainDefinitions[definition.name] = definition
        
        if markAsCurrentDefinition { currentDefintion = definition }
    }
    
    private func processProperties(_ tokens: TokenSequence, defaultType: PropertyType = .Instance) -> [ReportProperty] {
        var properties: [ReportProperty] = []
        
        if tokens.contains(where: { (syntax) -> Bool in
            syntax.tokenKind == .letKeyword
                || syntax.tokenKind == .varKeyword
        }) {
            var keyword = ""
            var propertyName = ""
            var type = defaultType

            tokens.forEach { (item) in
                switch item.tokenKind {
                case .identifier(let name) where !["IBOutlet", "weak"].contains(where: { $0.contains(name) }):
                    propertyName = propertyName.isEmpty ? name : propertyName
                case .letKeyword:
                    keyword = "let"
                case .varKeyword:
                    keyword = "var"
                case .staticKeyword:
                    type = .Static
                case .privateKeyword:
                    type = .Private
                default:
                    break
                }
            }
            if !keyword.isEmpty, !propertyName.isEmpty {
                properties.append(ReportProperty(keyword: keyword,
                                                       name: propertyName,
                                                       propertyType: type))
            }
        }
        return properties
    }
}
