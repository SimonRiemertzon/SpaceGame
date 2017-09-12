//
//  GameScene.swift
//  SpaceGame
//
//  Created by Simon Riemertzon on 2017-09-07.
//  Copyright © 2017 Simon Riemertzon. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Nodes
    var player: SKSpriteNode?
    var enemy: SKSpriteNode?
    var item: SKSpriteNode?
    var item2: SKSpriteNode?
    var cameraNode: SKCameraNode?
    
    // Timeintervals and rates
    var fireRate: TimeInterval = 0.5
    var enemyRate: TimeInterval = 1
    
    var timeSinceLastEnemySpawn: TimeInterval = 0
    var timeSinceFire: TimeInterval = 0
    var lastTimeShotWasFired : TimeInterval = 0
    var lastTimeEnemySpawned : TimeInterval = 0
    
    
    
    let nodesToBeRemoved = ["laser", "enemy"]
    var scoreLabel: SKLabelNode?
    var score = 0
    
    let cameraOffsetValue: CGFloat = 600
    
    var attackSpeed: CGFloat = -200
    
    
    
    //Masks
    let noCategory: UInt32 = 0
    let laserCategory:UInt32 = 0b1
    let playerCategory:UInt32 = 0b1 << 1
    let enemyCategory:UInt32 = 0b1 << 2
    let itemCategory:UInt32 = 0b1 << 3
    
    
    
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        // Instansiating variables and setting masks
        scoreLabel = self.childNode(withName: "scoreLabel") as? SKLabelNode
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = noCategory
        player?.physicsBody?.contactTestBitMask = enemyCategory | itemCategory
        
        enemy = self.childNode(withName: "enemy") as? SKSpriteNode
        enemy?.physicsBody?.categoryBitMask = enemyCategory
        enemy?.physicsBody?.collisionBitMask = noCategory
        enemy?.physicsBody?.contactTestBitMask = playerCategory | laserCategory
        
        
        item = self.childNode(withName: "item") as? SKSpriteNode
        item?.physicsBody?.categoryBitMask = itemCategory
        item?.physicsBody?.collisionBitMask = noCategory
        item?.physicsBody?.contactTestBitMask = playerCategory
        
        item2 = self.childNode(withName: "item2") as? SKSpriteNode
        item2?.physicsBody?.categoryBitMask = itemCategory
        item2?.physicsBody?.collisionBitMask = noCategory
        item2?.physicsBody?.contactTestBitMask = playerCategory
        
        //Setting camera
        cameraNode = self.childNode(withName: "cameraNode") as? SKCameraNode
        camera = cameraNode
        
        
        //Creating actions
        let moveAction: SKAction = SKAction.moveBy(x: -200, y: 0, duration: 2)
        moveAction.timingMode = .easeInEaseOut
        let reversedAction: SKAction = moveAction.reversed()
        let sequence:SKAction = SKAction.sequence([moveAction, reversedAction])
        let repeatAction: SKAction = SKAction.repeatForever(sequence)
        item2?.run(repeatAction, withKey: "itemMove")
        
        
    }
    
    func playerDidCollide(with other: SKNode) {
        
        if other.parent == nil {
            return
        }
        
        let otherCategory = other.physicsBody?.categoryBitMask
        
        if otherCategory == itemCategory {
            let points:Int = other.userData?.value(forKey: "points") as! Int
            score += points
            scoreLabel?.text = "Score: \(score)"
            
            other.removeFromParent()
            
        } else if otherCategory == enemyCategory {
            other.removeFromParent()
            player?.removeFromParent()
        }
    }
    
    func enemyDidCollide(with other: SKNode) {
        if other.parent == nil {
            
        }
        
        let otherCategory = other.physicsBody?.categoryBitMask
        
        for node in self.children {
            if (otherCategory == laserCategory && node.name == "enemy2") {
                let explosion: SKEmitterNode = SKEmitterNode(fileNamed: "Explosion")!
                explosion.position = node.position
                self.addChild(explosion)
            }
            
        }
        
      
    }
    
    func didBegin (_ contact: SKPhysicsContact) {
        let categoryA: UInt32 = contact.bodyA.categoryBitMask
        let categoryB: UInt32 = contact.bodyB.categoryBitMask
        
        if categoryA == playerCategory || categoryB == playerCategory {
            let otherNode: SKNode = (categoryA == playerCategory) ? contact.bodyB.node! : contact.bodyA.node!
            playerDidCollide(with: otherNode)
            
        } else if categoryA == enemyCategory || categoryB == enemyCategory {
            guard let nodeB = contact.bodyB.node else {
                return
            }
            
            guard let nodeA = contact.bodyA.node else {
                return
            }
           
            let otherNode: SKNode = (categoryA == enemyCategory) ? nodeB : nodeA
            enemyDidCollide(with: otherNode)
            
            
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if(location.y < player!.position.y + 200) {
                player?.run(SKAction.moveTo(x: location.x, duration: 0.2))
            }
            
            
        }
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        checkAndFireLaser(currentTime - lastTimeShotWasFired)
        checkAndSpawnEnemy(currentTime - lastTimeEnemySpawned)
        lastTimeShotWasFired = currentTime
        lastTimeEnemySpawned = currentTime
        
        for node in nodesToBeRemoved {
            self.enumerateChildNodes(withName: node) {
                node, stop in
                if (node is SKSpriteNode) {
                    let sprite = node as! SKSpriteNode
                    
                    if (sprite.position.x > self.player!.position.x + self.scene!.size.width
                        || sprite.position.x < self.player!.position.x - self.scene!.size.width
                        || sprite.position.y > self.player!.position.y + self.scene!.size.height
                        || sprite.position.y < self.player!.position.y - self.scene!.size.height
                        )
                    {
                        sprite.removeFromParent()
                    }
                }
            }
        }
        
        cameraNode?.position.y = player!.position.y + cameraOffsetValue
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
    
    func checkAndSpawnEnemy(_ frameRate:TimeInterval) {
        timeSinceLastEnemySpawn += frameRate
        
        if timeSinceLastEnemySpawn < enemyRate {
            return
        }
        spawnEnemy()
        timeSinceLastEnemySpawn = 0
        
    }
    
    func spawnLaser() {
        let scene:SKScene = SKScene(fileNamed: "Laser")!
        let laser = scene.childNode(withName: "laser")!
        laser.move(toParent: self)
        laser.position = player!.position
        laser.physicsBody?.categoryBitMask = laserCategory
        laser.physicsBody?.collisionBitMask = laserCategory
        laser.physicsBody?.contactTestBitMask = enemyCategory
    }
    
    func spawnEnemy() {
        print("Spawning Enem")
        let spriteWidth = 60
        let lowerValue = Int(frame.minX) + spriteWidth
        let upperValue = Int(frame.maxX) - spriteWidth
      
        
        let randomXPosition = Int(arc4random_uniform(UInt32(upperValue - lowerValue + 1))) + lowerValue
        print(randomXPosition)
        
        
        let scene:SKScene = SKScene(fileNamed: "EnemySprite")!
        let spawnedEnemy = scene.childNode(withName: "enemy2")!
        spawnedEnemy.move(toParent: self)
        spawnedEnemy.position = CGPoint(x: CGFloat(randomXPosition), y: player!.position.y + 1500)
        spawnedEnemy.physicsBody?.categoryBitMask = enemyCategory
        spawnedEnemy.physicsBody?.collisionBitMask = noCategory
        spawnedEnemy.physicsBody?.contactTestBitMask = playerCategory | laserCategory
        spawnedEnemy.physicsBody?.velocity.dy = attackSpeed
        
    }
    
    
}
