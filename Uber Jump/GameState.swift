//Copyright © 2019 Roving Mobile. All rights reserved.

import Foundation

class GameState {

    var score: Int
    var highScore: Int
    var stars: Int

    static let highScoreKey = "highScoreKey"
    static let starsKey = "starsKey"

    static var shared = GameState()

    init() {
        score = 0
        highScore = 0
        stars = 0

        let defaults = UserDefaults.standard

        highScore = defaults.integer(forKey: GameState.highScoreKey)
        stars = defaults.integer(forKey: GameState.starsKey)
    }

    func save() {
        highScore = max(score, highScore)

        let defaults = UserDefaults.standard
        defaults.set(highScore, forKey: GameState.highScoreKey)
        defaults.set(stars, forKey: GameState.starsKey)
    }
}
