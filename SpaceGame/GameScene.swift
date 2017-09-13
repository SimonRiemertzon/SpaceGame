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
    var player: SKSpriteNode!
    var enemy: SKSpriteNode?
    var spawnedEnemy : SKSpriteNode?
    var item: SKSpriteNode?
    var item2: SKSpriteNode?
    var cameraNode: SKCameraNode?
    
    // Timeintervals and rates
    var fireRate: TimeInterval = 0.3
    var enemyRate: TimeInterval = 1
    var itemRate: TimeInterval = 5
    
    var timeSinceFire: TimeInterval = 0
    var timeSinceLastEnemySpawn: TimeInterval = 0
    var timeSinceLastItemSpawn: TimeInterval = 0
    var lastTimeShotWasFired : TimeInterval = 0
    var lastTimeEnemySpawned : TimeInterval = 0
    var lastTimeItemSpawned : TimeInterval = 0
    
    let nodesToBeRemoved = ["laser", "spawnableItem", "enemy2", "explosion"]
    var scoreLabel: SKLabelNode?
    var score = 0
    
    let cameraOffsetValue: CGFloat = 600
    
    var fallspeed: CGFloat = -200
    
    //var fallspeed:  CGFloat = CGFloat(arc4random_uniform(3001))/10.0 + 100 * -1

    
    
    //Masks
    let noCategory: UInt32 = 0
    let laserCategory:UInt32 = 0b1
    let playerCategory:UInt32 = 0b1 << 1
    let enemyCategory:UInt32 = 0b1 << 2
    let itemCategory:UInt32 = 0b1 << 3
    
    
    
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        // Instansiating variables and setting masks
        scoreLabel = camera?.childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel?.text = "Score: 0"
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = noCategory
        player?.physicsBody?.contactTestBitMask = enemyCategory | itemCategory
        
        enemy = self.childNode(withName: "enemy") as? SKSpriteNode
        enemy?.physicsBody?.categoryBitMask = enemyCategory
        enemy?.physicsBody?.collisionBitMask = noCategory
        enemy?.physicsBody?.contactTestBitMask = playerCategory | laserCategory
        
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
    
    
    
    func didBegin (_ contact: SKPhysicsContact) {
        let categoryA: UInt32 = contact.bodyA.categoryBitMask
        let categoryB: UInt32 = contact.bodyB.categoryBitMask
        
        guard let nodeB = contact.bodyB.node else {
            return
        }
        
        guard let nodeA = contact.bodyA.node else {
            return
        }
        
        if categoryA == playerCategory || categoryB == playerCategory {
            let otherNode: SKNode = (categoryA == playerCategory) ? nodeB : nodeA
            playerDidCollide(with: otherNode)
            
        } else if categoryA == enemyCategory || categoryB == enemyCategory {
            
            let explosion:SKEmitterNode = SKEmitterNode(fileNamed: "Explosion")!
            explosion.position = contact.bodyA.node!.position
            self.addChild(explosion)
            
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
        checkAndSpawnItem(currentTime - lastTimeItemSpawned)
        
        lastTimeShotWasFired = currentTime
        lastTimeEnemySpawned = currentTime
        lastTimeItemSpawned = currentTime

        for node in nodesToBeRemoved {
            self.enumerateChildNodes(withName: node) {
                node, stop in
                if (node is SKSpriteNode) {
                    let sprite = node as! SKSpriteNode
                    
                    if (sprite.position.x > self.frame.size.width
                        //|| sprite.position.x < self.player!.position.x - self.scene!.size.width
                        
                        || sprite.position.y > self.frame.maxY + self.player!.position.y + self.cameraOffsetValue
                        || sprite.position.y < self.frame.minY - self.scene!.size.height
                        )
                    {
                        sprite.removeFromParent()
                    }
                }
            }
        }
        //Making the camera move with the player
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
    
    func checkAndSpawnItem (_ frameRate: TimeInterval) {
        timeSinceLastItemSpawn += frameRate

        if timeSinceLastItemSpawn < enemyRate {
            return
        }
        spawnItem()
        timeSinceLastItemSpawn = 0
    }
    
    func giveRandomNumberBetween(lowerValue:Double, upperValue:Double, oneDecimal:Bool) -> Double{
        var result = Double(arc4random_uniform(UInt32(upperValue - lowerValue + 1))) + lowerValue
        
        if(oneDecimal) {
            result = result / 10
        }
        print("This is the result of randomNumber: \(result)")
        return result
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
        let spriteWidth: CGFloat = 60
        let lowerValue = Int(frame.minX + spriteWidth)
        let upperValue = Int(frame.maxX - spriteWidth)
        let randomXPosition = Int(arc4random_uniform(UInt32(upperValue - lowerValue + 1))) + lowerValue
        let scene:SKScene = SKScene(fileNamed: "EnemySprite")!
        spawnedEnemy = scene.childNode(withName: "enemy2") as? SKSpriteNode
        spawnedEnemy?.physicsBody?.categoryBitMask = enemyCategory
        spawnedEnemy?.physicsBody?.collisionBitMask = noCategory
        spawnedEnemy?.physicsBody?.contactTestBitMask = playerCategory | laserCategory
        spawnedEnemy?.position = CGPoint(x: CGFloat(randomXPosition), y: frame.maxY + player.position.y + cameraOffsetValue)
        spawnedEnemy?.physicsBody?.velocity.dy = fallspeed + CGFloat(giveRandomNumberBetween(lowerValue: -100, upperValue: 0, oneDecimal: false))
        spawnedEnemy?.move(toParent: self)
    }
    
    func spawnItem() {
        itemRate = 5
        let spriteWidth: CGFloat = 60
        let lowerValue = Int(frame.minX + spriteWidth)
        let upperValue = Int(frame.maxX - spriteWidth)
        let randomXPosition = Int(arc4random_uniform(UInt32(upperValue - lowerValue + 1))) + lowerValue
        let scene:SKScene = SKScene(fileNamed: "Item")!
        let spawnedItem = scene.childNode(withName: "spawnableItem") as? SKSpriteNode
        spawnedItem?.position = CGPoint(x: CGFloat(randomXPosition), y: frame.maxY + player.position.y + cameraOffsetValue)
        spawnedItem?.physicsBody?.categoryBitMask = itemCategory
        spawnedItem?.physicsBody?.collisionBitMask = noCategory
        spawnedItem?.physicsBody?.contactTestBitMask = playerCategory
        spawnedItem?.physicsBody?.velocity.dy = fallspeed + CGFloat(giveRandomNumberBetween(lowerValue: -100, upperValue: 0, oneDecimal: false))
        spawnedItem?.move(toParent: self)
        itemRate = itemRate + giveRandomNumberBetween(lowerValue: 11, upperValue: 20, oneDecimal: true)
        print("Itemrate is now: \(itemRate)")
        
    }
}
