
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
    
    var difficultyLabel: SKLabelNode!
    var easyLabel: SKLabelNode!
    var hardLabel: SKLabelNode!
    var difficultyLevel = DifficultyLevel.easy
    
    var faceFeatureLabel: SKLabelNode!
    var smileLabel: SKLabelNode!
    var blinkLabel: SKLabelNode!
    var facialFeaturePreference = FacialFeature.smile
    
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
        selectLabelForInitialDifficultyLevel()
        selectLabelForInitialFacialFeature()
        
        
        // Adding physics world gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        // Adding background music as node
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "m4a") {
        
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        switch gameState {
        
        case .showingLogo:
            
            if wasEasyLabelTouched(touch: touches.first!) && difficultyLevel == .hard {
                difficultyLevel = .easy
                selectLabel(label: easyLabel)
                deselectLabel(label: hardLabel)
                return
            }
            else if wasHardLabelTouched(touch: touches.first!) && difficultyLevel == .easy {
                difficultyLevel = .hard
                selectLabel(label: hardLabel)
                deselectLabel(label: easyLabel)
                return
            }
            else if wasBlinkLabelTouched(touch: touches.first!) && facialFeaturePreference == .smile {
                facialFeaturePreference = .blink
                selectLabel(label: blinkLabel)
                deselectLabel(label: smileLabel)
                
                 NotificationCenter.default.post(Notification.init(name: Notification.Name("toggleFacialFeaturePreference")))
                
                return
            }
            else if wasSmileLabelTouched(touch: touches.first!) && facialFeaturePreference == .blink {
                facialFeaturePreference = .smile
                selectLabel(label: smileLabel)
                deselectLabel(label: blinkLabel)
                
                NotificationCenter.default.post(Notification.init(name: Notification.Name("toggleFacialFeaturePreference")))
                
                return
            }
            else {
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
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)
        
        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
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
    
    func createDifficultyLabel() {
        
        difficultyLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        difficultyLabel.horizontalAlignmentMode = .center
        difficultyLabel.text = "Difficulty Level"
        difficultyLabel.fontColor = .black
        difficultyLabel.fontSize = 30
        difficultyLabel.name = "difficultyLabel"
        difficultyLabel.position = CGPoint(x: logo.frame.midX, y: logo.frame.minY - difficultyLabel.frame.size.height - 20)
        
        addChild(difficultyLabel)
    }
    
    func createEasyLabel() {
        
        easyLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        easyLabel.horizontalAlignmentMode = .center
        easyLabel.text = "Easy"
        easyLabel.fontColor = .green
        easyLabel.fontSize = 30
        easyLabel.name = "easyLabel"
        easyLabel.position = CGPoint(x: difficultyLabel.frame.midX - difficultyLabel.frame.width / 4, y: difficultyLabel.frame.minY - easyLabel.frame.height)
        easyLabel.alpha = 0.6

        addChild(easyLabel)
    }
    
    func createHardLabel() {
        
        hardLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        hardLabel.horizontalAlignmentMode = .center
        hardLabel.text = "Hard"
        hardLabel.fontColor = .red
        hardLabel.fontSize = 30
        hardLabel.name = "hardLabel"
        hardLabel.position = CGPoint(x: difficultyLabel.frame.midX + difficultyLabel.frame.width / 4, y:  difficultyLabel.frame.minY - easyLabel.frame.height)
        hardLabel.alpha = 0.6
        
        addChild(hardLabel)
    }
    
    func createDifficultyLevelUIComponents() {
        
        createDifficultyLabel()
        createEasyLabel()
        createHardLabel()
    }
    
    func createFaceFeatureLabe() {
        
        faceFeatureLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        faceFeatureLabel.horizontalAlignmentMode = .center
        faceFeatureLabel.text = "Face Feature"
        faceFeatureLabel.fontColor = .black
        faceFeatureLabel.fontSize = 30
        faceFeatureLabel.name = "faceFeatureLabel"
        faceFeatureLabel.position = CGPoint(x: difficultyLabel.frame.midX, y: difficultyLabel.frame.minY - easyLabel.frame.size.height - faceFeatureLabel.frame.size.height - 10)
        
        addChild(faceFeatureLabel)
    }
    
    func createSmileLabel() {
        
        smileLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        smileLabel.horizontalAlignmentMode = .center
        smileLabel.text = "Smile"
        smileLabel.fontColor = .blue
        smileLabel.fontSize = 30
        smileLabel.name = "smileLabel"
        smileLabel.position = CGPoint(x: difficultyLabel.frame.midX - difficultyLabel.frame.width / 4, y: faceFeatureLabel.frame.minY - smileLabel.frame.height - 10)
        smileLabel.alpha = 0.6
        
        addChild(smileLabel)
    }
    
    func createBlinkLabel() {
        
        blinkLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
        blinkLabel.horizontalAlignmentMode = .center
        blinkLabel.text = "Blink"
        blinkLabel.fontColor = .blue
        blinkLabel.fontSize = 30
        blinkLabel.name = "blinkLabel"
        blinkLabel.position = CGPoint(x: difficultyLabel.frame.midX + difficultyLabel.frame.width / 4, y: faceFeatureLabel.frame.minY - smileLabel.frame.height - 10)
        blinkLabel.alpha = 0.6
        
        addChild(blinkLabel)
    }
    
    
    func createFacialFeaturesUIComponents() {
        
        createFaceFeatureLabe()
        createSmileLabel()
        createBlinkLabel()
    }
    
    func selectionUILabelNodesPerformAction(action: SKAction) {
        
        difficultyLabel.run(action)
        easyLabel.run(action)
        hardLabel.run(action)
        
        faceFeatureLabel.run(action)
        smileLabel.run(action)
        blinkLabel.run(action)
    }
    
    func selectLabelForInitialDifficultyLevel() {
        if difficultyLevel == .easy {
            let scaleAction = SKAction.scale(by: 1.25, duration: 0)
            easyLabel.alpha = 1.0
            easyLabel.run(scaleAction)
            hardLabel.fontColor = .gray
        }
        else {
            let scaleAction = SKAction.scale(by: 1.25, duration: 0)
            hardLabel.alpha = 1.0
            hardLabel.run(scaleAction)
            easyLabel.fontColor = .gray
        }
    }
    
    func selectLabelForInitialFacialFeature() {
        if facialFeaturePreference == .smile {
            let scaleAction = SKAction.scale(by: 1.25, duration: 0)
            smileLabel.alpha = 1.0
            smileLabel.run(scaleAction)
            blinkLabel.fontColor = .gray
        }
        else {
            let scaleAction = SKAction.scale(by: 1.25, duration: 0)
            blinkLabel.alpha = 1.0
            blinkLabel.run(scaleAction)
            smileLabel.fontColor = .gray
        }
    }
    
    func wasEasyLabelTouched(touch: UITouch) -> Bool {
        
        let positionInScene = touch.location(in: self)
        let nodesTouched = self.nodes(at: positionInScene)
        
        if !nodesTouched.isEmpty {
            if let name = nodesTouched.first?.name {
                
                if name == "easyLabel" {
                    
                    return true
                }
            }
        }
        return false
    }
    
    func wasHardLabelTouched(touch: UITouch) -> Bool {
        
        let positionInScene = touch.location(in: self)
        let nodesTouched = self.nodes(at: positionInScene)
        
        if !nodesTouched.isEmpty {
            if let name = nodesTouched.first?.name {
                
                if name == "hardLabel" {
                    
                    return true
                }
            }
        }
        return false
    }
    
    func wasSmileLabelTouched(touch: UITouch) -> Bool {
        
        let positionInScene = touch.location(in: self)
        let nodesTouched = self.nodes(at: positionInScene)
        
        if !nodesTouched.isEmpty {
            if let name = nodesTouched.first?.name {
                
                if name == "smileLabel" {
                    
                    return true
                }
            }
        }
        return false
    }
    
    func wasBlinkLabelTouched(touch: UITouch) -> Bool {
        
        let positionInScene = touch.location(in: self)
        let nodesTouched = self.nodes(at: positionInScene)
        
        if !nodesTouched.isEmpty {
            if let name = nodesTouched.first?.name {
                
                if name == "blinkLabel" {
                    
                    return true
                }
            }
        }
        return false
    }

    func selectLabel(label: SKLabelNode) {
        label.run(SKAction.scale(by: 1.25, duration: 0.2))
        label.alpha = 1.0
        
        switch label {
            
        case easyLabel:
            easyLabel.fontColor = .green
            
        case hardLabel:
            hardLabel.fontColor = .red
            
        case smileLabel:
            smileLabel.fontColor = .blue
            
        case blinkLabel:
            blinkLabel.fontColor = .blue
            
        default:
            return
        }
    }
    
    func deselectLabel(label: SKLabelNode) {
        label.run(SKAction.scale(by: 0.80, duration: 0.2))
        label.fontColor = UIColor.gray
        label.alpha = 0.6
    }

}

