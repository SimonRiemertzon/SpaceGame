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
        player = self.childNode(withName: "player") as? SKSpriteNode
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
        
        /*
         self.enumerateChildNodes , need to scale better. I want to do this for both enemies and lasers.
       */
        self.enumerateChildNodes(withName: "laser") {
            node, stop in
            if (node is SKSpriteNode) {
                let sprite = node as! SKSpriteNode
                
                if (sprite.position.x > self.size.width
                    || sprite.position.x < -self.size.width
                    || sprite.position.y > self.size.height
                    || sprite.position.y < -self.size.height
                    )
                {
                    sprite.removeFromParent()
                }
            }
        }
        
     
        
    }
    
    func checkLaser(_ frameRate:TimeInterval) {
        timeSinceFire += frameRate
        
        if timeSinceFire < fireRate {
            return
        }
        
        spawnLaser()
        //reset timer
        timeSinceFire = 0
    }
    
    func spawnLaser() {
        let scene:SKScene = SKScene(fileNamed: "Laser")!
        let laser = scene.childNode(withName: "laser")!
        laser.move(toParent: self)
        laser.position = player!.position
        
    }
    
    
}
