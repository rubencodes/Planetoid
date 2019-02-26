//
//  GameScene.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import SpriteKit
import CoreMotion
import Foundation
import AVFoundation

class Level1Scene: SKScene, SKPhysicsContactDelegate {
    let motionManager: CMMotionManager = CMMotionManager()
    let kAsteroidName = "asteroid"
    let kPlutoName    = "pluto"
    let kStarName     = "star"
    let kExplodedName = "exploded"
    let kScoreName    = "score"
    let kLifeName     = "life"
    
    let kStarCount     = 20
    let kStarPerLevelFactor = 5
    let kAsteroidCount = 120
    let kAsteroidPerLevelFactor = 20
    let kPlutoBaseline = 20
    
    var levelDelegate : LevelDelegate?
    var initialState : Double = -0.7
    var scoreTimer : Timer?
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(Level1Scene.receiveUpdatedScore(_:)), name:NSNotification.Name(rawValue: "ScoreChangedNotification"), object: nil)

        //set up game scene
        setupScene()
        
        //start watching the accelerometer
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.01
        }
    }
    
    //update loop
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        //update pluto according to accelerometer
        processUserMotionForUpdate(currentTime)
        
        //move asteroids
        moveAsteroidsForUpdate()
    }
    
    //gets movement data from accelerometer and updates scene
    func processUserMotionForUpdate(_ currentTime: CFTimeInterval) {
        //get our hero, pluto
        let pluto = childNode(withName: kPlutoName) as! SKSpriteNode
        
        //check if we have the accelerometer data
        if let data = motionManager.accelerometerData {
            //move pluto according to its variation from the baseline
            pluto.physicsBody!.applyForce(CGVector(dx: 0, dy: 20.0 * (CGFloat(self.initialState) - CGFloat(data.acceleration.z))))
        }
    }
    
    //move asteroids forward at update loop
    func moveAsteroidsForUpdate() {
        var asteroidsVisible = false //keep track of asteroids
        
        //loop over all asteroids
        self.enumerateChildNodes(withName: kAsteroidName) { node, stop in
            //update their position
            node.position = CGPoint(x: node.position.x - (2 * node.speed), y: node.position.y)
            
            //check if asteroid is still visible
            if node.position.x+node.frame.width > self.frame.minX {
                asteroidsVisible = true
            }
            
            let rotateAsteroid = SKAction.rotate(byAngle: CGFloat(Double.pi / 4)/32, duration: 0)
            node.run(rotateAsteroid)
        }
        
        //if no asteroid was visible, raise flag for end of level
        if !asteroidsVisible {
//            self.playLevelUpSound()
            self.levelDelegate?.levelSucceeded()
        }
        
        //loop over exploded asteroids and update their positions, too
        self.enumerateChildNodes(withName: kExplodedName) { node, stop in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        }
        
        //loop over stars and update their positions, too
        self.enumerateChildNodes(withName: kStarName) { node, stop in
            node.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        }
    }
    
    //contact happened between objects
    func didBegin(_ contact: SKPhysicsContact) {
        if contact as SKPhysicsContact? != nil {
            let nodes     = [contact.bodyA.node!, contact.bodyB.node!]
            let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kAsteroidName) {
                let node = nodes[nodeNames.index(of: kAsteroidName)!]
                (node as! SKSpriteNode).texture = SKTexture(imageNamed: "Explosion")
                node.name = kExplodedName
                node.physicsBody!.isDynamic = false
                
                let currentLifeLevel = levelDelegate!.lifeLost(1)
                updateLifeLevel(currentLifeLevel)
                
                playExplosionSound(volume: node.xScale)
            }
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kStarName) {
                let node = nodes[nodeNames.index(of: kStarName)!]
                node.removeFromParent()
                
                let currentLifeLevel = levelDelegate!.lifeGained(1)
                updateLifeLevel(currentLifeLevel)
                
                let currentScore = levelDelegate!.pointsGained(10)
                updateScoreLevel(currentScore)
                
                playStarSound()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
//        
//        for touch in touches {
//            let location = touch.locationInNode(self)
//            print(location)
//            self.enumerateChildNodesWithName(kAsteroidName) { node, stop in
//                //update their position
//                node.position = CGPointMake(node.position.x - (2 * node.speed), node.position.y)
//                
//                if(node.containsPoint(location)) {
//                    
//                }
//            }
//        }
    }
    
    func setupScene() {
        let currentLevel = (self.levelDelegate?.getLevel())! as Int
        
        setupFrame() //setup level frame
        setupBackground()
        setupPlayer() //setup pluto and add it to scene
        setupAsteroids(kAsteroidCount + (kAsteroidPerLevelFactor * currentLevel)) //setup obstacles
        setupStars(kStarCount + (kStarPerLevelFactor * currentLevel)) //setup stars
        setupHUD() //setup heads-up display
        
        self.levelDelegate?.startScoreTimer()
    }
    
    func setupBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        //move background right to left; replace
        let shiftBackground = SKAction.moveBy(x: -backgroundTexture.size().width, y: 0, duration: 80)
        let replaceBackground = SKAction.moveBy(x: backgroundTexture.size().width, y:0, duration: 0)
        let movingAndReplacingBackground = SKAction.repeatForever(SKAction.sequence([shiftBackground,replaceBackground]))
        
        for i in 0..<3 {
            //defining background; giving it height and moving width
            let background = SKSpriteNode(texture:backgroundTexture)
            background.zPosition = 0
            background.position = CGPoint(x: backgroundTexture.size().width/2 + (backgroundTexture.size().width * CGFloat(i)), y: self.frame.midY)
            background.size.height = self.frame.height
            background.run(movingAndReplacingBackground)
            
            self.addChild(background)
        }
    }
    
    func setupFrame() {
        //set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody!.isDynamic = false
        physicsBody!.categoryBitMask = ColliderType.walls.rawValue
        isUserInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        //set background, dark blue
        backgroundColor = UIColor(red: 0, green: 0, blue: 140/255, alpha: 1)
    }
    
    func setupHUD() {
        //create health label
        let lifeLabel = SKLabelNode(fontNamed: "Consolas")
        lifeLabel.name = kLifeName
        lifeLabel.fontSize = 25
        lifeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        lifeLabel.position = CGPoint(x: frame.size.width - 10, y: size.height - 40)
        lifeLabel.zPosition = 3
        
        //add label to scene
        addChild(lifeLabel)
        updateLifeLevel((self.levelDelegate?.getHealth())!)
        
        //create score label
        let scoreLabel = SKLabelNode(fontNamed: "CourierNewPS-BoldMT")
        scoreLabel.name = kScoreName
        scoreLabel.fontSize = 25
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: 10, y: size.height - 40)
        scoreLabel.zPosition = 3
        
        //add label to scene
        addChild(scoreLabel)
        updateScoreLevel((self.levelDelegate?.getScore())!)
    }
    
    func setupPlayer() {
        //create our hero, pluto
        let pluto = SKSpriteNode(imageNamed:"Pluto")
        pluto.name = kPlutoName
        
        //scale pluto down (our image is too big)
        pluto.xScale = 0.1
        pluto.yScale = 0.1
        
        //position pluto at the horizontal baseline, center vertically
        pluto.position = CGPoint(x: self.frame.minX + pluto.size.width/2 + CGFloat(kPlutoBaseline), y: self.frame.midY)
        
        //setup physics body to collide with the wall bounds
        pluto.physicsBody = SKPhysicsBody(circleOfRadius: pluto.frame.width/2)
        pluto.physicsBody!.isDynamic = true
        pluto.physicsBody!.affectedByGravity = false
        pluto.physicsBody!.mass = 0.02
        pluto.physicsBody!.restitution = 0
        pluto.physicsBody!.allowsRotation = false
        pluto.physicsBody!.categoryBitMask = ColliderType.planet.rawValue
        pluto.physicsBody!.collisionBitMask = ColliderType.walls.rawValue
        pluto.zPosition = 2
        
        //add pluto to scene
        self.addChild(pluto)
    }
    
    func setupStars(_ starCount : Int) {
        //create starCount stars
        for i in 0...starCount {
            //create a star
            let star = SKSpriteNode(imageNamed: "Star")
            star.name = kStarName
            
            //generate a pseudo-random position
            let sceneLength = self.frame.maxX*10
            let starPositionY = CGFloat.random(self.frame.minY, max: self.frame.maxY)
            let starPositionX = CGFloat.random((CGFloat(i)/CGFloat(starCount))*(sceneLength*0.9), max: sceneLength)
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
            self.addChild(star)
        }
    }
    
    func setupAsteroids(_ asteroidCount : Int) {
        //create kAsteroidCount asteroids
        var clearPath = (top : 0.45 as CGFloat, bottom: 0.55 as CGFloat)
        for i in 0...asteroidCount {
            //create a random Asteroid (3 variations)
            let asteroid = SKSpriteNode(imageNamed: "Asteroid-\(Int.random(1, max: 3))")
            asteroid.name = kAsteroidName
            
            //generate a pseudo-random position
            let sceneLength = self.frame.maxX*10

            //position asteroids on either side of path we keep clear
            let asteroidPositionY = Bool.random()
                ? CGFloat.random(self.frame.minY, max: self.frame.maxY*clearPath.top) //position UP
                : CGFloat.random(self.frame.maxY*clearPath.bottom, max: self.frame.maxY) //position DOWN
            //update clearPath for next round
            let shift = CGFloat.random(-0.1, max: 0.1)
            
            //bound path to top and bottom
            if clearPath.top+shift <= 1 && clearPath.bottom >= 0 {
                clearPath.top    += shift
                clearPath.bottom += shift
            } else if clearPath.top+shift <= 1 {
                clearPath.top    = 0.1
                clearPath.bottom = 0
            } else {
                clearPath.top    = 1
                clearPath.bottom = 0.9
            }
            
            //weighs X position towards end of scene so level gets harder
            let asteroidPositionX = CGFloat.random((CGFloat(i)/CGFloat(asteroidCount))*(sceneLength*0.9), max: sceneLength)
            asteroid.position = CGPoint(x: asteroidPositionX, y: asteroidPositionY)
            
            //size and rotate asteroid at random within bounds
            let scale = CGFloat.random(0.05, max: 0.15)
            asteroid.xScale = scale
            asteroid.yScale = scale
            asteroid.zRotation = CGFloat.random(0, max: 360)
            
            //setup physics body to collide with other asteroids, stars and pluto
            asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width/2)
            asteroid.physicsBody!.isDynamic = true
            asteroid.physicsBody!.affectedByGravity = false
            asteroid.physicsBody!.mass = 0.02
            asteroid.speed = CGFloat.random(1.3, max: 1.5) //random speed, mostly for later use
            asteroid.physicsBody!.categoryBitMask    = ColliderType.asteroids.rawValue
            asteroid.physicsBody!.contactTestBitMask = ColliderType.planet.rawValue
            asteroid.physicsBody!.collisionBitMask   = ColliderType.planet.rawValue
            asteroid.zPosition = 1
            
            //add asteroid to scene
            self.addChild(asteroid)
        }
    }
    
    //change in life level, update HUD label
    func updateLifeLevel(_ currentLifeLevel : Int) {
        let lifeLabel = self.childNode(withName: kLifeName) as! SKLabelNode
        
        lifeLabel.text = String(repeating: "|", count: currentLifeLevel)
        
        if currentLifeLevel <= 5 {
            lifeLabel.fontColor = SKColor.red
        } else if currentLifeLevel <= 10 {
            lifeLabel.fontColor = SKColor.yellow
        } else {
            lifeLabel.fontColor = SKColor.init(red: 1, green: 1, blue: 1, alpha: 0.69)
        }
    }
    
    //change in score level, update HUD label
    func updateScoreLevel(_ currentScore : Int) {
        let scoreLabel = self.childNode(withName: kScoreName) as! SKLabelNode
        
        scoreLabel.text = String(format: "%05d", currentScore)
        scoreLabel.fontColor = SKColor.init(red: 1, green: 1, blue: 1, alpha: 0.69)
    }
    
    //receives notification of updated score
    func receiveUpdatedScore(_ notification: Notification) {
        guard let score = notification.object else {
            return
        }
        
        let currentScore = score as! Int
        updateScoreLevel(currentScore)
    }
    
    //plays explosion sound effect
    func playExplosionSound(volume: CGFloat) {
        //let transformedVolume = Float((volume - 0.04) * 10)
        //playSoundFromArray(["b1.mp3", "b2.mp3", "b3.mp3", "b4.mp3"], volume: transformedVolume)
    }
    
    //plays star sound effect
    func playStarSound() {
        //playSoundFromArray(["l1.mp3"], volume: 0.5)
    }
    
    //plays star sound effect
    func playLevelUpSound() {
        //playSoundFromArray(["a1.mp3"], volume: 0.5)
    }
    
    func playSoundFromArray(_ soundArray : [String], volume: Float) {
        let selectedFileName = soundArray[Int.random(0, max: soundArray.count-1)]
        
        let backgroundThread = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        backgroundThread.async { () -> Void in
//            self.runAction(SKAction.playSoundFileNamed(selectedFileName, waitForCompletion: false))
            do {
                let fileInfo = selectedFileName.components(separatedBy: ".")
                let soundURL = Bundle.main.url(forResource: fileInfo[0], withExtension: fileInfo[1])
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
                audioPlayer.volume = volume
                audioPlayer.prepareToPlay()
                
                let playAction = SKAction.run { () -> Void in
                    audioPlayer.play()
                }
                let waitAction = SKAction.wait(forDuration: audioPlayer.duration+1)
                let seq = SKAction.sequence([playAction, waitAction])
                self.run(seq)
            } catch {
                
            }
        }
    }
}

//collision-capable objects
enum ColliderType: UInt32 {
    case asteroids = 1
    case walls  = 2
    case planet = 4
    case stars  = 8
}

//generates random Ints and CGFloats
public extension Int {
    public static func random() -> Int {
        return Int(arc4random())
    }
    
    public static func random(_ n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    public static func random(_ min: Int, max: Int) -> Int {
        return Int(arc4random_uniform(UInt32(max - min + 1))) + min
    }
}

public extension CGFloat {
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(_ min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}

public extension Bool {
    public static func random() -> Bool {
        return round(CGFloat.random()).truncatingRemainder(dividingBy: 2) == 0
    }
}
