//
//  GameScene.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import Combine
import SpriteKit
import CoreMotion
import Foundation
import AVFoundation

final class Level1Scene: SKScene, ObservableObject {

    // MARK: - Nested Types

    /// Collision-capable objects
    enum ColliderType: UInt32 {
        case asteroids = 1
        case walls  = 2
        case planet = 4
        case stars  = 8
    }

    // MARK: - Internal Properties

    var levelDelegate : LevelDelegate?

    // MARK: - Private Properties

    private let motionManager: CMMotionManager = CMMotionManager()
    nonisolated private let kAsteroidName = "asteroid"
    nonisolated private let kPlutoName    = "pluto"
    nonisolated private let kStarName     = "star"
    nonisolated private let kExplodedName = "exploded"
    nonisolated private let kScoreName    = "score"
    nonisolated private let kLifeName     = "life"
    nonisolated private let kStarCount     = 20
    nonisolated private let kStarPerLevelFactor = 5
    nonisolated private let kAsteroidCount = 120
    nonisolated private let kAsteroidPerLevelFactor = 20
    nonisolated private let kPlutoBaseline = 20
    private var initialState : Double = -0.7
    private var scoreTimer : Timer?

    // MARK: - SKScene

    /// Initial setup
    override func didMove(to view: SKView) {

        // Set up game scene
        setupScene()

        // Start watching the accelerometer
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.01
        }
    }

    /// Update loop
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */

        //update pluto according to accelerometer
        processUserMotionForUpdate(currentTime)

        //move asteroids
        moveAsteroidsForUpdate()
    }

    /// Handle touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       for touch in touches {
            let location = touch.location(in: self)
            enumerateChildNodes(withName: kAsteroidName) { node, stop in
                //update their position
                node.position = CGPointMake(node.position.x - (2 * node.speed), node.position.y)

                if node.contains(location) {

                }
            }
        }
    }

    // MARK: - Private Functions

    /// Gets movement data from accelerometer and updates scene
    private func processUserMotionForUpdate(_ currentTime: CFTimeInterval) {
        //get our hero, pluto, and the accelerometer data
        guard let pluto = childNode(withName: kPlutoName) as? SKSpriteNode,
              let data = motionManager.accelerometerData else {
            return
        }

        //move pluto according to its variation from the baseline
        pluto.physicsBody?.applyForce(
            CGVector(dx: 0,
                     dy: 20.0 * (CGFloat(initialState) - CGFloat(data.acceleration.z)))
        )
    }
    
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
        if !asteroidsVisible {
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
        let backgroundTexture = SKTexture(imageNamed: "background")
        
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
        backgroundColor = UIColor(red: 0, green: 0, blue: 140/255, alpha: 1)
    }
    
    private func setupPlayer() {
        //create our hero, pluto
        let pluto = SKSpriteNode(imageNamed:"Pluto")
        pluto.name = kPlutoName
        
        //scale pluto down (our image is too big)
        pluto.xScale = 0.1
        pluto.yScale = 0.1
        
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
            let star = SKSpriteNode(imageNamed: "Star")
            star.name = kStarName
            
            //generate a pseudo-random position
            let sceneLength = frame.maxX * 10
            let starPositionY: CGFloat = .random(in: frame.minY..<frame.maxY)
            let minStarPositionX = (CGFloat(i) / CGFloat(starCount)) * (sceneLength * 0.9)
            let starPositionX: CGFloat = .random(in: minStarPositionX..<sceneLength)
            star.position = CGPoint(x: starPositionX, y: starPositionY)
            
            //fixed scale size
            star.xScale = 0.10
            star.yScale = 0.10
            
            //setup physics body to collide with asteroids, stars and pluto
            star.physicsBody = SKPhysicsBody(circleOfRadius: star.frame.width/2)
            star.physicsBody!.isDynamic = true
            star.physicsBody!.affectedByGravity = false
            star.physicsBody!.mass = 0.02
            star.physicsBody!.categoryBitMask    = ColliderType.stars.rawValue
            star.physicsBody!.contactTestBitMask = ColliderType.planet.rawValue
            star.physicsBody!.collisionBitMask   = ColliderType.planet.rawValue
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
            //create a random Asteroid (3 variations)
            let asteroid = SKSpriteNode(imageNamed: "Asteroid-\(Int.random(in: 1..<3))")
            asteroid.name = kAsteroidName
            
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
            let scale: CGFloat = .random(in: 0.05...0.15)
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
}

// MARK: - SKPhysicsContactDelegate

extension Level1Scene: SKPhysicsContactDelegate {

    //contact happened between objects
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        let nodes = bodies.map(\.node)

        Task {
            await MainActor.run {
                guard let levelDelegate, nodes.contains(where: { $0?.name == kPlutoName }) else { return }

                if let asteroid = nodes.first(where: { $0?.name == kAsteroidName }),
                   let asteroid = asteroid as? SKSpriteNode {
                    asteroid.texture = SKTexture(imageNamed: "Explosion")
                    asteroid.name = kExplodedName
                    asteroid.physicsBody?.isDynamic = false

                    levelDelegate.lifeLost(1)
                    playExplosionSound(volume: asteroid.xScale)
                }

                if let star = nodes.first(where: { $0?.name == kStarName }),
                   let star {
                    star.removeFromParent()

                    levelDelegate.lifeGained(1)
                    levelDelegate.pointsGained(10)

                    playStarSound()
                }
            }
        }
    }
}
