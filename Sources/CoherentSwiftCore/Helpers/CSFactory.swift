//
//  coherent-swift
//
//  Created by Arthur Alves on 26/05/2020.
//

import Foundation
import SwiftSyntax

typealias FactoryDefinitionResponse = ((_ name: String, _ definition: inout CSDefinition) -> Void)
typealias FactoryMethodResponse = ((inout CSMethod) -> Void)

public class CSFactory {
    
    func process(definition: CSDefinition,
                 withMembers members: MemberDeclListSyntax,
                 completion: @escaping FactoryDefinitionResponse) {
        var localDefinition = definition
        var reportProperties: [CSProperty] = []
        
        let properties = members.filter { $0.decl.is(VariableDeclSyntax.self) }
        properties.forEach { (property) in
            let props = processProperties(property.tokens)
            reportProperties.append(contentsOf: props)
        }
        localDefinition.properties = reportProperties
        completion(localDefinition.name, &localDefinition)
    }
    
    func process(node: FunctionDeclSyntax, completion: @escaping FactoryMethodResponse) {
        var name = node.identifier.description+node.signature.description
        name = Cleaner.shared.methodName(name)
        var method = CSMethod(name: name)
        
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
    
    func mapExtensions(_ extensions: ParsingDefition, to highLevelDefinitions: ParsingDefition) -> ParsingDefition {
        
        var finalDefinitions: ParsingDefition = highLevelDefinitions
        extensions.forEach { (key, value) in
            var definition = value
            if var existingDefinition = highLevelDefinitions[key] {
                definition.methods.mutateEach { (method) in
                    let cohesion = Measurer.shared.generateCohesion(for: method, withinDefinition: existingDefinition)
                    method.cohesion = cohesion.formattedCohesion()
                    existingDefinition.methods.append(method)
                }
                definition = existingDefinition
            }
            finalDefinitions[definition.name] = definition
        }
        
        finalDefinitions.forEach { (key, value) in
            finalDefinitions[key] = processCohesion(for: value)
        }
        
        return finalDefinitions
    }
    
    // MARK: - Private
    
    private func processProperties(_ tokens: TokenSequence, defaultType: CSPropertyType = .Instance) -> [CSProperty] {
        var properties: [CSProperty] = []
        
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
                properties.append(CSProperty(keyword: keyword,
                                                       name: propertyName,
                                                       propertyType: type))
            }
        }
        return properties
    }
    
    private func processCohesion(for definition: CSDefinition) -> CSDefinition {
        var cohesion: Double = 0
        var definition = definition
        if !definition.methods.isEmpty {
            cohesion = Measurer.shared.generateCohesion(for: definition)
        } else {
            /*
             * if a definition doesn't contain properties nor methods, its
             * still considered as highly cohesive
             */
            cohesion = 100
        }
        definition.cohesion = cohesion.formattedCohesion()
        return definition
    }
}
