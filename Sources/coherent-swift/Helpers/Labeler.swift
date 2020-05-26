//
//  coherent-swift
//
//  Created by Arthur Alves on 25/05/2020.
//

import Foundation

struct Labeler {
    static func printColor(for cohesion: Double,
                           threshold: Double,
                           fallback: ShellColor = .purple) -> ShellColor {
        guard cohesion < threshold else { return fallback }
        return .red
    }
}
