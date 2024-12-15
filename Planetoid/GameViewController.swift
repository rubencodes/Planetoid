//
//  GameViewController.swift
//  Planetoid
//
//  Created by Ruben on 6/17/15.
//  Copyright (c) 2015 Ruben. All rights reserved.
//

import UIKit
import SpriteKit

final class GameViewController: UIViewController, LevelDelegate {

    // MARK: - Internal Properties

    var safeAreaInsets: UIEdgeInsets {
        view.safeAreaInsets
    }
    private(set) var currentLevel = 1
    private(set) var currentScore  = 0
    private(set) var currentHealth = 20

    // MARK: - Private Properties

    @IBOutlet private var playPauseButton : UIButton?
    private var currentScene : SKScene?
    private var scoreTimer : Timer?
    private var state : GameState = .play

    // MARK: - Constants

    private let kInitialHealthValue = 20
    private let kInitialScoreValue  = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loads current level
        loadLevel(currentLevel)
    }

    // MARK: - Internal Functions

    //changes presented scene to a given integer level
    func loadLevel(_ level : Int) {
        currentScene = Level1Scene(size: self.view.frame.size) as SKScene
        if let currentScene = currentScene as? Level1Scene {
            currentScene.levelDelegate = self
        }

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
    
    @objc func score() {
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

    //finished level successfully
    func levelSucceeded() {
        let titles = ["Stellar!", "Rock-star!", "Out of this World!"]
        let titleIndex = Int.random(in: 0..<titles.count)

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
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: optionTitle, style: UIAlertAction.Style.default, handler: { (action) -> Void in
            //change to current level
            self.loadLevel(self.currentLevel)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func pause() {
        self.state = .pause
        self.playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: UIControl.State())
        currentScene?.view?.isPaused = true
        scoreTimer?.invalidate()
    }
    
    func play() {
        self.state = .play
        self.playPauseButton?.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State())
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

    @MainActor var safeAreaInsets: UIEdgeInsets { get }
    @MainActor var currentLevel: Int { get }
    @MainActor var currentScore: Int { get }
    @MainActor var currentHealth: Int { get }

    @MainActor func startScoreTimer()
    @MainActor func lifeLost(_ amount : Int?) -> Int
    @MainActor func lifeGained(_ amount : Int?) -> Int
    @MainActor func pointsGained(_ amount : Int?) -> Int

    @MainActor func levelSucceeded()
}
