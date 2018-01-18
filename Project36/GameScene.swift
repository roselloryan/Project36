
import SpriteKit
import GameplayKit


enum GameState {
    case showingLogo
    case playing
    case dead
    
}

enum DifficultyLevel {
    case easy
    case hard
}

enum FacialFeature {
    case smile
    case blink
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var scoreLabel : SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    
    // SpriteNode properties
    var difficultyNode: SKSpriteNode!
    var easyNode: SKSpriteNode!
    var hardNode: SKSpriteNode!
    
    var faceFeatureNode: SKSpriteNode!
    var blinkNode: SKSpriteNode!
    var smileNode: SKSpriteNode!
    
    var difficultyLevel = DifficultyLevel.easy {
        
        didSet {
            if difficultyLevel != oldValue && logo != nil {
                
                if difficultyLevel == .easy {
                    updateUIForEasySelected()
                }
                else {
                    updateUIForHardSelected()
                }
            }
        }
    }
    
    var facialFeaturePreference = FacialFeature.smile {
        
        didSet {
            if facialFeaturePreference != oldValue && logo != nil {
               
                postToggleFacialFeatureNotification()
                
                if facialFeaturePreference == .smile {
                    updateUIForSmileSelected()
                }
                else {
                    updateUIForBlinkSelected()
                }
            }
        }
    }
    
    var backgroundMusic: SKAudioNode!
    
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo
    
    
    
    override func didMove(to view: SKView) {
        createPlayer()
        createSky()
        createBackground()
        createGround()
        createScore()
        createLogos()
        createDifficultyLevelUIComponents()
        createFacialFeaturesUIComponents()
        
        
        
        
        // Adding physics world gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        // Adding background music as node
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {

            print(musicURL)
            
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        switch gameState {
        
        case .showingLogo:
            
            if !wasSelectionNodeTouched(touch: touches.first!) {
                // Strating game no selection labels touched
                gameState = .playing
                
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                let wait = SKAction.wait(forDuration: 0.5)
                let activatePlayer = SKAction.run { [unowned self] in
                    self.player.physicsBody?.isDynamic = true
                    self.startRocks()
                }
                let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
                logo.run(sequence)
                selectionUILabelNodesPerformAction(action: SKAction.sequence([fadeOut, remove]))
            }
            
        case .playing:
            player.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            player.physicsBody?.applyImpulse( CGVector(dx: 0.0, dy: 20.0))
        
        default:
            // Dead

            // Reset game with new scene
            let scene = GameScene(fileNamed: "GameScene")!
            scene.difficultyLevel = self.difficultyLevel
            scene.facialFeaturePreference = self.facialFeaturePreference
            let transition = SKTransition.moveIn(with: .right, duration: 1.0)
            self.view?.presentScene(scene, transition: transition)
        }
    }

    func createPlayer() {
        
        let playerTexture = SKTexture(imageNamed: "player-1")
        player = SKSpriteNode(texture: playerTexture)
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 6, y: frame.height * 0.75)
        addChild(player)
        
        // Add physics to player
        player.physicsBody = SKPhysicsBody(texture: playerTexture, size: playerTexture.size())
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        player.physicsBody?.isDynamic = false
        player.physicsBody?.collisionBitMask = 0
        
        let frame2 = SKTexture(imageNamed: "player-2")
        let frame3 = SKTexture(imageNamed: "player-3")
        let animation = SKAction.animate(with: [playerTexture, frame2, frame3, frame2], timePerFrame: 0.01)
        let runForever = SKAction.repeatForever(animation)
        
        player.run(runForever)
    }
    
    
    func createSky() {
        
        let topSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.14, brightness: 0.97, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.67))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        let bottomSky = SKSpriteNode(color: UIColor(hue: 0.55, saturation: 0.16, brightness: 0.96, alpha: 1), size: CGSize(width: frame.width, height: frame.height * 0.33))
        topSky.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        topSky.position = CGPoint(x: frame.midX, y: frame.height)
        bottomSky.position = CGPoint(x: frame.midX, y: bottomSky.frame.height / 2)
        
        addChild(topSky)
        addChild(bottomSky)
        
        bottomSky.zPosition = -40
        topSky.zPosition = -40
    }
    
    func createBackground () {
        
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        for i in 0...1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.zPosition =  -30
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: (backgroundTexture.size().width * CGFloat(i)) - CGFloat(1 * i), y: 100)
            addChild(background)
            
            let moveLeft = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0.0, duration: 20)
            let moveReset = SKAction.moveBy(x: backgroundTexture.size().width, y: 0.0, duration: 0.0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")
        
        for i in 0...1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)
            
            
            // Add ground physics. Keeps ground form responding to gravity and falling off screen
            ground.physicsBody = SKPhysicsBody(texture: groundTexture, size: groundTexture.size())
            ground.physicsBody?.isDynamic = false
            
            addChild(ground)
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0.0, duration: 5)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0.0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }
    
    func createRocksForDifficultyLevel(level: DifficultyLevel) {
        
        // Make rocks
        let rockTexture = SKTexture(imageNamed: "rock")
        
        let topRock = SKSpriteNode(texture: rockTexture)
        topRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        topRock.physicsBody?.isDynamic = false
        topRock.zRotation = CGFloat.pi
        topRock.xScale = -1.0
        
        let bottomRock = SKSpriteNode(texture: rockTexture)
        bottomRock.physicsBody = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())
        bottomRock.physicsBody?.isDynamic = false
        topRock.zPosition = -20
        bottomRock.zPosition = -20
        
        // Make collisions
        let rockCollision = SKSpriteNode(color: .clear, size: CGSize(width: 32, height: frame.height))
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false
        rockCollision.name = "scoreDetect"
        
        addChild(topRock)
        addChild(bottomRock)
        addChild(rockCollision)
        
        // Position some rocks
        let xPosition = frame.width + topRock.frame.width
        
        let max = Int(frame.height / 2.6)
        let rand = GKRandomDistribution(lowestValue: 0, highestValue: max)
        let yPostition = CGFloat(rand.nextInt())
        
        
        // Makes space bigger or smaller
        let rockDistance: CGFloat = level == .easy ? 110 : 70
        
        // Move rocks from right to left and then remove
        topRock.position = CGPoint(x: xPosition, y: yPostition + topRock.size.height + rockDistance)
        bottomRock.position = CGPoint(x: xPosition, y: yPostition - rockDistance)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)
        
        let endPosition = frame.width + (topRock.frame.width * 2)
        
        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])

        topRock.run(moveSequence)
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }
    
    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocksForDifficultyLevel(level: self.difficultyLevel)
        }
        
        let wait = SKAction.wait(forDuration: 3)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        
        run(repeatForever)
    }

    
    override func update(_ currentTime: TimeInterval) {
        
        guard player != nil else { return }
        guard let playerPhysicsBody = player.physicsBody else { return }
        
        let value = playerPhysicsBody.velocity.dy * 0.001
        let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
        
        player.run(rotate)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            }
            else {
                contact.bodyA.node?.removeFromParent()
            }
            
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1
            
            return
        }
        
        // prevents "Double collision" after one node has been removed
        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }
        
        if contact.bodyA.node == player || contact.bodyB.node == player {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            
            let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
            run(sound)
            
            gameState = .dead
            gameOver.alpha = 1
            backgroundMusic.run(SKAction.stop())
            
            player.removeFromParent()
            speed = 0
        }
    }
    
    func createLogos() {
        
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY + 40)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY + 40)
        gameOver.alpha = 0.0
        addChild(gameOver)
    }
    
    func createScore() {
        
        scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        scoreLabel.position = self.frame.size.height == 812 ? CGPoint(x: frame.maxX - 20, y: frame.maxY - 60) : CGPoint(x: frame.maxX - 20, y: frame.maxY - 40)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.fontColor = .black
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
    }
    
    
    // MARK: Selection Node methods
    
    func createDifficultyLevelNode() {
        
        difficultyNode = SKSpriteNode(imageNamed: "difficultyLevel")
        difficultyNode.position = CGPoint(x: logo.frame.minX + difficultyNode.frame.width / 2, y: logo.frame.minY - difficultyNode.frame.height / 2 - 20)
        difficultyNode.name = "difficultyNode"
        addChild(difficultyNode)
    }
    
    func setEasyOnNode() {
        
        if easyNode != nil {
            easyNode.removeFromParent()
        }
        
        easyNode = SKSpriteNode(imageNamed: "Easy_On")
        easyNode.position = CGPoint(x: frame.midX - easyNode.frame.width / 2, y: difficultyNode.frame.minY - easyNode.frame.height / 2)
        easyNode.name = "easyNode"
        addChild(easyNode)
    }
    
    func setEasyOffNode() {
        
        if easyNode != nil {
            easyNode.removeFromParent()
        }
        
        easyNode = SKSpriteNode(imageNamed: "Easy_Off")
        easyNode.position = CGPoint(x: frame.midX - easyNode.frame.width / 2, y: difficultyNode.frame.minY - easyNode.frame.height / 2)
        easyNode.name = "easyNode"
        addChild(easyNode)
    }
    
    func setHardOnNode() {
        
        if hardNode != nil {
            hardNode.removeFromParent()
        }
        
        hardNode = SKSpriteNode(imageNamed: "Hard_On")
        hardNode.position = CGPoint(x: frame.midX + hardNode.frame.width / 2, y: easyNode.position.y)
        hardNode.name = "hardNode"
        addChild(hardNode)
    }
    
    func setHardOffNode() {
        
        if hardNode != nil {
            hardNode.removeFromParent()
        }
        
        hardNode = SKSpriteNode(imageNamed: "Hard_Off")
        hardNode.position = CGPoint(x: frame.midX + hardNode.frame.width / 2, y: easyNode.position.y)
        hardNode.name = "hardNode"
        addChild(hardNode)
    }
    
    func updateUIForEasySelected() {
        setEasyOnNode()
        setHardOffNode()
    }
    
    func updateUIForHardSelected() {
        setEasyOffNode()
        setHardOnNode()
    }
    
    func createDifficultyLevelUIComponents() {
        
        createDifficultyLevelNode()
        
        if difficultyLevel == .easy {
            updateUIForEasySelected()
        }
        else {
            updateUIForHardSelected()
        }
    }
    
    func createFacialFeatureNode() {
        
        faceFeatureNode = SKSpriteNode(imageNamed: "facialFeature")
        faceFeatureNode.position = CGPoint(x: logo.frame.minX + faceFeatureNode.frame.width / 2, y: easyNode.frame.minY - faceFeatureNode.frame.height / 2 - 20)
        faceFeatureNode.name = "faceFeatureNode"
        addChild(faceFeatureNode)
    }
    
    func setSmileOnNode() {
        
        if smileNode != nil {
            smileNode.removeFromParent()
        }
        
        smileNode = SKSpriteNode.init(imageNamed: "Smile_On")
        smileNode.position = CGPoint(x: frame.midX - smileNode.frame.width / 2, y: faceFeatureNode.frame.minY - smileNode.frame.height / 2)
        smileNode.name = "smileNode"
        addChild(smileNode)
    }
    
    func setSmileOffNode() {
        
        if smileNode != nil {
            smileNode.removeFromParent()
        }
        
        smileNode = SKSpriteNode.init(imageNamed: "Smile_Off")
        smileNode.position = CGPoint(x: frame.midX - smileNode.frame.width / 2, y: faceFeatureNode.frame.minY - smileNode.frame.height / 2)
        smileNode.name = "smileNode"
        addChild(smileNode)
    }
    
    func setBlinkOnNode() {
        
        if blinkNode != nil {
            blinkNode.removeFromParent()
        }
        
        blinkNode = SKSpriteNode.init(imageNamed: "Blink_On")
        blinkNode.position = CGPoint(x: frame.midX + blinkNode.frame.width / 2, y: faceFeatureNode.frame.minY - blinkNode.frame.height / 2)
        blinkNode.name = "blinkNode"
        addChild(blinkNode)
    }
    
    func setBlinkOffNode() {
        
        if blinkNode != nil {
            blinkNode.removeFromParent()
        }
        blinkNode = SKSpriteNode.init(imageNamed: "Blink_Off")
        blinkNode.position = CGPoint(x: frame.midX + blinkNode.frame.width / 2, y: faceFeatureNode.frame.minY - blinkNode.frame.height / 2)
        blinkNode.name = "blinkNode"
        addChild(blinkNode)
    }
    
    func updateUIForSmileSelected() {
        
        if faceFeatureNode == nil {
            createFacialFeatureNode()
        }
        
        setSmileOnNode()
        setBlinkOffNode()
    }
    
    func updateUIForBlinkSelected() {
        
        if faceFeatureNode == nil {
            createFacialFeatureNode()
        }
        
        setSmileOffNode()
        setBlinkOnNode()
    }
    
    
    func createFacialFeaturesUIComponents() {
        
        createFacialFeatureNode()
        
        if facialFeaturePreference == .smile {
           updateUIForSmileSelected()
        }
        else {
            updateUIForBlinkSelected()
        }
    }
    
    func selectionUILabelNodesPerformAction(action: SKAction) {
        
        difficultyNode.run(action)
        easyNode.run(action)
        hardNode.run(action)
        
        faceFeatureNode.run(action)
        smileNode.run(action)
        blinkNode.run(action)
    }

    
    func wasSelectionNodeTouched(touch: UITouch) -> Bool {
        
        let positionInScene = touch.location(in: self)
        let nodesTouched = self.nodes(at: positionInScene)
        
        if !nodesTouched.isEmpty {
            if let name = nodesTouched.first?.name {
                
                switch name {
                    
                case "easyNode":
                    print("easy node tapped")
                    difficultyLevel = .easy
                    return true

                case "hardNode":
                    print("hard node tapped")
                    difficultyLevel = .hard
                    return true
                    
                case "smileNode":
                    print("smile node tapped")
                    facialFeaturePreference = .smile
                    return true
                    
                case "blinkNode":
                    print("blink node tapped")
                    facialFeaturePreference = .blink
                    return true

                default:
                    print("other node tapped")
                    return false
                }
            }
        }
        return false
    }
    
    func postToggleFacialFeatureNotification() {
        NotificationCenter.default.post(Notification.init(name: Notification.Name("toggleFacialFeaturePreference")))
    }
}


