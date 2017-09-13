//
//  MenuVC.swift
//  SpaceGame
//
//  Created by Simon Riemertzon on 2017-09-13.
//  Copyright © 2017 Simon Riemertzon. All rights reserved.
//

import Foundation
import UIKit

class MenuVC : UIViewController {
    /*
    enum gameType {
        case: easy
        case: medium
        case: hard
        
    }
 */

    
    @IBAction func startGame(_ sender: UIButton) {
        let gameVC = self.storyboard?.instantiateViewController(withIdentifier: "gameVC") as! GameViewController
        self.navigationController?.pushViewController(gameVC, animated: true)
    }
    
    /*
    func moveToGame(gameType) {
        
    }
    */
}
