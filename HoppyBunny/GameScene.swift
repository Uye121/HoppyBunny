//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Ulric Ye on 6/22/16.
//  Copyright (c) 2016 TestingDummies@_@. All rights reserved.
//

import SpriteKit
enum GameSceneState {
    case Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var hero: SKSpriteNode!
    var scrollLayer: SKNode!
    var obstacleLayer: SKNode!
    var cloud: SKNode!
    var ice: SKNode!
    var scoreLabel: SKLabelNode!
    var buttonRestart: MSButtonNode!
    /* Game management */
    var gameState: GameSceneState = .Active
    var sinceTouch : CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var difficultyTimer: CFTimeInterval = 0
    var points = 0
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
        /* Set reference to scroll layer node */
        scrollLayer = self.childNodeWithName("scrollLayer")
        /* Set reference to obstacle layer node */
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        /* Set reference to cloud layer node */
        cloud = self.childNodeWithName("cloud")
        /* Set reference to ice layer node */
        ice = self.childNodeWithName("ice")
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        /* Set UI connections */
        buttonRestart = self.childNodeWithName("buttonRestart") as! MSButtonNode
        scoreLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        /* Hide restart button */
        buttonRestart.state = .Hidden
        
        /* Setup restart button selection handler */
        buttonRestart.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart game scene */
            skView.presentScene(scene)
            
            
        }
        /* Reset Score label */
        scoreLabel.text = String(points)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Disable touch if game state is not active */
        if gameState != .Active { return }
        /* Reset velocity, helps improve response against cumulative falling velocity */
        hero.physicsBody?.velocity = CGVectorMake(0, 0)
        
        /* Called when a touch begins */
        /* Apply vertical impulse */
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /* Reset touch timer */
        sinceTouch = 0
        hero.physicsBody?.applyImpulse(CGVectorMake(0, 250))
        
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.runAction(flapSFX)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        /* Skip game update if game no longer active */
        if gameState != .Active { return }
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(CGFloat(-20).degreesToRadians(),CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(-2, 2)
        
        /* Update last touch timer */
        sinceTouch+=fixedDelta
        
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(CGFloat(-20).degreesToRadians(),CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(-2, 2)
        
        /* Update last touch timer */
        sinceTouch+=fixedDelta
        /* Process world scrolling */
        scrollWorld()
        updateObstacles()
    }
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        cloud.position.x -= (scrollSpeed * CGFloat(fixedDelta) / 2)
        ice.position.x -= (scrollSpeed * CGFloat(fixedDelta) / 3)
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake( (self.size.width / 2) + ground.size.width, groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convertPoint(newPosition, toNode: scrollLayer)
            }
        }
    }
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
            
        }
        /* Time to add a new obstacle? */
        if spawnTimer >= 1.5 {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = NSBundle.mainBundle().pathForResource("Obstacle", ofType: "sks")
            let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPointMake(352, CGFloat.random(min: 234, max: 382))
//            if difficultyTimer < 20 {
//                randomPosition = CGPointMake(352, CGFloat.random(min: ))
//            }
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
        spawnTimer+=fixedDelta
        difficultyTimer+=fixedDelta
    }
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            /* We can return now */
            return
        }
        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        
        /* Show restart button */
        buttonRestart.state = .Active
        
        /* Create our hero death action */
        let heroDeath = SKAction.runBlock({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            /* Stop hero from colliding with anything else */
            self.hero.physicsBody?.collisionBitMask = 0
        })
        
        /* Run action */
        hero.runAction(heroDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.runAction(shakeScene)
        }
    }
}
