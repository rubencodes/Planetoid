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
    var scoreTimer : NSTimer?
    
    override func didMoveToView(view: SKView) {
        print(levelDelegate)
        /* Setup your scene here */
        UIApplication.sharedApplication().idleTimerDisabled = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveUpdatedScore:", name:"ScoreChangedNotification", object: nil)

        //set up game scene
        setupScene()
        
        //start watching the accelerometer
        if motionManager.accelerometerAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.01
        }
    }
    
    //update loop
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        //update pluto according to accelerometer
        processUserMotionForUpdate(currentTime)
        
        //move asteroids
        moveAsteroidsForUpdate()
    }
    
    //gets movement data from accelerometer and updates scene
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        //get our hero, pluto
        let pluto = childNodeWithName(kPlutoName) as! SKSpriteNode
        
        //check if we have the accelerometer data
        if let data = motionManager.accelerometerData {
            //move pluto according to its variation from the baseline
            pluto.physicsBody!.applyForce(CGVectorMake(0, 20.0 * (CGFloat(self.initialState) - CGFloat(data.acceleration.z))))
        }
    }
    
    //move asteroids forward at update loop
    func moveAsteroidsForUpdate() {
        var asteroidsVisible = false //keep track of asteroids
        
        //loop over all asteroids
        self.enumerateChildNodesWithName(kAsteroidName) { node, stop in
            //update their position
            node.position = CGPointMake(node.position.x - (2 * node.speed), node.position.y)
            
            //check if asteroid is still visible
            if node.position.x+node.frame.width > CGRectGetMinX(self.frame) {
                asteroidsVisible = true
            }
            
            let rotateAsteroid = SKAction.rotateByAngle(CGFloat(M_PI_4)/32, duration: 0)
            node.runAction(rotateAsteroid)
        }
        
        //if no asteroid was visible, raise flag for end of level
        if !asteroidsVisible {
            self.levelDelegate?.levelSucceeded()
        }
        
        //loop over exploded asteroids and update their positions, too
        self.enumerateChildNodesWithName(kExplodedName) { node, stop in
            node.position = CGPointMake(node.position.x - 2, node.position.y)
        }
        
        //loop over stars and update their positions, too
        self.enumerateChildNodesWithName(kStarName) { node, stop in
            node.position = CGPointMake(node.position.x - 2, node.position.y)
        }
    }
    
    //contact happened between objects
    func didBeginContact(contact: SKPhysicsContact) {
        if contact as SKPhysicsContact? != nil {
            let nodes     = [contact.bodyA.node!, contact.bodyB.node!]
            let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kAsteroidName) {
                let node = nodes[nodeNames.indexOf(kAsteroidName)!]
                (node as! SKSpriteNode).texture = SKTexture(imageNamed: "Explosion")
                node.name = kExplodedName
                node.physicsBody!.dynamic = false
                let currentLifeLevel = levelDelegate!.lifeLost()
                
                updateLifeLevel(currentLifeLevel)
            }
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kStarName) {
                let node = nodes[nodeNames.indexOf(kStarName)!]
                node.removeFromParent()
                
                let currentLifeLevel = levelDelegate!.lifeGained()
                
                updateLifeLevel(currentLifeLevel)
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
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
        let shiftBackground = SKAction.moveByX(-backgroundTexture.size().width, y: 0, duration: 80)
        let replaceBackground = SKAction.moveByX(backgroundTexture.size().width, y:0, duration: 0)
        let movingAndReplacingBackground = SKAction.repeatActionForever(SKAction.sequence([shiftBackground,replaceBackground]))
        
        for var i:CGFloat = 0; i<3; i++ {
            //defining background; giving it height and moving width
            let background = SKSpriteNode(texture:backgroundTexture)
            background.zPosition = 0
            background.position = CGPoint(x: backgroundTexture.size().width/2 + (backgroundTexture.size().width * i), y: CGRectGetMidY(self.frame))
            background.size.height = self.frame.height
            background.runAction(movingAndReplacingBackground)
            
            self.addChild(background)
        }
    }
    
    func setupFrame() {
        //set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.dynamic = false
        physicsBody!.categoryBitMask = ColliderType.Walls.rawValue
        userInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        //set background, dark blue
        backgroundColor = UIColor(red: 0, green: 0, blue: 140/255, alpha: 1)
    }
    
    func setupHUD() {
        //create health label
        let lifeLabel = SKLabelNode(fontNamed: "Consolas")
        lifeLabel.name = kLifeName
        lifeLabel.fontSize = 25
        lifeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        lifeLabel.position = CGPoint(x: frame.size.width - 10, y: size.height - 40)
        lifeLabel.zPosition = 3
        
        //add label to scene
        addChild(lifeLabel)
        updateLifeLevel((self.levelDelegate?.getHealth())!)
        
        //create score label
        let scoreLabel = SKLabelNode(fontNamed: "CourierNewPS-BoldMT")
        scoreLabel.name = kScoreName
        scoreLabel.fontSize = 25
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
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
        pluto.position = CGPointMake(CGRectGetMinX(self.frame) + pluto.size.width/2 + CGFloat(kPlutoBaseline), CGRectGetMidY(self.frame))
        
        //setup physics body to collide with the wall bounds
        pluto.physicsBody = SKPhysicsBody(circleOfRadius: pluto.frame.width/2)
        pluto.physicsBody!.dynamic = true
        pluto.physicsBody!.affectedByGravity = false
        pluto.physicsBody!.mass = 0.02
        pluto.physicsBody!.restitution = 0
        pluto.physicsBody!.allowsRotation = false
        pluto.physicsBody!.categoryBitMask = ColliderType.Planet.rawValue
        pluto.physicsBody!.collisionBitMask = ColliderType.Walls.rawValue
        pluto.zPosition = 2
        
        //add pluto to scene
        self.addChild(pluto)
    }
    
    func setupStars(starCount : Int) {
        //create starCount stars
        for i in 0...starCount {
            //create a star
            let star = SKSpriteNode(imageNamed: "Star")
            star.name = kStarName
            
            //generate a pseudo-random position
            let sceneLength = CGRectGetMaxX(self.frame)*10
            let starPositionY = CGFloat.random(min: CGRectGetMinY(self.frame), max: CGRectGetMaxY(self.frame))
            let starPositionX = CGFloat.random(min: (CGFloat(i)/CGFloat(starCount))*(sceneLength*0.9), max: sceneLength)
            star.position = CGPointMake(starPositionX, starPositionY)
            
            //fixed scale size
            star.xScale = 0.10
            star.yScale = 0.10
            
            //setup physics body to collide with asteroids, stars and pluto
            star.physicsBody = SKPhysicsBody(circleOfRadius: star.frame.width/2)
            star.physicsBody!.dynamic = true
            star.physicsBody!.affectedByGravity = false
            star.physicsBody!.mass = 0.02
            star.physicsBody!.categoryBitMask    = ColliderType.Stars.rawValue
            star.physicsBody!.contactTestBitMask = ColliderType.Planet.rawValue
            star.physicsBody!.collisionBitMask   = ColliderType.Planet.rawValue
            star.zPosition = 1
            
            //add star to scene
            self.addChild(star)
        }
    }
    
    func setupAsteroids(asteroidCount : Int) {
        //create kAsteroidCount asteroids
        var clearPath = (top : 0.45 as CGFloat, bottom: 0.55 as CGFloat)
        for i in 0...asteroidCount {
            //create a random Asteroid (3 variations)
            let asteroid = SKSpriteNode(imageNamed: "Asteroid-\(Int.random(min: 1, max: 3))")
            asteroid.name = kAsteroidName
            
            //generate a pseudo-random position
            let sceneLength = CGRectGetMaxX(self.frame)*10

            //position asteroids on either side of path we keep clear
            let asteroidPositionY = Bool.random()
                ? CGFloat.random(min: CGRectGetMinY(self.frame), max: CGRectGetMaxY(self.frame)*clearPath.top) //position UP
                : CGFloat.random(min: CGRectGetMaxY(self.frame)*clearPath.bottom, max: CGRectGetMaxY(self.frame)) //position DOWN
            //update clearPath for next round
            let shift = CGFloat.random(min: -0.1, max: 0.1)
            
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
            let asteroidPositionX = CGFloat.random(min: (CGFloat(i)/CGFloat(asteroidCount))*(sceneLength*0.9), max: sceneLength)
            asteroid.position = CGPointMake(asteroidPositionX, asteroidPositionY)
            
            //size and rotate asteroid at random within bounds
            let scale = CGFloat.random(min: 0.05, max: 0.15)
            asteroid.xScale = scale
            asteroid.yScale = scale
            asteroid.zRotation = CGFloat.random(min: 0, max: 360)
            
            //setup physics body to collide with other asteroids, stars and pluto
            asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width/2)
            asteroid.physicsBody!.dynamic = true
            asteroid.physicsBody!.affectedByGravity = false
            asteroid.physicsBody!.mass = 0.02
            asteroid.speed = CGFloat.random(min: 1.3, max: 1.5) //random speed, mostly for later use
            asteroid.physicsBody!.categoryBitMask    = ColliderType.Asteroids.rawValue
            asteroid.physicsBody!.contactTestBitMask = ColliderType.Planet.rawValue
            asteroid.physicsBody!.collisionBitMask   = ColliderType.Planet.rawValue
            asteroid.zPosition = 1
            
            //add asteroid to scene
            self.addChild(asteroid)
        }
    }
    
    //change in life level, update HUD label
    func updateLifeLevel(currentLifeLevel : Int) {
        let lifeLabel = self.childNodeWithName(kLifeName) as! SKLabelNode
        
        lifeLabel.text = String(count: currentLifeLevel, repeatedValue: Character("|"))
        
        if currentLifeLevel <= 5 {
            lifeLabel.fontColor = SKColor.redColor()
        } else if currentLifeLevel <= 10 {
            lifeLabel.fontColor = SKColor.yellowColor()
        } else {
            lifeLabel.fontColor = SKColor.greenColor()
        }
    }
    
    //change in score level, update HUD label
    func updateScoreLevel(currentScore : Int) {
        let scoreLabel = self.childNodeWithName(kScoreName) as! SKLabelNode
        
        scoreLabel.text = String(format: "%05d", currentScore)
        scoreLabel.fontColor = SKColor.greenColor()
    }
    
    //receives notification of updated score
    func receiveUpdatedScore(notification: NSNotification) {
        guard let score = notification.object else {
            return
        }
        
        let currentScore = score as! Int
        updateScoreLevel(currentScore)
    }
}

//collision-capable objects
enum ColliderType: UInt32 {
    case Asteroids = 1
    case Walls  = 2
    case Planet = 4
    case Stars  = 8
}

//generates random Ints and CGFloats
public extension Int {
    public static func random() -> Int {
        return Int(arc4random())
    }
    
    public static func random(n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    public static func random(min min: Int, max: Int) -> Int {
        return Int(arc4random_uniform(UInt32(max - min + 1))) + min
    }
}

public extension CGFloat {
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}

public extension Bool {
    public static func random() -> Bool {
        return round(CGFloat.random())%2 == 0
    }
}