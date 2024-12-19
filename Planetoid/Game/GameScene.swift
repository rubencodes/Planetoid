//
//  GameScene.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import AVFoundation
import CoreHaptics
import Foundation
import SpriteKit
import SwiftUI

final class GameScene: SKScene, ObservableObject {

    // MARK: - Nested Types

    /// Collision-capable objects
    enum ColliderType: UInt32 {
        case asteroids = 1
        case walls  = 2
        case planet = 4
        case stars  = 8
    }

    /// Sprite nodes
    enum SpriteFactory: String {
        case pluto
        case star
        case asteroid

        var name: String {
            rawValue
        }

        var size: CGSize {
            switch self {
            case .pluto: return .init(width: 256, height: 247)
            case .star: return .init(width: 48, height: 48)
            case .asteroid: return .init(width: 72, height: 72)
            }
        }

        @MainActor
        var node: SKSpriteNode {
            switch self {
            case .pluto:
                let pluto = SKSpriteNode(imageNamed: "Pluto")
                pluto.name = name
                pluto.size = size

                // scale pluto down (our image is too big)
                pluto.xScale = 0.3
                pluto.yScale = 0.3

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

                return pluto

            case .star:
                let star = SKSpriteNode(imageNamed: "Star")
                star.name = name
                star.size = size

                star.xScale = 0.5
                star.yScale = 0.5

                let rotationDegrees = Int.random(in: 20..<45)
                let maxDegrees = 180 - rotationDegrees
                let angle = Angle(degrees: .init(Int.random(in: 0...maxDegrees)))
                star.zRotation = angle.radians
                star.userData = [
                    "minRotation": angle.degrees,
                    "maxRotation": angle.degrees + Double(rotationDegrees),
                    "isIncreasing": false
                ]

                // setup physics body to collide with asteroids, stars and pluto
                star.physicsBody = SKPhysicsBody(circleOfRadius: star.frame.width / 2)
                star.physicsBody?.isDynamic = true
                star.physicsBody?.affectedByGravity = false
                star.physicsBody?.mass = 0.02
                star.physicsBody?.categoryBitMask    = ColliderType.stars.rawValue
                star.physicsBody?.contactTestBitMask = ColliderType.planet.rawValue
                star.physicsBody?.collisionBitMask   = ColliderType.planet.rawValue
                star.zPosition = 1

                return star

            case .asteroid:
                let asteroid = SKSpriteNode(imageNamed: "Asteroid-\(Int.random(in: 1...10))")
                asteroid.name = name
                asteroid.size = size

                // size and rotate asteroid at random within bounds
                let scale: CGFloat = .random(in: 0.4...0.6)
                asteroid.xScale = scale
                asteroid.yScale = scale
                asteroid.zRotation = Angle(degrees: .random(in: 0...360)).radians

                // setup physics body to collide with other asteroids, stars and pluto
                asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width / 2)
                asteroid.physicsBody?.isDynamic = true
                asteroid.physicsBody?.affectedByGravity = false
                asteroid.physicsBody?.mass = 0.02
                asteroid.physicsBody?.categoryBitMask    = ColliderType.asteroids.rawValue
                asteroid.physicsBody?.contactTestBitMask = ColliderType.planet.rawValue
                asteroid.physicsBody?.collisionBitMask   = ColliderType.planet.rawValue
                asteroid.zPosition = 1

                return asteroid
            }
        }
    }

    /// Texture nodes
    enum TextureFactory: String {
        case explosion
        case background

        var name: String {
            rawValue
        }

        @MainActor
        var node: SKTexture {
            switch self {
            case .explosion:
                let explosion = SKTexture(imageNamed: "Explosion-\(Int.random(in: 1...6))")
                return explosion
            case .background:
                let background = SKTexture(imageNamed: "background")
                return background
            }
        }
    }

    enum SoundEffect {
        case explosion
        case music
        case star

        var fileName: String {
            switch self {
            case .explosion: "explosion-\(Int.random(in: 1...3))"
            case .music: "music"
            case .star: "star"
            }
        }

        var fileExtension: String {
            "mp3"
        }

        var url: URL? {
            Bundle.main.url(forResource: fileName,
                            withExtension: fileExtension)
        }
    }

    /// Different devices have different input capabilities;
    /// Pluto is the main thing a user needs to control, so
    /// whichever of these matches first will be our control.
    private static let drivers: [PlutoDriver.Type] = [
        AccelerometerDriver.self,
        MouseDriver.self,
    ]

    // MARK: - Internal Properties

    var levelDelegate : GameDelegate?
    override var isPaused: Bool {
        get {
            super.isPaused
        }
        set {
            let newValue = levelDelegate?.isPaused ?? newValue
            super.isPaused = newValue

            guard isMusicEnabled else { return }
            if newValue {
                audioPlayer?.pause()
            } else {
                audioPlayer?.play()
            }
        }
    }

    // MARK: - Private Properties

    @AppStorage(GameSettingKey.isMusicEnabled.rawValue) private var isMusicEnabled: Bool = true
    @AppStorage(GameSettingKey.areSoundEffectsEnabled.rawValue) private var areSoundEffectsEnabled: Bool = true
    nonisolated private let kStarCount = 20
    nonisolated private let kStarPerLevelFactor = 5
    nonisolated private let kAsteroidCount = 120
    nonisolated private let kAsteroidPerLevelFactor = 20
    nonisolated private let kPlutoBaseline = 20
    private let initialState: Double = -0.7
    private var scoreTimer: Timer?
    private var driver: PlutoDriver?
    private var audioPlayer: AVAudioPlayer?
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var isInitialized = false

    // MARK: - SKScene

    /// Initial setup
    override func didMove(to view: SKView) {
        guard let levelDelegate, isInitialized == false else {
            return
        }

        isInitialized = true

        // Set up game scene
        setupFrame() // setup level frame
        setupBackground()
        setupMusic()
        setupFeedbackGenerator(view: view)
        setupPluto() // setup the player
        setupPlutoDriver()
        setupAsteroids(level: levelDelegate.currentLevel) // setup obstacles
        setupStars(level: levelDelegate.currentLevel) // setup stars

        levelDelegate.execute(.ready)
    }

    /// Update loop (called before each frame is rendered)
    override func update(_ currentTime: TimeInterval) {
        updatePluto()
        updateAsteroids()
        updateStars(currentTime)
    }

    /// Handle touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       for touch in touches {
           let location = touch.location(in: self)

           enumerateChildNodes(withName: SpriteFactory.asteroid.name) { [weak self] asteroid, stop in
               // update their position
               asteroid.position = CGPointMake(asteroid.position.x - (2 * asteroid.speed),
                                               asteroid.position.y)

               guard asteroid.contains(location),
                     let asteroid = asteroid as? SKSpriteNode else {
                   return
               }

               self?.handleAsteroidCollision(asteroid: asteroid, intentional: true)
           }
        }
    }

    // MARK: - Setup Scene

    private func setupFrame() {
        // set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = ColliderType.walls.rawValue
        isUserInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        // set background, dark blue
        backgroundColor = .primaryBackground
    }

    private func setupBackground() {
        let backgroundTexture = TextureFactory.background.node

        // move background right to left; replace
        let shiftBackground = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 80)
        let replaceBackground = SKAction.moveBy(x: backgroundTexture.size().width, y:0, duration: 0)
        let movingAndReplacingBackground = SKAction.repeatForever(SKAction.sequence([shiftBackground,replaceBackground]))

        for i in 0..<3 {
            // defining background; giving it height and moving width
            let background = SKSpriteNode(texture:backgroundTexture)
            background.zPosition = 0
            background.position = CGPoint(x: backgroundTexture.size().width / 2 + (backgroundTexture.size().width * CGFloat(i)),
                                          y: frame.midY)
            background.size.height = frame.height
            background.run(movingAndReplacingBackground)

            addChild(background)
        }
    }

    private func setupMusic() {
        guard let soundUrl = SoundEffect.music.url else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)

        audioPlayer = try? AVAudioPlayer(contentsOf: soundUrl)
        audioPlayer?.volume = 0.2
        audioPlayer?.prepareToPlay()
    }

    private func setupFeedbackGenerator(view: SKView) {
        feedbackGenerator = UIImpactFeedbackGenerator(view: view)
    }

    private func setupPluto() {
        // create our hero, pluto
        let pluto = SpriteFactory.pluto.node

        // position pluto at the horizontal baseline, center vertically
        pluto.position = CGPoint(x: pluto.size.width / 2 + CGFloat(kPlutoBaseline),
                                 y: frame.midY)
        
        // add pluto to scene
        addChild(pluto)
    }

    private func setupPlutoDriver() {
        Self.drivers.forEach {
            guard driver == nil else { return }
            driver = $0.init(initialState: initialState)
        }
    }

    private func setupStars(level: Int) {
        let starCount = kStarCount + (kStarPerLevelFactor * level)

        // create starCount stars
        for i in 0...starCount {
            // create a star
            let star = SpriteFactory.star.node

            // generate a pseudo-random position
            let sceneLength = frame.maxX * 10
            let starPositionY: CGFloat = .random(in: frame.minY..<frame.maxY)
            let minStarPositionX = (CGFloat(i) / CGFloat(starCount)) * (sceneLength * 0.9)
            let starPositionX: CGFloat = .random(in: minStarPositionX..<sceneLength)
            star.position = CGPoint(x: starPositionX, y: starPositionY)
            
            // add star to scene
            addChild(star)
        }
    }
    
    private func setupAsteroids(level: Int) {
        let asteroidCount = kAsteroidCount + (kAsteroidPerLevelFactor * level)

        // create kAsteroidCount asteroids
        var clearPath: CGFloat = .random(in: 0.45...0.55)
        for i in 0...asteroidCount {
            // create a random Asteroid
            let asteroid = SpriteFactory.asteroid.node

            // generate a pseudo-random position
            let sceneLength = frame.maxX * 10

            // position asteroids on either side of path we keep clear
            let asteroidPositionY: CGFloat = Bool.random()
                ? .random(in: frame.minY...(frame.maxY * (clearPath + 0.05))) // position UP
                : .random(in: (frame.maxY * (clearPath - 0.05))...frame.maxY) // position DOWN

            // update clearPath for next round
            let shift: CGFloat = .random(in: -0.1..<0.1)

            // bound path to top and bottom
            clearPath = max(min(clearPath + shift, 0.95), 0.05)

            // weighs X position towards end of scene so level gets harder
            let minAsteroidPosition: CGFloat = (CGFloat(i) / CGFloat(asteroidCount)) * (sceneLength * 0.9)
            let asteroidPositionX: CGFloat = .random(in: minAsteroidPosition..<sceneLength)
            asteroid.position = CGPoint(x: asteroidPositionX, y: asteroidPositionY)
            asteroid.speed = CGFloat.random(in: 1.3...1.5) // random speed, mostly for later use

            // add asteroid to scene
            addChild(asteroid)
        }
    }

    // MARK: - Update Scene

    private func updatePluto() {
        // get our hero, pluto, and then adjust its position according to the chosen driver.
        guard let pluto = childNode(withName: SpriteFactory.pluto.name) as? SKSpriteNode else {
            return
        }

        pluto.physicsBody?.applyForce(
            CGVector(dx: 0,
                     dy: driver?.readAdjustmentValue() ?? 0)
        )
    }

    private func updateAsteroids() {
        var asteroidsVisible = false // keep track of asteroids

        // loop over all asteroids
        enumerateChildNodes(withName: SpriteFactory.asteroid.name) { [weak self] node, stop in
            // update their position
            node.position = CGPoint(x: node.position.x - (2 * node.speed), y: node.position.y)

            // check if asteroid is still visible
            if node.position.x + node.frame.width > (self?.frame.minX ?? 0) {
                asteroidsVisible = true
            }
        }

        // if no asteroid was visible, raise flag for end of level
        if asteroidsVisible == false {
            playLevelUpSound()
            levelDelegate?.execute(.levelSuccess)
        }

        // loop over exploded asteroids and update their positions, too
        enumerateChildNodes(withName: TextureFactory.explosion.name) { node, stop in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        }
    }

    private func updateStars(_ currentTime: TimeInterval) {
        // loop over stars and update their positions, too
        enumerateChildNodes(withName: SpriteFactory.star.name) { node, _ in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)

            // twinkle twinkle little star
            if let minRotation = node.userData?["minRotation"] as? CGFloat,
               let maxRotation = node.userData?["maxRotation"] as? CGFloat,
               let isIncreasing = node.userData?["isIncreasing"] as? Bool {
                let oldValue = Angle(radians: node.zRotation)
                node.zRotation = if isIncreasing {
                    Angle(degrees: oldValue.degrees + 1).radians
                } else {
                    Angle(degrees: oldValue.degrees - 1).radians
                }
                let newValue = Angle(radians: node.zRotation)

                if round(newValue.degrees) == round(maxRotation) {
                    node.userData?["isIncreasing"] = false
                } else if round(newValue.degrees) == round(minRotation) {
                    node.userData?["isIncreasing"] = true
                }
            }
        }
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {

    // contact happened between objects
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        let nodes = bodies.map(\.node)
        let contactPoint: CGPoint = contact.contactPoint

        Task {
            await MainActor.run {
                feedbackGenerator?.prepare()
                guard nodes.contains(where: { $0?.name == SpriteFactory.pluto.name }) else { return }

                if let asteroid = nodes.first(where: { $0?.name == SpriteFactory.asteroid.name }),
                   let asteroid = asteroid as? SKSpriteNode {
                    handleAsteroidCollision(asteroid: asteroid)
                    feedbackGenerator?.impactOccurred(intensity: asteroid.xScale * 2,
                                                      at: contactPoint)
                }

                if let star = nodes.first(where: { $0?.name == SpriteFactory.star.name }),
                   let star {
                    handleStarCollision(star: star)
                    feedbackGenerator?.impactOccurred(intensity: 0.5,
                                                      at: contactPoint)
                }
            }
        }
    }

    // MARK: - Handle Collisions

    private func handleAsteroidCollision(asteroid: SKSpriteNode, intentional: Bool = false) {
        asteroid.texture = TextureFactory.explosion.node
        asteroid.name = TextureFactory.explosion.name
        asteroid.physicsBody?.isDynamic = false

        if intentional == false {
            levelDelegate?.execute(.loseHealth())
        }

        playExplosionSound(volume: asteroid.xScale)
    }

    private func handleStarCollision(star: SKNode) {
        star.removeFromParent()

        levelDelegate?.execute(.gainHealth())
        levelDelegate?.execute(.gainPoints(amount: 10))

        playStarSound()
    }

    // MARK: - Sound Effects

    /// plays explosion sound effect
    private func playExplosionSound(volume: CGFloat) {
        playSound(.explosion, volume: Float((volume - 0.04) * 10))
    }

    /// plays star sound effect
    private func playStarSound() {
        playSound(.star, volume: 0.5)
    }

    /// plays star sound effect
    private func playLevelUpSound() {
        // playSound.levelUp, volume: 0.5)
    }

    private func playSound(_ sound: SoundEffect, volume: Float) {
        guard areSoundEffectsEnabled else { return }
        let backgroundThread = DispatchQueue.global(qos: .background)
        backgroundThread.async { [weak self] () -> Void in
            guard let soundUrl = sound.url,
                  let audioPlayer = try? AVAudioPlayer(contentsOf: soundUrl) else {
                return
            }
            audioPlayer.volume = volume
            audioPlayer.prepareToPlay()

            let playAction = SKAction.run { () -> Void in
                audioPlayer.play()
            }
            let waitAction = SKAction.wait(forDuration: audioPlayer.duration + 1)
            let seq = SKAction.sequence([playAction, waitAction])
            DispatchQueue.main.async {
                self?.run(SKAction.playSoundFileNamed(sound.fileName, waitForCompletion: false))
                self?.run(seq)
            }
        }
    }
}
