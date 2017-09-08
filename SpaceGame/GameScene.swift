//
//  GameScene.swift
//  SpaceGame
//
//  Created by Simon Riemertzon on 2017-09-07.
//  Copyright © 2017 Simon Riemertzon. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var player: SKSpriteNode?
    var fireRate: TimeInterval = 0.5
    var timeSinceFire: TimeInterval = 0
    var lastTimeShotWasFired : TimeInterval = 0

    
    override func didMove(to view: SKView) {
        player = self.childNode(withName: "player") as! SKSpriteNode
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
    
    }
    
    func touchMoved(toPoint pos : CGPoint) {
 
    }
    
    func touchUp(atPoint pos : CGPoint) {
  
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        checkLaser(currentTime - lastTimeShotWasFired)
        lastTimeShotWasFired = currentTime
    }
    
    func checkLaser(_ frameRate:TimeInterval) {
        timeSinceFire += frameRate
        
        if timeSinceFire < fireRate {
            return
        }
    }
    
    
}
