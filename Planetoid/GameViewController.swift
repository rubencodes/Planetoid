//
//  GameViewController.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, LevelDelegate {
    var currentHealth = 100
    var currentScene : SKScene?
    var currentLevel = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //gets the current level from storage
        let currentLevel = NSUserDefaults.standardUserDefaults().integerForKey("currentLevel")
        
        //loads current level
        changeLevelTo(currentLevel)
    }
    
    //returns level scene for a given integer level number
    func getLevel(level : Int) -> SKScene {
        let levelScene : SKScene
        switch level {
        case 0...1:
            levelScene = Level1Scene(size: self.view.frame.size) as SKScene
            (levelScene as! Level1Scene).levelDelegate = self
        default:
            levelScene = Level1Scene(size: self.view.frame.size) as SKScene
            (levelScene as! Level1Scene).levelDelegate = self
            break
        }
        
        return levelScene
    }
    
    //changes presented scene to a given integer level
    func changeLevelTo(level : Int) {
        let level = getLevel(currentLevel)
        currentScene = level
        
        // Configure the view.
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        level.scaleMode = .AspectFill
        
        skView.presentScene(level)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .Landscape
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //sent from scene, tells us user lost points
    func pointsLost(points: Int) -> Int {
        currentHealth += points
        
        //if the user is out of points, it's game over.
        if points == 0 {
            currentScene?.view?.paused = true
        }
        
        return currentHealth
    }
    
    //sent from scene, tells us user gained points
    func pointsGained(points: Int) -> Int {
        currentHealth += points
        return currentHealth
    }
    
    func endOfLevel() {
        //pause the current level and update what level we're on
        currentScene?.view?.paused = true
        currentLevel++
        
        //store out progress
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(currentLevel, forKey: "currentLevel")
        defaults.synchronize()
        
        //ask the user before continuing to the next level
        let alert = UIAlertController(title: "Good job!", message: "You've survived this level!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            //get the next level and store it
            let levelScene = self.getLevel(self.currentLevel)
            self.currentScene = levelScene
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

protocol LevelDelegate {
    func pointsLost(points : Int) -> Int
    func pointsGained(points : Int) -> Int
    func endOfLevel()
}