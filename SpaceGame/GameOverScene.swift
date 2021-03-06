//
//  GameOverScene.swift
//  SpaceGame
//
//  Created by Simon Riemertzon on 2017-09-13.
//  Copyright © 2017 Simon Riemertzon. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene :SKScene {
    override func didMove(to view: SKView) {
        let scoreLabel: SKLabelNode? = self.childNode(withName: "scoreLabel") as? SKLabelNode
        let enemiesShotLabel: SKLabelNode? = self.childNode(withName: "enemiesShotLabel") as? SKLabelNode
        scoreLabel?.text = "Score: \(score.cleanValue)"
        enemiesShotLabel?.text = "Enemies shot down: \(enemiesShotDown.cleanValue)"
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Add code that restarts game!
    }
}
