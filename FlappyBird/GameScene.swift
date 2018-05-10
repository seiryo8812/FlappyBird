//
//  GameScene.swift
//  FlappyBird
//
//  Created by 加島亮成 on 2018/04/29.
//  Copyright © 2018年 加島亮成. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate ,AVAudioPlayerDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var coinNode:SKNode!
    
    
    let coinSound = SKAction.playSoundFileNamed("coinSound.mp3", waitForCompletion: true)
    
    
    
    
    //    衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory:UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let coinCategory: UInt32 = 1 << 3
    let scoreCategory: UInt32 = 1 << 4
    
    //    スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //    アイテムスコア用
    var aitemscore = 0
    var aitemscoreLabelNode:SKLabelNode!
    
    //    SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView){
        
        //        重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        //        背景色を設定
        backgroundColor =  UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //        スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //        壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //        コイン用のノード
        coinNode = SKNode()
        scrollNode.addChild(coinNode)
        
        
        
        
        //        各種スプライトをを生成する処理をメソッドに分割
        setupGround()
        setuoCloud()
        setupWall()
        setupBird()
        setupCoin()
        setupScoreLabel()
        
    }
    
    
    func setupCoin() {
        //            コインの画像を読み込む
        let coinTexture = SKTexture(imageNamed: "coin")
        coinTexture.filteringMode = .nearest
        //        移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + coinTexture.size().width)
        
        //        画面外まで移動するアクションを作成
        let moveCoin = SKAction.moveBy(x: -movingDistance - 80  , y: 0, duration: 4.5)
        
        //        自身を取り除くアクションを作成
        let removeCoin = SKAction.removeFromParent()
        
        //        二つのアニメーションを順に実行するアクションを作成
        let coinAnimation = SKAction.sequence([moveCoin, removeCoin])
        
        //        コインを生成するアクションを作成
        let createCoinAnimation = SKAction.run({
            //            コイン関連のノードを乗せるノードを作成
            let coin = SKNode()
            coin.position = CGPoint(x: self.frame.size.width + coinTexture.size().width / 2, y: 0.0)
            coin.zPosition = 0.0//雲より手前、地面より奥
            
            //            画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //            コインのY座標を上下ランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 4
            //            コインのY軸の下限
            let under_coin_lowest_y = UInt32( center_y - coinTexture.size().height / 2 - random_y_range / 4)
            //            1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range))
            //            Y軸の下限にランダムな値を足して、下のコインのY座標を決定
            let under_coin_y = CGFloat(under_coin_lowest_y + random_y)
            
            //            コインを作成
            let under = SKSpriteNode(texture: coinTexture)
            under.position = CGPoint(x:80.0, y: under_coin_y)
            coin.addChild(under)
            
            //            スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody (rectangleOf: coinTexture.size())
            under.physicsBody?.categoryBitMask = self.coinCategory
            //        衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            
            
            //            スコアアップ用のノード
            let aitemscoreNode = SKNode()
            aitemscoreNode.position = CGPoint(x: under.size.width + self.bird.size.width / 2, y:self.frame.height / 2.0)
            
            
            aitemscoreNode.physicsBody?.isDynamic = false
            aitemscoreNode.physicsBody?.categoryBitMask = self.coinCategory
            aitemscoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            coin.addChild(aitemscoreNode)
            
            coin.run(coinAnimation)
            
            self.coinNode.addChild(coin)
        })
        
        //        次のコイン作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //        コインを作成 ->待ち時間->コインを作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createCoinAnimation,waitAnimation]))
        
        coinNode.run(repeatForeverAnimation)
        
        
        
    }
    
    
    
    
    
    
    func setupGround(){
        //            地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //        必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //        スクロールするアクションを作成
        //        左方向に画像１枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width ,y: 0, duration: 5.0)
        
        
        //        元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        
        //        左スクロール->元の位置->左スクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //        groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //            スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width * (CGFloat(i) + 0.5),
                y: groundTexture.size().height * 0.5
            )
            //            スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //            スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //            衝突のカテゴリーを設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //            衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            //            スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
    func setuoCloud() {
        
        //        雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //        必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        //        スクロールするアクションを作成
        //        左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width ,y: 0,duration: 20.0)
        
        //        元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0,duration: 0.0)
        
        //        左にスクロール ->元の位置 ->左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //       スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //            スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            
            //            スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //            スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupWall() {
        //        壁の画像を読み込む
        let wallTextrue = SKTexture(imageNamed: "wall")
        wallTextrue.filteringMode = .linear
        
        //        移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTextrue.size().width)
        
        //        画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        //        自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //        二つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //        壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //            壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTextrue.size().width / 2,y:0.0)
            wall.zPosition = -50.0//雲より手前、地面より奥
            
            //            画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            //            壁のY座標を上下ランダムにさせる時の最大値
            let random_y_range = self.frame.size.height / 4
            //            下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTextrue.size().height / 2 - random_y_range / 2)
            //            1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range))
            //            Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            //            キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 6
            
            //            下側の壁を作成
            let under = SKSpriteNode(texture: wallTextrue)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            //            スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody (rectangleOf: wallTextrue.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            //        衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            //            上側の壁を作成
            let upper = SKSpriteNode(texture: wallTextrue)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTextrue.size().height + slit_length)
            //            スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody (rectangleOf: wallTextrue.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            //        衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //            スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: under.size.width + self.bird.size.width / 2, y:self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //        次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //        壁を作成 ->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        let birdTeXtureA = SKTexture(imageNamed:"bird_a")
        birdTeXtureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed:"bird_b")
        birdTextureB.filteringMode = .linear
        
        //        二種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTeXtureA,birdTextureB],timePerFrame:0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //        スプライトを作成
        bird = SKSpriteNode(texture:birdTeXtureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //        物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        //        衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //        衝突のカテゴリーを設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | coinCategory
        
        
        //        アニメーションを設定
        bird.run(flap)
        
        //        スプライトを追加する
        addChild(bird)
    }
    //    画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            //       鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            //        鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0,dy:15))
        }else if bird.speed == 0 {
            restart()
        }
    }
    
    //    SKPhisicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact){
        if scrollNode.speed <= 0 {
            return
        }
        
        
        if ( contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //            スコア用の物体と衝突した
            print("scoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            
            
            //            ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
                
            }
        }else if ( contact.bodyA.categoryBitMask & coinCategory) == coinCategory || (contact.bodyB.categoryBitMask & coinCategory) == coinCategory {
            
            
            contact.bodyA.node?.removeFromParent()
            
            self.run(coinSound)
            
            
            print("AitemscoreUp")
            aitemscore += 1
            aitemscoreLabelNode.text = "AitemScore:\(aitemscore)"
        }else{
            //            壁か地面と衝突した
            print("GameOver")
            
            
            //            スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle:CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01 , duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
                
                
            })
        }
        
        
        
    }
    
    
    
    
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        
        aitemscore = 0
        aitemscoreLabelNode.text = String("Aitem Score:\(aitemscore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2,y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 //一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        aitemscore = 0
        aitemscoreLabelNode = SKLabelNode()
        aitemscoreLabelNode.fontColor = UIColor.black
        aitemscoreLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 120)
        aitemscoreLabelNode.zPosition = 100 //一番手前に表示する
        aitemscoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        aitemscoreLabelNode.text = "Aitem Score:\(aitemscore)"
        self.addChild(aitemscoreLabelNode)
    }
    
    
    
    
    
}