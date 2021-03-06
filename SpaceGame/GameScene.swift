//
//  GameScene.swift
//  SpaceGame
//
//  Created by Simon Riemertzon on 2017-09-07.
//  Copyright © 2017 Simon Riemertzon. All rights reserved.
//

import SpriteKit
import GameplayKit

extension Float {
    var cleanValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.f", self) : String(self)
    }
}

//Public variables
var multiplyer: Float = 1.0
var enemiesShotDown: Float = 0
var score: Float = 0

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
    
    //Labels
    var scoreLabel: SKLabelNode?
    var multiplyerLabel: SKLabelNode?

    //Quality of programmer-life values
    let cameraOffsetValue: CGFloat = 600
    var fallspeed: CGFloat = -200

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
        multiplyerLabel = camera?.childNode(withName: "multiplyerLabel") as? SKLabelNode
        multiplyerLabel?.text = "Multiplyer: 0"
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = noCategory
        player?.physicsBody?.contactTestBitMask = enemyCategory | itemCategory
        
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
            let points:Float = other.userData?.value(forKey: "points") as! Float
            score += points * multiplyer
            scoreLabel?.text = "Score: \(score.cleanValue)"
            other.removeFromParent()
        } else if otherCategory == enemyCategory {
            self.removeAllChildren()
            let gameOverScene = GameOverScene(fileNamed: "GameOverScene")
            gameOverScene?.scaleMode = .aspectFill
            self.view?.presentScene(gameOverScene!, transition: SKTransition.fade(withDuration: 0.5))
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
            multiplyer += 0.1
            enemiesShotDown += 1
            multiplyerLabel?.text = "Multiplyer: \(multiplyer.cleanValue)"
            
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
        
      
    }
}
