//
//  GameScene.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import SpriteKit
import CoreMotion

class Level1Scene: SKScene, SKPhysicsContactDelegate {
    let motionManager: CMMotionManager = CMMotionManager()
    let kAsteroidName = "asteroid"
    let kPlutoName = "pluto"
    let kStarName  = "star"
    let kExplodedName = "exploded"
    let kScoreName  = "score"
    let kAsteroidCount = 160
    let kStarCount  = 20
    let kPlutoBaseline = 20
    var levelDelegate : LevelDelegate?
    var initialState : Double = -0.7
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.dynamic = false
        physicsBody!.categoryBitMask = ColliderType.Walls.rawValue
        userInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        //set up planet, asteroids, and HUD
        setupScene()
        
        //start watching the accelerometer
        if motionManager.accelerometerAvailable {
            motionManager.startAccelerometerUpdates()
            motionManager.accelerometerUpdateInterval = 0.01
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
                let currentPoints = levelDelegate!.pointsLost(-5)
                
                updateScore(currentPoints)
            }
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kStarName) {
                let node = nodes[nodeNames.indexOf(kStarName)!]
                node.removeFromParent()
                
                let currentPoints = levelDelegate!.pointsGained(5)
                
                updateScore(currentPoints)
            }
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
    
    func setupScene() {
        //set background, dark blue
        backgroundColor = UIColor(red: 0, green: 0, blue: 140/255, alpha: 1)
        
        setupPlayer() //setup pluto and add it to scene
        setupAsteroids() //setup asteroids and add to scene
        setupStars()  //setup stars
        setupHUD()    //setup heads-up display
    }
    
    func setupHUD() {
        //create health label
        let scoreLabel = SKLabelNode(fontNamed: "Consolas")
        scoreLabel.name = kScoreName
        scoreLabel.fontSize = 25
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        scoreLabel.position = CGPoint(x: frame.size.width - 20, y: size.height - 40)
        
        //add label to scene
        addChild(scoreLabel)
        
        updateScore(100)
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
        
        //add pluto to scene
        self.addChild(pluto)
    }
    
    func setupStars() {
        //create kStarCount stars
        for i in 0...kStarCount {
            //create a star
            let star = SKSpriteNode(imageNamed: "Star")
            star.name = kStarName
            
            //generate a pseudo-random position
            let sceneLength = CGRectGetMaxX(self.frame)*10
            let starPositionY = CGFloat.random(min: CGRectGetMinY(self.frame), max: CGRectGetMaxY(self.frame))
            let starPositionX = CGFloat.random(min: (CGFloat(i)/CGFloat(kStarCount))*(sceneLength*0.9), max: sceneLength)
            star.position = CGPointMake(starPositionX, starPositionY)
            
            //fixed scale size
            star.xScale = 0.10
            star.yScale = 0.10
            
            //setup physics body to collide with asteroids, stars and pluto
            star.physicsBody = SKPhysicsBody(circleOfRadius: star.frame.width/2)
            star.physicsBody!.dynamic = true
            star.physicsBody!.affectedByGravity = false
            star.physicsBody!.mass = 0.02
            star.physicsBody!.categoryBitMask = ColliderType.Stars.rawValue
            star.physicsBody!.contactTestBitMask = ColliderType.Planet.rawValue
            star.physicsBody!.collisionBitMask = ColliderType.Planet.rawValue
            
            //add star to scene
            self.addChild(star)
        }
    }
    
    func setupAsteroids() {
        //create kAsteroidCount asteroids
        var clearPath = (top : 0.45 as CGFloat, bottom: 0.55 as CGFloat)
        for i in 0...kAsteroidCount {
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
            let asteroidPositionX = CGFloat.random(min: (CGFloat(i)/CGFloat(kAsteroidCount))*(sceneLength*0.9), max: sceneLength)
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
            asteroid.physicsBody!.categoryBitMask = ColliderType.Asteroids.rawValue
            asteroid.physicsBody!.contactTestBitMask = ColliderType.Planet.rawValue
            asteroid.physicsBody!.collisionBitMask = ColliderType.Planet.rawValue
            
            //add asteroid to scene
            self.addChild(asteroid)
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
        }
        
        //if no asteroid was visible, raise flag for end of level
        if !asteroidsVisible {
            self.levelDelegate?.endOfLevel()
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        //        for touch in touches {
        //            let location = touch.locationInNode(self)
        //            print(location)
        //        }
    }
    
    //change in score, update HUD label
    func updateScore(currentPoints : Int) {
        let scoreLabel = self.childNodeWithName(kScoreName) as! SKLabelNode
        
        let scoreCount = currentPoints/5
        scoreLabel.text = String(count: scoreCount, repeatedValue: Character("|"))
        
        if scoreCount <= 5 {
            scoreLabel.fontColor = SKColor.redColor()
        } else if scoreCount <= 15 {
            scoreLabel.fontColor = SKColor.yellowColor()
        } else {
            scoreLabel.fontColor = SKColor.greenColor()
        }
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