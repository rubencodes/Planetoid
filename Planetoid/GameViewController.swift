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
    let kInitialHealthValue = 20
    let kInitialScoreValue  = 0
    var currentHealth = 20
    var currentScore  = 0
    var currentScene : SKScene?
    var currentLevel = 1
    var scoreTimer : NSTimer?
    var state : GameState = .Play
    @IBOutlet var playPauseButton : UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loads current level
        loadLevel(currentLevel)
    }
    
    //returns level scene for a given integer level number
    func getLevel() -> Int {
        return currentLevel
    }
    
    //changes presented scene to a given integer level
    func loadLevel(level : Int) {
        currentScene = Level1Scene(size: self.view.frame.size) as SKScene
        (currentScene as! Level1Scene).levelDelegate = self
        
        //reset the score
        currentHealth = kInitialHealthValue
        
        // Configure the view.
        let skView = self.view as! SKView
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        currentScene!.scaleMode = .AspectFill
        skView.presentScene(currentScene!)
        skView.paused = false
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //begin tracking the score
    func startScoreTimer() {
        scoreTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("score"), userInfo: nil, repeats: true)
    }
    
    func score() {
        ++currentScore
        
        NSNotificationCenter.defaultCenter().postNotificationName("ScoreChangedNotification", object: currentScore)
    }
    
    //sent from scene, tells us user gained points
    func pointsGained(amount : Int?) -> Int {
        currentScore += amount != nil ? amount! : 1
        return currentScore
    }

    //sent from scene, tells us user gained life points
    func lifeGained(amount : Int?) -> Int {
        currentHealth += amount != nil ? amount! : 1
        return currentHealth
    }
    
    //sent from scene, tells us user lost life points
    func lifeLost(amount : Int?) -> Int {
        currentHealth = max(amount != nil ? currentHealth-amount! : currentHealth-1, 0)
        
        //if the user is out of points, it's game over.
        if currentHealth == 0 {
            self.levelFailed()
        }
        
        return currentHealth
    }
    
    //get current health
    func getHealth() -> Int {
        return currentHealth
    }
    
    //get current score
    func getScore() -> Int {
        return currentScore
    }

    //finished level successfully
    func levelSucceeded() {
        let titles = ["Stellar!", "Rock-star!", "Out of this World!"]
        let titleIndex = Int.random(min: 0, max: titles.count-1)
        
        self.presentLevelTransition(title: titles[titleIndex],
            message: "Pluto survived this round with \(currentScore) points!",
            optionTitle: "Continue")
        
        currentLevel++
    }
    
    //gameover
    func levelFailed() {
        self.presentLevelTransition(title: "Bummer",
            message: "You couldn't make it past this wave of asteroids. Better luck next time! Score: \(currentScore), Level: \(currentLevel)",
            optionTitle: "Try Again")
        
        currentLevel = 1
        currentScore = kInitialScoreValue
    }
    
    //option to transition between levels
    func presentLevelTransition(title title: String, message: String, optionTitle: String) {
        currentScene?.view?.paused = true
        scoreTimer?.invalidate()
        
        //ask the user before continuing
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: optionTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            //change to current level
            self.loadLevel(self.currentLevel)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func pause() {
        self.state = .Pause
        self.playPauseButton?.setImage(UIImage(named: "Play"), forState: UIControlState.Normal)
        currentScene?.view?.paused = true
        scoreTimer?.invalidate()
    }
    
    func play() {
        self.state = .Play
        self.playPauseButton?.setImage(UIImage(named: "Pause"), forState: UIControlState.Normal)
        currentScene?.view?.paused = false
        startScoreTimer()
    }
    
    @IBAction func togglePause() {
        if self.state == .Play {
            self.pause()
        } else {
            self.play()
        }
    }
}

enum GameState {
    case Play, Pause
}

protocol LevelDelegate {
    func startScoreTimer()
    func lifeLost(amount : Int?) -> Int
    func lifeGained(amount : Int?) -> Int
    func pointsGained(amount : Int?) -> Int
    
    func getScore() -> Int
    func getHealth() -> Int
    func getLevel() -> Int
    
    func levelSucceeded()
}