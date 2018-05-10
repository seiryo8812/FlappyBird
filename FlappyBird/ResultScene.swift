//
//  ResultViewController.swift
//  FlappyBird
//
//  Created by 加島亮成 on 2018/05/08.
//  Copyright © 2018年 加島亮成. All rights reserved.
//

import Foundation
import SpriteKit



class ResultScene: SKScene {
    
    override func didMove(to view: SKView){
        
        let label = SKLabelNode()
        label.text = "result"
        label.position = CGPoint(x:100,y:70)
        self.addChild(label)
    
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first as UITouch? {
            let scene = GameScene(size: self.scene!.size)
            scene.scaleMode = SKSceneScaleMode.aspectFill
            self.view!.presentScene(scene)
        }
    }

}
