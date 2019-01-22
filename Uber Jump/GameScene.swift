//Copyright © 2019 Roving Mobile. All rights reserved.

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene {

    var player: SKNode!
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0.0
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var tapToStartNode: SKSpriteNode!
    var scaleFactor: CGFloat!
    var endLevelY = 0
    var maxPlayerY: Int!
    var scoreLabel: SKLabelNode!
    var starsLabel: SKLabelNode!
    var gameOver = false

    private lazy var levelData: [String: AnyObject] = {
        let levelPlistPath = Bundle.main.path(forResource: "Level01", ofType: "plist")!
        let levelPlist = FileManager.default.contents(atPath: levelPlistPath)!
        return try! PropertyListSerialization.propertyList(from: levelPlist, options: [], format: nil) as! [String: AnyObject]
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.white
        maxPlayerY = 80
        GameState.shared.score = 0
        gameOver = false

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self

        scaleFactor = size.width / 320.0

        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)

        midgroundNode = createMidgroundNode()
        addChild(midgroundNode)

        foregroundNode = createForegroundNode()
        addChild(foregroundNode)

        hudNode = createHUDNode()
        addChild(hudNode)

        startAccelerometer()
    }

    private func startAccelerometer() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { accelerometerData, error in
            let acceleration = accelerometerData!.acceleration
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        }
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

    private func createPlatforms(_ node: SKNode) {
        let platforms = levelData["Platforms"] as! [String: Any]
        let platformPatterns = platforms["Patterns"] as! [String: Any]
        let platformPositions = platforms["Positions"] as! [[String: Any]]

        for platformPosition in platformPositions {
            let patternX = platformPosition["x"] as! Float
            let patternY = platformPosition["y"] as! Float
            let pattern = platformPosition["pattern"] as! String

            let platformPattern = platformPatterns[pattern] as! [[String: Any]]
            for platformPoint in platformPattern {
                let x = platformPoint["x"] as! Float
                let y = platformPoint["y"] as! Float
                let type = PlatformType(rawValue: platformPoint["type"] as! Int)!
                let positionX = CGFloat(x + patternX)
                let positionY = CGFloat(y + patternY)
                let platformNode = createPlatform(at: CGPoint(x: positionX, y: positionY), type: type)
                node.addChild(platformNode)
            }
        }
    }

    private func createStars(_ node: SKNode) {
        let stars = levelData["Stars"] as! [String: Any]
        let starPatterns = stars["Patterns"] as! [String: Any]
        let starPositions = stars["Positions"] as! [[String: Any]]

        for starPosition in starPositions {
            let patternX = starPosition["x"] as! Float
            let patternY = starPosition["y"] as! Float
            let pattern = starPosition["pattern"] as! String

            let starPattern = starPatterns[pattern] as! [[String: Any]]
            for starPoint in starPattern {
                let x = starPoint["x"] as! Float
                let y = starPoint["y"] as! Float
                let type = StarType(rawValue: starPoint["type"] as! Int)!
                let positionX = CGFloat(x + patternX)
                let positionY = CGFloat(y + patternY)
                let starNode = createStar(at: CGPoint(x: positionX, y: positionY), type: type)
                node.addChild(starNode)
            }
        }
    }

    func createForegroundNode() -> SKNode {
        let node = SKNode()

        endLevelY = levelData["EndY"] as! Int

        createPlatforms(node)
        createStars(node)

        player = createPlayer()
        node.addChild(player)

        return node
    }

    func createMidgroundNode() -> SKNode {
        let node = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat!

        for index in 0...9 {
            var spriteName: String
            let r = arc4random_uniform(2)
            switch r {
            case 0:
                spriteName = "BranchRight"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = size.width
            default:
                spriteName = "BranchLeft"
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition = 0.0
            }

            let branchNode = SKSpriteNode(imageNamed: spriteName)
            branchNode.anchorPoint = anchor
            branchNode.position = CGPoint(x: xPosition, y: 500.0 * CGFloat(index))
            node.addChild(branchNode)
        }

        return node
    }

    func createHUDNode() -> SKNode {
        let node = SKNode()

        tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
        tapToStartNode.position = CGPoint(x: size.width / 2, y: 180.0)
        node.addChild(tapToStartNode)

        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: size.height - 30)
        node.addChild(star)

        starsLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        starsLabel.fontSize = 30
        starsLabel.fontColor = SKColor.white
        starsLabel.position = CGPoint(x: 50, y: size.height - 40)
        starsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        starsLabel.text = String(format: "X %d", GameState.shared.stars)
        node.addChild(starsLabel)

        scoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 40)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        scoreLabel.text = "0"
        node.addChild(scoreLabel)

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

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }
        
        if Int(player.position.y) > maxPlayerY {
            GameState.shared.score += Int(player.position.y) - maxPlayerY
            maxPlayerY = Int(player.position.y)
            scoreLabel.text = String(format: "%d", GameState.shared.score)
        }

        foregroundNode.enumerateChildNodes(withName: "NODE_PLATFORM") { node, stop in
            let platform = node as! PlatformNode
            platform.checkNodeRemoval(playerY: self.player.position.y)
        }

        foregroundNode.enumerateChildNodes(withName: "NODE_STAR") { node, stop in
            let star = node as! StarNode
            star.checkNodeRemoval(playerY: self.player.position.y)
        }

        if player.position.y > 200.0 {
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0) / 10))
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0) / 4))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200.0))
        }

        if Int(player.position.y) > endLevelY {
            endGame()
        }

        if Int(player.position.y) < maxPlayerY - 800 {
            endGame()
        }
    }

    override func didSimulatePhysics() {
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        if player.position.x < -20.0 {
            player.position = CGPoint(x: size.width + 20, y: player.position.y)
        } else if player.position.x > size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }

    func endGame() {
        gameOver = true
        GameState.shared.save()

        let reveal = SKTransition.fade(withDuration: 0.5)
        let endGameScene = EndGameScene(size: size)
        view?.presentScene(endGameScene, transition: reveal)
    }
}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        var updateHUD = false
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = whichNode as! GameObjectNode

        updateHUD = other.collision(with: player)

        if updateHUD {
            starsLabel.text = String(format: "X %d", GameState.shared.stars)
            scoreLabel.text = String(format: "%d", GameState.shared.score)
        }
    }
}
