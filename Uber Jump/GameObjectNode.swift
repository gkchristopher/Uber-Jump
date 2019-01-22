//Copyright © 2019 Roving Mobile. All rights reserved.

import SpriteKit

enum StarType: Int {
    case normal
    case special
}

enum PlatformType: Int {
    case normal
    case `break`
}

class GameObjectNode: SKNode {

    func collision(with player: SKNode) -> Bool {
        return false
    }

    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > position.y + 300.0 {
            removeFromParent()
        }
    }
}

class StarNode: GameObjectNode {

    var starType: StarType!
    let starSound = SKAction.playSoundFileNamed("StarPing.caf", waitForCompletion: false)

    override func collision(with player: SKNode) -> Bool {
        player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 400.0)
        run(starSound) {
            self.removeFromParent()
        }
        GameState.shared.score += starType == .normal ? 20 : 100
        GameState.shared.stars += starType == .normal ? 1 : 5
        return true
    }
}

class PlatformNode: GameObjectNode {

    var platformType: PlatformType!

    override func collision(with player: SKNode) -> Bool {
        if let dy = player.physicsBody?.velocity.dy, dy < CGFloat(0.0) {
            player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 250.0)

            if platformType == .break {
                removeFromParent()
            }
        }
        return false
    }
}

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let Star: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
}
