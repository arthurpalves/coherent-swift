//
//  coherent-swift
//
//  Created by Arthur Alves on 26/05/2020.
//

import Foundation
import SwiftSyntax

typealias FactoryDefinitionResponse = ((_ name: String, _ definition: ReportDefinition) -> Void)
typealias FactoryMethodResponse = ((inout ReportMethod) -> Void)

class SwiftFactory {
    
    func process(definition: ReportDefinition,
                 withMembers members: MemberDeclListSyntax,
                 completion: @escaping FactoryDefinitionResponse) {
        var localDefinition = definition
        var reportProperties: [ReportProperty] = []
        
        let properties = members.filter { $0.decl.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens)
            reportProperties.append(contentsOf: props)
        }
        localDefinition.properties = reportProperties
        completion(localDefinition.name, localDefinition)
    }
    
    
    func process(node: FunctionDeclSyntax, completion: @escaping FactoryMethodResponse) {
        let name = node.identifier.description+node.signature.description
        var method = ReportMethod(name: name)
        
        node.modifiers?.tokens.forEach { (item) in
            switch item.tokenKind {
            case .privateKeyword, .fileprivateKeyword:
                method.methodType = .Private
            case .internalKeyword:
                method.methodType = .Internal
            case .staticKeyword:
                method.methodType = .Static
            default:
                break
            }
        }
        
        guard let body = node.body else {
            method.cohesion = "0.00"
            return completion(&method)
        }
        
        let properties = body.statements.filter { $0.item.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens)
            method.properties.append(contentsOf: props)
        }
        method.contentString = body.description
        
        completion(&method)
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
