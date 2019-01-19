//Copyright © 2019 Roving Mobile. All rights reserved.

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    var player: SKNode!
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var tapToStartNode: SKSpriteNode!
    var scaleFactor: CGFloat!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.white

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self

        scaleFactor = size.width / 320.0

        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)

        foregroundNode = createForegroundNode()
        addChild(foregroundNode)

        hudNode = createHUDNode()
        addChild(hudNode)
    }

    func createBackgroundNode() -> SKNode {
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor

        for index in 0...19 {
            let node = SKSpriteNode(imageNamed: String(format: "Background%02d", index + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: size.width / 2, y: ySpacing * CGFloat(index))

            backgroundNode.addChild(node)
        }

        return backgroundNode
    }

    func createForegroundNode() -> SKNode {
        let node = SKNode()

        let platform = createPlatform(at: CGPoint(x: 160, y: 320), type: .normal)
        node.addChild(platform)

        let star = createStar(at: CGPoint(x: 160, y: 220), type: .special)
        node.addChild(star)

        player = createPlayer()
        node.addChild(player)

        return node
    }

    func createHUDNode() -> SKNode {
        let node = SKNode()

        tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
        tapToStartNode.position = CGPoint(x: size.width / 2, y: 180.0)
        node.addChild(tapToStartNode)

        return node
    }

    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: size.width / 2, y: 80.0)

        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.addChild(sprite)

        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        playerNode.physicsBody?.isDynamic = false
        playerNode.physicsBody?.allowsRotation = true
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform

        return playerNode
    }

    func createStar(at position: CGPoint, type: StarType) -> StarNode {
        let node = StarNode()
        let nodePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = nodePosition
        node.name = "NODE_STAR"

        var sprite: SKSpriteNode
        switch type {
        case .normal:
            sprite = SKSpriteNode(imageNamed: "Star")
        case .special:
            sprite = SKSpriteNode(imageNamed: "StarSpecial")
        }
        node.addChild(sprite)

        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Star
        node.physicsBody?.collisionBitMask = 0

        return node
    }

    func createPlatform(at position: CGPoint, type: PlatformType) -> PlatformNode {
        let node = PlatformNode()
        let nodePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = nodePosition
        node.name = "NODE_PLATFORM"
        node.platformType = type

        var sprite: SKSpriteNode
        switch type {
        case .normal:
            sprite = SKSpriteNode(imageNamed: "Platform")
        case .break:
            sprite = SKSpriteNode(imageNamed: "PlatformBreak")
        }
        node.addChild(sprite)

        node.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0

        return node
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard player.physicsBody?.isDynamic == false else { return }
        tapToStartNode.removeFromParent()

        player.physicsBody?.isDynamic = true
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        var updateHUD = false
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = whichNode as! GameObjectNode

        updateHUD = other.collision(with: player)

        if updateHUD {
            
        }
    }
}
