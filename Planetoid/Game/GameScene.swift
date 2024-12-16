//
//  GameScene.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import AVFoundation
import Foundation
import SpriteKit

final class GameScene: SKScene, ObservableObject {

    // MARK: - Nested Types

    /// Collision-capable objects
    enum ColliderType: UInt32 {
        case asteroids = 1
        case walls  = 2
        case planet = 4
        case stars  = 8
    }

    enum SpriteFactory {
        case pluto
        case star
        case asteroid

        @MainActor
        var node: SKSpriteNode {
            switch self {
            case .pluto: return SKSpriteNode(imageNamed: "Pluto")
            case .star: return SKSpriteNode(imageNamed: "Star")
            case .asteroid: return SKSpriteNode(imageNamed: "Asteroid-\(Int.random(in: 1...10))")
            }
        }
    }

    enum TextureFactory {
        case asteroid
        case background

        @MainActor
        var node: SKTexture {
            switch self {
            case .asteroid: return SKTexture(imageNamed: "Explosion-\(Int.random(in: 1...6))")
            case .background: return SKTexture(imageNamed: "background")
            }
        }
    }

    private static let drivers: [PlutoDriver.Type] = [
        MouseDriver.self,
        AccelerometerDriver.self
    ]

    // MARK: - Internal Properties

    var levelDelegate : LevelDelegate?

    // MARK: - Private Properties

    nonisolated private let kAsteroidName = "asteroid"
    nonisolated private let kPlutoName = "pluto"
    nonisolated private let kStarName = "star"
    nonisolated private let kExplodedName = "exploded"
    nonisolated private let kScoreName = "score"
    nonisolated private let kLifeName = "life"
    nonisolated private let kStarCount = 20
    nonisolated private let kStarPerLevelFactor = 5
    nonisolated private let kAsteroidCount = 120
    nonisolated private let kAsteroidPerLevelFactor = 20
    nonisolated private let kPlutoBaseline = 20
    private let initialState: Double = -0.7
    private var scoreTimer: Timer?
    private var driver: PlutoDriver?

    // MARK: - SKScene

    /// Initial setup
    override func didMove(to view: SKView) {
        // Set up game scene
        setupScene()

        Self.drivers.forEach {
            guard driver == nil else { return }
            driver = $0.init(initialState: initialState)
        }
    }

    /// Update loop (called before each frame is rendered)
    override func update(_ currentTime: TimeInterval) {
        moveAsteroidsForUpdate()

        //get our hero, pluto, and then adjust its position according to the chosen driver.
        guard let pluto = childNode(withName: kPlutoName) as? SKSpriteNode else {
            return
        }

        pluto.physicsBody?.applyForce(
            CGVector(dx: 0,
                     dy: driver?.readAdjustmentValue() ?? 0)
        )
    }

    /// Handle touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       for touch in touches {
           let location = touch.location(in: self)

           enumerateChildNodes(withName: kAsteroidName) { asteroid, stop in
               //update their position
               asteroid.position = CGPointMake(asteroid.position.x - (2 * asteroid.speed),
                                               asteroid.position.y)

               guard asteroid.contains(location),
                     let asteroid = asteroid as? SKSpriteNode else {
                   return
               }

               self.handleAsteroidCollision(asteroid: asteroid, intentional: true)
           }
        }
    }

    // MARK: - Private Functions
    
    /// Move asteroids forward at update loop
    private func moveAsteroidsForUpdate() {
        var asteroidsVisible = false //keep track of asteroids
        
        //loop over all asteroids
        enumerateChildNodes(withName: kAsteroidName) { node, stop in
            //update their position
            node.position = CGPoint(x: node.position.x - (2 * node.speed), y: node.position.y)
            
            //check if asteroid is still visible
            if node.position.x + node.frame.width > self.frame.minX {
                asteroidsVisible = true
            }
            
            let rotateAsteroid = SKAction.rotate(byAngle: CGFloat(Double.pi / 4)/32, duration: 0)
            node.run(rotateAsteroid)
        }
        
        //if no asteroid was visible, raise flag for end of level
        if asteroidsVisible == false {
            playLevelUpSound()
            levelDelegate?.levelSucceeded()
        }
        
        //loop over exploded asteroids and update their positions, too
        enumerateChildNodes(withName: kExplodedName) { node, stop in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        }
        
        //loop over stars and update their positions, too
        enumerateChildNodes(withName: kStarName) { node, stop in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        }
    }
    
    private func setupScene() {
        guard let levelDelegate, size.width > .zero, size.height > .zero else { return }

        setupFrame() //setup level frame
        setupBackground()
        setupPlayer() //setup pluto and add it to scene
        setupAsteroids(level: levelDelegate.currentLevel) //setup obstacles
        setupStars(level: levelDelegate.currentLevel) //setup stars

        levelDelegate.play()
    }
    
    private func setupBackground() {
        let backgroundTexture = TextureFactory.background.node

        //move background right to left; replace
        let shiftBackground = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 80)
        let replaceBackground = SKAction.moveBy(x: backgroundTexture.size().width, y:0, duration: 0)
        let movingAndReplacingBackground = SKAction.repeatForever(SKAction.sequence([shiftBackground,replaceBackground]))
        
        for i in 0..<3 {
            //defining background; giving it height and moving width
            let background = SKSpriteNode(texture:backgroundTexture)
            background.zPosition = 0
            background.position = CGPoint(x: backgroundTexture.size().width / 2 + (backgroundTexture.size().width * CGFloat(i)),
                                          y: frame.midY)
            background.size.height = frame.height
            background.run(movingAndReplacingBackground)
            
            addChild(background)
        }
    }
    
    private func setupFrame() {
        //set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = ColliderType.walls.rawValue
        isUserInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        //set background, dark blue
        backgroundColor = .primaryBackground
    }
    
    private func setupPlayer() {
        //create our hero, pluto
        let pluto = SpriteFactory.pluto.node
        pluto.name = kPlutoName
        
        //scale pluto down (our image is too big)
        pluto.size = .init(width: 256, height: 256)
        pluto.xScale = 0.3
        pluto.yScale = 0.3

        //position pluto at the horizontal baseline, center vertically

        pluto.position = CGPoint(x: pluto.size.width / 2 + CGFloat(kPlutoBaseline),
                                 y: frame.midY)

        //setup physics body to collide with the wall bounds
        pluto.physicsBody = SKPhysicsBody(circleOfRadius: pluto.frame.width / 2)
        pluto.physicsBody?.isDynamic = true
        pluto.physicsBody?.affectedByGravity = false
        pluto.physicsBody?.mass = 0.02
        pluto.physicsBody?.restitution = 0
        pluto.physicsBody?.allowsRotation = false
        pluto.physicsBody?.categoryBitMask = ColliderType.planet.rawValue
        pluto.physicsBody?.collisionBitMask = ColliderType.walls.rawValue
        pluto.zPosition = 2
        
        //add pluto to scene
        addChild(pluto)
    }
    
    private func setupStars(level: Int) {
        let starCount = kStarCount + (kStarPerLevelFactor * level)

        //create starCount stars
        for i in 0...starCount {
            //create a star
            let star = SpriteFactory.star.node
            star.name = kStarName
            
            //generate a pseudo-random position
            let sceneLength = frame.maxX * 10
            let starPositionY: CGFloat = .random(in: frame.minY..<frame.maxY)
            let minStarPositionX = (CGFloat(i) / CGFloat(starCount)) * (sceneLength * 0.9)
            let starPositionX: CGFloat = .random(in: minStarPositionX..<sceneLength)
            star.position = CGPoint(x: starPositionX, y: starPositionY)
            
            //fixed scale size
            star.size = .init(width: 24, height: 24)
            star.xScale = 1
            star.yScale = 1

            //setup physics body to collide with asteroids, stars and pluto
            star.physicsBody = SKPhysicsBody(circleOfRadius: star.frame.width/2)
            star.physicsBody?.isDynamic = true
            star.physicsBody?.affectedByGravity = false
            star.physicsBody?.mass = 0.02
            star.physicsBody?.categoryBitMask    = ColliderType.stars.rawValue
            star.physicsBody?.contactTestBitMask = ColliderType.planet.rawValue
            star.physicsBody?.collisionBitMask   = ColliderType.planet.rawValue
            star.zPosition = 1
            
            //add star to scene
            addChild(star)
        }
    }
    
    private func setupAsteroids(level: Int) {
        let asteroidCount = kAsteroidCount + (kAsteroidPerLevelFactor * level)

        //create kAsteroidCount asteroids
        var clearPath: CGFloat = .random(in: 0.45...0.55)
        for i in 0...asteroidCount {
            //create a random Asteroid
            let asteroid = SpriteFactory.asteroid.node
            asteroid.name = kAsteroidName
            asteroid.size = .init(width: 72, height: 72)

            //generate a pseudo-random position
            let sceneLength = frame.maxX * 10

            //position asteroids on either side of path we keep clear
            let asteroidPositionY: CGFloat = Bool.random()
            ? .random(in: frame.minY...(frame.maxY * (clearPath + 0.05))) //position UP
            : .random(in: (frame.maxY * (clearPath - 0.05))...frame.maxY) //position DOWN
            //update clearPath for next round
            let shift: CGFloat = .random(in: -0.1..<0.1)

            //bound path to top and bottom
            clearPath = max(min(clearPath + shift, 0.95), 0.05)

            //weighs X position towards end of scene so level gets harder
            let minAsteroidPosition: CGFloat = (CGFloat(i) / CGFloat(asteroidCount)) * (sceneLength * 0.9)
            let asteroidPositionX: CGFloat = .random(in: minAsteroidPosition..<sceneLength)
            asteroid.position = CGPoint(x: asteroidPositionX, y: asteroidPositionY)
            
            //size and rotate asteroid at random within bounds
            let scale: CGFloat = .random(in: 0.4...0.6)
            asteroid.xScale = scale
            asteroid.yScale = scale
            asteroid.zRotation = .random(in: 0...360)

            //setup physics body to collide with other asteroids, stars and pluto
            asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width/2)
            asteroid.physicsBody?.isDynamic = true
            asteroid.physicsBody?.affectedByGravity = false
            asteroid.physicsBody?.mass = 0.02
            asteroid.speed = CGFloat.random(in: 1.3...1.5) //random speed, mostly for later use
            asteroid.physicsBody?.categoryBitMask    = ColliderType.asteroids.rawValue
            asteroid.physicsBody?.contactTestBitMask = ColliderType.planet.rawValue
            asteroid.physicsBody?.collisionBitMask   = ColliderType.planet.rawValue
            asteroid.zPosition = 1
            
            //add asteroid to scene
            addChild(asteroid)
        }
    }

    //plays explosion sound effect
    private func playExplosionSound(volume: CGFloat) {
        let transformedVolume = Float((volume - 0.04) * 10)
        playSoundFromArray(["b1.mp3", "b2.mp3", "b3.mp3", "b4.mp3"], volume: transformedVolume)
    }
    
    //plays star sound effect
    private func playStarSound() {
        playSoundFromArray(["l1.mp3"], volume: 0.5)
    }
    
    //plays star sound effect
    private func playLevelUpSound() {
        playSoundFromArray(["a1.mp3"], volume: 0.5)
    }
    
    private func playSoundFromArray(_ soundArray : [String], volume: Float) {
        let selectedFileName = soundArray[Int.random(in: 0..<soundArray.count)]

        let backgroundThread = DispatchQueue.global(qos: .background)
        backgroundThread.async { () -> Void in
            do {
                let fileInfo = selectedFileName.components(separatedBy: ".")
                let soundURL = Bundle.main.url(forResource: fileInfo[0], withExtension: fileInfo[1])
                guard let soundURL else {
                    print("Failed to create sound URL from \(selectedFileName)")
                    return
                }
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.volume = volume
                audioPlayer.prepareToPlay()
                
                let playAction = SKAction.run { () -> Void in
                    audioPlayer.play()
                }
                let waitAction = SKAction.wait(forDuration: audioPlayer.duration+1)
                let seq = SKAction.sequence([playAction, waitAction])
                DispatchQueue.main.async {
                    self.run(SKAction.playSoundFileNamed(selectedFileName, waitForCompletion: false))
                    self.run(seq)
                }
            } catch {
                
            }
        }
    }

    private func handleAsteroidCollision(asteroid: SKSpriteNode, intentional: Bool = false) {
        asteroid.texture = TextureFactory.asteroid.node
        asteroid.name = kExplodedName
        asteroid.physicsBody?.isDynamic = false

        if intentional == false {
            levelDelegate?.lifeLost(1)
        }

        playExplosionSound(volume: asteroid.xScale)
    }

    private func handleStarCollision(star: SKNode) {
        star.removeFromParent()

        levelDelegate?.lifeGained(1)
        levelDelegate?.pointsGained(10)

        playStarSound()
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {

    //contact happened between objects
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        let nodes = bodies.map(\.node)

        Task {
            await MainActor.run {
                guard nodes.contains(where: { $0?.name == kPlutoName }) else { return }

                if let asteroid = nodes.first(where: { $0?.name == kAsteroidName }),
                   let asteroid = asteroid as? SKSpriteNode {
                    handleAsteroidCollision(asteroid: asteroid)
                }

                if let star = nodes.first(where: { $0?.name == kStarName }),
                   let star {
                    handleStarCollision(star: star)
                }
            }
        }
    }
}
