//
//  CoherentSwift
//

import Foundation
import PathKit

public class UserInputHelper {
    public init(
        logger: Logger = Logger.shared
    ) {
        self.logger = logger
    }
    
    public func doesUserGrantPermissionToOverrideSpec() -> Bool {
        let shouldOverrideSpec = Bool(userInput(
            with: "'coherent-swift.yml' spec already exists! Should we override it?",
            suggestion: "[Y]yes / [N]no") { input -> Bool in
            return ["y", "yes", "n","no"].contains(input.lowercased())
        }) ?? false
        
        return shouldOverrideSpec
    }
    
    public func configurationFromUserInput() -> Configuration {
        let sourceFolder = userInput(
            with: "Provide the relative path of the source folder to be scanned during the report. Ensure this folder exists.",
            suggestion: "i.e.: ./MyApp/Sources/") { input -> Bool in
            return !Path.glob(input).isEmpty
        }
        
        let minimumThreshold = userInput(
            with: "What is the minimum threshold you'd like to allow?",
            suggestion: "i.e.: Integer from 0 to 100") { input -> Bool in
            guard let number = Int(input) else { return false }
            return 0...100 ~= number
        }
        
        let reportsFolder = userInput(
            with: "Provide the relative path to a folder where you'd like to store the reports. This folder, if not existent, will be created.",
            suggestion: "i.e.: ./coherent-reports/") { input -> Bool in
            let reportsFolderPath = Path(input)
            return !reportsFolderPath.isFile
        }
        
        let ignoreOutputResults = userInput(
            with: "Should the results be ignored in case the minimum threshold isn't met? If yes, there will be no failure.",
            suggestion: "[Y]yes / [N]no") { input -> Bool in
            return ["y", "yes", "n","no"].contains(input.lowercased())
        }
        
        let reportsFormat = userInput(
            with:
                """
                Choose the format of the report:
                1. JSON
                2. Plain text
                """,
            suggestion: "Choose 1 or 2") { input -> Bool in
            guard let number = Int(input) else { return false }
            return 1...2 ~= number
        }
        
        var format: Configuration.ReportFormat = .json
        switch reportsFormat {
        case "2":
            format = .plain
        default: break
        }
        
        let configuration = Configuration(sources: [sourceFolder],
                                      minimum_threshold: minimumThreshold,
                                      reports_folder: reportsFolder,
                                      ignore_output_result: Bool(ignoreOutputResults) ?? false,
                                      report_format: format)
        return configuration
    }
    
    private func userInput(with description: String, suggestion: String, validation: (String) -> Bool) -> String  {
        logger.logInfo("*  ", item: description)
        logger.logInfo(suggestion, item: "")
        guard let input = readLine(), validation(input) else {
            logger.logInfo(item: " ")
            return userInput(with: description, suggestion: suggestion, validation: validation)
        }
        logger.logInfo(item: " ")
        if ["y", "yes"].contains(input.lowercased()) {
            return "true"
        } else if ["n", "no"].contains(input.lowercased()) {
            return "false"
        }
        return input
    }
    
    private let logger: Logger
}
