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
    let nodesToBeRemoved = ["laser", "enemy"]
    
    override func didMove(to view: SKView) {
        player = self.childNode(withName: "player") as? SKSpriteNode
    }
    
    

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if(location.y <= 0) {
                player?.run(SKAction.moveTo(x: location.x, duration: 0.2))
            }
            
            
        }
    }

    
    
    override func update(_ currentTime: TimeInterval) {
        checkAndFireLaser(currentTime - lastTimeShotWasFired)
        lastTimeShotWasFired = currentTime
        
        for node in nodesToBeRemoved {
            self.enumerateChildNodes(withName: node) {
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
    }
    
    func checkAndFireLaser(_ frameRate:TimeInterval) {
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
