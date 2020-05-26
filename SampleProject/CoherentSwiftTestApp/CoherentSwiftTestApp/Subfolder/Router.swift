import UIKit

class Router {
    let defaultEntryProint: EntryPoint = EntryPoint(name: "entryPoint")
    
    func viewController(for entryPoint: EntryPoint?) -> UIViewController {
        guard let entry = entryPoint else { return UIViewController() }
        return entry.viewController()
    }
}

struct EntryPoint: Codable {
    let name: String
    func viewController() -> UIViewController {
        return UINavigationController()
    }
}


