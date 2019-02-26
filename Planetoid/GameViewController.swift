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
    var scoreTimer : Timer?
    var state : GameState = .play
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
    func loadLevel(_ level : Int) {
        currentScene = Level1Scene(size: self.view.frame.size) as SKScene
        (currentScene as! Level1Scene).levelDelegate = self
        
        //reset the score
        currentHealth = kInitialHealthValue
        
        // Configure the view.
        let skView = self.view as! SKView
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        currentScene!.scaleMode = .aspectFill
        skView.presentScene(currentScene!)
        skView.isPaused = false
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    //begin tracking the score
    func startScoreTimer() {
        scoreTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(GameViewController.score), userInfo: nil, repeats: true)
    }
    
    func score() {
        currentScore += 1
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ScoreChangedNotification"), object: currentScore)
    }
    
    //sent from scene, tells us user gained points
    func pointsGained(_ amount : Int?) -> Int {
        currentScore += amount != nil ? amount! : 1
        return currentScore
    }

    //sent from scene, tells us user gained life points
    func lifeGained(_ amount : Int?) -> Int {
        currentHealth += amount != nil ? amount! : 1
        return currentHealth
    }
    
    //sent from scene, tells us user lost life points
    func lifeLost(_ amount : Int?) -> Int {
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
        let titleIndex = Int.random(0, max: titles.count-1)
        
        self.presentLevelTransition(title: titles[titleIndex],
            message: "Pluto survived this round with \(currentScore) points!",
            optionTitle: "Continue")
        
        currentLevel += 1
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
    func presentLevelTransition(title: String, message: String, optionTitle: String) {
        currentScene?.view?.isPaused = true
        scoreTimer?.invalidate()
        
        //ask the user before continuing
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: optionTitle, style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //change to current level
            self.loadLevel(self.currentLevel)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func pause() {
        self.state = .pause
        self.playPauseButton?.setImage(UIImage(named: "Play"), for: UIControlState())
        currentScene?.view?.isPaused = true
        scoreTimer?.invalidate()
    }
    
    func play() {
        self.state = .play
        self.playPauseButton?.setImage(UIImage(named: "Pause"), for: UIControlState())
        currentScene?.view?.isPaused = false
        startScoreTimer()
    }
    
    @IBAction func togglePause() {
        if self.state == .play {
            self.pause()
        } else {
            self.play()
        }
    }
}

enum GameState {
    case play, pause
}

protocol LevelDelegate {
    func startScoreTimer()
    func lifeLost(_ amount : Int?) -> Int
    func lifeGained(_ amount : Int?) -> Int
    func pointsGained(_ amount : Int?) -> Int
    
    func getScore() -> Int
    func getHealth() -> Int
    func getLevel() -> Int
    
    func levelSucceeded()
}
