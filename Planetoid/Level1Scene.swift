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
    let kCometName = "comet"
    let kPlutoName = "pluto"
    let kExplodedName = "exploded"
    let kScoreName = "score"
    let kCometCount = 120
    let kPlutoBaseline = 20
    var levelDelegate : LevelDelegate?
    var initialState : Double?
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //set up boundaries around frame
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.dynamic = false
        physicsBody!.categoryBitMask = ColliderType.Walls.rawValue
        userInteractionEnabled = true
        physicsWorld.contactDelegate = self
        
        //set up planet, comets, and HUD
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
            
            if nodeNames.contains(kPlutoName) && nodeNames.contains(kCometName) {
                let node = nodes[nodeNames.indexOf(kCometName)!]
                (node as! SKSpriteNode).texture = SKTexture(imageNamed: "Explosion")
                node.name = kExplodedName
                node.physicsBody!.dynamic = false
                let currentPoints = levelDelegate!.pointsLost(-5)
                
                let scoreLabel = self.childNodeWithName(kScoreName) as! SKLabelNode
                scoreLabel.text = "Health \(currentPoints)%"
            }
        }
    }
    
    //update loop
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        //update pluto according to accelerometer
        processUserMotionForUpdate(currentTime)
        
        //move comets
        moveCometsForUpdate()
    }
    
    //gets movement data from accelerometer and updates scene
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        //get our hero, pluto
        let pluto = childNodeWithName(kPlutoName) as! SKSpriteNode
        
        //check if we have the accelerometer data
        if let data = motionManager.accelerometerData {
            //set a baseline for the accelerometer
            if self.initialState == nil {
                self.initialState = data.acceleration.z
            }
            
            //move pluto according to its variation from the baseline
            pluto.physicsBody!.applyForce(CGVectorMake(0, 20.0 * (CGFloat(self.initialState!) - CGFloat(data.acceleration.z))))
        }
    }
    
    func setupScene() {
        //set background, dark blue
        backgroundColor = UIColor(red: 0, green: 0, blue: 140/255, alpha: 1)
        
        setupPlayer() //setup pluto and add it to scene
        setupComets() //setup comets and add to scene
        setupHUD()    //setup heads-up display
    }
    
    func setupHUD() {
        //create health label
        let scoreLabel = SKLabelNode(fontNamed: "Futura")
        scoreLabel.name = kScoreName
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.text = "Health 100%"
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        scoreLabel.position = CGPoint(x: frame.size.width - 20, y: size.height - 40)
        
        //add label to scene
        addChild(scoreLabel)
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
    
    func setupComets() {
        //create kCometCount comets
        for var i in 0...kCometCount {
            //create a random comet (3 variations)
            let comet = SKSpriteNode(imageNamed: "Comet-\(Int.random(min: 1, max: 3))")
            comet.name = kCometName
            
            //generate a pseudo-random position (weighted towards end of scene)
            let sceneLength = CGRectGetMaxX(self.frame)*10
            let cometPositionY = CGFloat.random(min: CGRectGetMinY(self.frame), max: CGRectGetMaxY(self.frame))
            let cometPositionX = CGFloat.random(min: ((max(CGFloat(i)-20, 1))/CGFloat(kCometCount))*(sceneLength*0.9), max: sceneLength)
            comet.position = CGPointMake(cometPositionX, cometPositionY)
            
            
            //size and rotate comet at random within bounds
            let scale = CGFloat.random(min: 0.05, max: 0.15)
            comet.xScale = scale
            comet.yScale = scale
            comet.zRotation = CGFloat.random(min: 0, max: 360)
            
            //setup physics body to collide with other comets and pluto
            comet.physicsBody = SKPhysicsBody(circleOfRadius: comet.frame.width/2)
            comet.physicsBody!.dynamic = true
            comet.physicsBody!.affectedByGravity = false
            comet.physicsBody!.mass = 0.02
            comet.physicsBody!.categoryBitMask = ColliderType.Comets.rawValue
            comet.physicsBody!.contactTestBitMask = ColliderType.Planet.rawValue
            comet.physicsBody!.collisionBitMask = ColliderType.Planet.rawValue | ColliderType.Comets.rawValue
            
            //add comet to scene
            self.addChild(comet)
        }
    }
    
    //move comets forward at update loop
    func moveCometsForUpdate() {
        var cometsVisible = false //keep track of comets
        
        //loop over all comets
        self.enumerateChildNodesWithName(kCometName) { node, stop in
            //update their position
            node.position = CGPointMake(node.position.x - 1, node.position.y)
            
            //check if comet is still visible
            if node.position.x > CGRectGetMinX(self.frame) {
                cometsVisible = true
            }
        }
        
        //if no comet was visible, raise flag for end of level
        if !cometsVisible {
            self.levelDelegate?.endOfLevel()
        }
        
        //loop over exploded comets and update their positions, too
        self.enumerateChildNodesWithName(kExplodedName) { node, stop in
            node.position = CGPointMake(node.position.x - 1, node.position.y)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        //        for touch in touches {
        //            let location = touch.locationInNode(self)
        //            print(location)
        //        }
    }
}

//collision-capable objects
enum ColliderType: UInt32 {
    case Comets = 1
    case Walls  = 2
    case Planet = 4
}

//generates random Ints and CGFloats
public extension Int {
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