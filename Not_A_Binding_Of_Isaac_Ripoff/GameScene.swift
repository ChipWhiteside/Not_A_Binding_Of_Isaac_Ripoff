//
//  GameScene.swift
//  Not_A_Binding_Of_Isaac_Ripoff
//
//  Created by Chip Whiteside on 12/9/19.
//  Copyright © 2019 Chip Whiteside. All rights reserved.
//

import SpriteKit

//delay = dispatchTime.now + second(1.0
//dispatchQueue.main.asyncAfter(deadline: delay

enum CollisionTypes: UInt32 {
    case player = 1
    case door = 2
    case enemy = 4
    case bullet = 8
    case chest = 16
    case coin = 32
    case key = 64
    case stairs = 128
    case upgrade = 256
}

struct Player {
    var speed: Int = 4
    var health: Int = 100
    var bulletType: Int = 0
    var bulletDamage: Int = 10
    var coins: Int = 0
    var keys: Int = 0
    var spriteNode: SKSpriteNode?
    var score: Int = 0
}

struct Enemy {
    var arrayIndex: Int = 0
    var speed: Double = 2.0
    var health: Int = 40
    var damage: Int = 10
    var dropChance: Int = 25 // out of 100
    var spriteNode: SKSpriteNode?
    var pos: CGPoint?
    var score: Int = 10
}

struct Door {
    var room: (Int, Int) = (0, 0)
    var next: (Int, Int) = (0, 0)
    var nextID: Int = 0
    var key: Bool = false
    var open: Bool = false
    var pos: CGPoint?
    var node: SKSpriteNode?
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var background: SKSpriteNode?
    var playerNode: SKSpriteNode?
    var thePlayer: Player?
    var bulletDistance: CGFloat = 0.0
    var shooting: Bool = false
    var bulletDirection: Int = 4
    var bulletID: Int = 0
    var prevDir: Int = 4
    var gameMap: [[Int]] = []
    let moveJoystick = 🕹(withDiameter: 100)
    let rotateJoystick = TLAnalogJoystick(withDiameter: 100)
    var bulletTimer: Timer?
    var enemySpawns: [CGPoint] = []
    var spawnedEnemies: [Bool] = [false, false, false, false, false, false, false, false, false, false, false, false]
    var enemyStructs: [Enemy] = []
    var theBoss: Enemy?
    var roomDoors: [Door] = []
    var fader = SKSpriteNode()
    var dummy: [[Int]] = []
    var healthBar: SKSpriteNode?
    var scoreLabel: SKLabelNode?
    var coinLabel: SKLabelNode?
    var keysLabel: SKLabelNode?
    var roomsVisited: [(Int, Int)] = []
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        //backgroundColor = .white
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        view.isMultipleTouchEnabled = true
        
        guard let backgroundImage = UIImage(named: "Background") else { return }
        let texture = SKTexture(image: backgroundImage)
        background = SKSpriteNode(texture: texture)
        let scalar = (frame.width + 5.0) / texture.size().width
        background!.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        background!.position = CGPoint(x: frame.width/2, y: frame.height/2)
        background!.zPosition = -10
        background!.name = "background"
        addChild(background!)
        
        bulletDistance = frame.width < frame.height ? frame.height : frame.width
        
//        dummyLabel = SKLabelNode(text: "Temp")
//        dummyLabel?.position = CGPoint(x: 25.0, y: 25.0)
//        dummyLabel?.fontSize = 20
//        dummyLabel?.fontColor = UIColor.black
//        dummyLabel?.horizontalAlignmentMode = .left
//        dummyLabel?.verticalAlignmentMode = .center
//        dummyLabel?.name = "dummy"
//        addChild(dummyLabel!)
        
//
//        dummy = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
//        var count = 0
//        for i in 0..<3 {
//            for j in 0..<3 {
//                dummy[i][j] = count
//                count += 1
//            }
//        }
//        print(dummy)
//        print(dummy[0])
//        print(dummy[1])
//        print(dummy[2])
//        print("1, 2", dummy[1][2])
//        print("2, 1", dummy[2][1])
//        print("0, 2", dummy[0][2])

        
        
        //setup enemy spawn positions
        var midEnemies: [CGPoint] = []
        var bottomEnemies: [CGPoint] = []
        for i in 1...5 {
            let xVal = (frame.width / 6) * CGFloat(i)
            let tyVal = (frame.height / 4) * CGFloat(1)
            let byVal = (frame.height / 4) * CGFloat(3)
            let topSpawn: CGPoint = CGPoint(x: xVal, y: tyVal)
            let botSpawn: CGPoint = CGPoint(x: xVal, y: byVal)
            enemySpawns.append(topSpawn)
            bottomEnemies.append(botSpawn)
        }
        let midY = (frame.height / 4) * CGFloat(2)
        midEnemies.append(CGPoint(x: enemySpawns[0].x, y: midY))
        midEnemies.append(CGPoint(x: enemySpawns[4].x, y: midY))
        enemySpawns += midEnemies
        enemySpawns += bottomEnemies
        //print("enemieSpawns: ", enemySpawns)
        
        let moveJoystickHiddenArea = TLAnalogJoystickHiddenArea(rect: CGRect(x: 0, y: 0, width: frame.midX, height: frame.height))
        moveJoystickHiddenArea.joystick = moveJoystick
        moveJoystick.isMoveable = true
        moveJoystickHiddenArea.strokeColor = .clear
        addChild(moveJoystickHiddenArea)
        
        let rotateJoystickHiddenArea = TLAnalogJoystickHiddenArea(rect: CGRect(x: frame.midX, y: 0, width: frame.midX, height: frame.height))
        rotateJoystickHiddenArea.joystick = rotateJoystick
        rotateJoystickHiddenArea.strokeColor = .clear
        addChild(rotateJoystickHiddenArea)
    
        
        //MARK: Handlers begin
        moveJoystick.on(.begin) { [unowned self] _ in
//            let actions = [
//                SKAction.scale(to: 0.5, duration: 0.5),
//                SKAction.scale(to: 1, duration: 0.5)
//            ]
            
            
            //DO WHEN MOVE STARTS ##############################################################################
            self.despawnMenu()
            
            //self.playerNode?.run(SKAction.sequence(actions))
        }
        
        moveJoystick.on(.move) { [unowned self] joystick in
            guard let playerNode = self.playerNode else {
                return
            }
            //DO WHILE MOVE HAPPENS ##############################################################################
            
            
            let pVelocity = joystick.velocity;
            let speed = CGFloat(0.1)
            let newX = playerNode.position.x + (pVelocity.x * speed)
            let newY = playerNode.position.y + (pVelocity.y * speed)
            if (newX < self.frame.width - playerNode.size.width/2 && newX > 0.0 + playerNode.size.width/2 && newY < self.frame.height - playerNode.size.height/2 && newY > 0.0 + playerNode.size.height/2) {
                playerNode.position = CGPoint(x: newX, y: newY)
            }
            //print("playerPos: ", playerNode.position)
        }
        
        moveJoystick.on(.end) { [unowned self] _ in
//            let actions = [
//                SKAction.scale(to: 1.5, duration: 0.5),
//                SKAction.scale(to: 1, duration: 0.5)
//            ]
//            //DO WHEN MOVE ENDS ##############################################################################
            
            
            //self.playerNode?.run(SKAction.sequence(actions))
        }
        
        rotateJoystick.on(.move) { [unowned self] joystick in
//            guard let playerNode = self.playerNode else {
//                return
//            }
            //DO WHEN ROTATE STARTS ##############################################################################
            self.despawnMenu()
            self.shooting = true
            //print(self.shooting)
            
            //var dir: Int = 0
            if (joystick.angular < 0.75 && joystick.angular > -0.75) { //UP
                self.bulletDirection = 0
                guard let playerImage = UIImage(named: "Player_Default_Up") else {
                    return
                }
                let texture = SKTexture(image: playerImage)
                self.playerNode!.texture = texture
            } else if (joystick.angular < -0.75 && joystick.angular > -2.25) { //RIGHT
                self.bulletDirection = 1
                guard let playerImage = UIImage(named: "Player_Default_Right") else {
                    return
                }
                let texture = SKTexture(image: playerImage)
                self.playerNode!.texture = texture
            } else if (joystick.angular > 2.25 || joystick.angular < -2.25) { //DOWN
                self.bulletDirection = 2
                guard let playerImage = UIImage(named: "Player_Default_Down") else {
                    return
                }
                let texture = SKTexture(image: playerImage)
                self.playerNode!.texture = texture
            } else if (joystick.angular < 2.25 && joystick.angular > 0.75) { //LEFT
                self.bulletDirection = 3
                guard let playerImage = UIImage(named: "Player_Default_Left") else {
                    return
                }
                let texture = SKTexture(image: playerImage)
                self.playerNode!.texture = texture
            }
            
            if (self.bulletDirection != self.prevDir) {
                if (self.prevDir != 4) {
                    self.bulletTimer!.invalidate()
                }
                self.prevDir = self.bulletDirection
                if (self.thePlayer!.bulletType == 0) {
                    self.bulletTimer = Timer.scheduledTimer(timeInterval: 0.33, target: self, selector: #selector(self.fire), userInfo: nil, repeats: true)
                } else if (self.thePlayer!.bulletType == 1) {
                    self.bulletTimer = Timer.scheduledTimer(timeInterval: 0.66, target: self, selector: #selector(self.fire), userInfo: nil, repeats: true)
                }
                self.bulletTimer!.fire()
            }
            
            //playerNode.zRotation = joystick.angular
            //print("angular: ", joystick.angular)
        }
        
        rotateJoystick.on(.end) { [unowned self] _ in
            //self.playerNode?.run(SKAction.rotate(byAngle: 3.6, duration: 0.5))
            //DO WHEN ROTATE ENDS ##############################################################################
            guard let playerImage = UIImage(named: "Player_Default") else {
                return
            }
            let texture = SKTexture(image: playerImage)
            self.playerNode!.texture = texture
            self.shooting = false
            self.bulletTimer!.invalidate()
            self.prevDir = 4
            self.bulletDirection = 4
            self.playerNode?.run(SKAction.rotate(toAngle: 0.0, duration: 0.5))
        }
        //MARK: Handlers end

        thePlayer = Player.init()
        addPlayer(CGPoint(x: frame.midX, y: frame.midY))
        initializeGame()
        initializeMenu()
        
        fader.size = CGSize(width: frame.width, height: frame.height)
        fader.position = CGPoint(x: frame.width/2, y: frame.height/2)
    }
    
    @objc func fire()
    {
        var offScreenPos: CGPoint?
        var secondOffScreenPos: CGPoint?
        var thirdOffScreenPos: CGPoint?
        var bulletSpawn: CGPoint?
        let spread = frame.height/4
        
        switch bulletDirection {
        case 0: //UP
            switch thePlayer!.bulletType {
            case 0:
                offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! + bulletDistance)
            case 1:
                offScreenPos = CGPoint(x: playerNode!.position.x - spread, y: (playerNode?.position.y)! + bulletDistance)
                secondOffScreenPos = CGPoint(x: playerNode!.position.x, y: (playerNode?.position.y)! + bulletDistance)
                thirdOffScreenPos = CGPoint(x: playerNode!.position.x + spread, y: (playerNode?.position.y)! + bulletDistance)
            default:
                offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! + bulletDistance)
            }
//            offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! + bulletDistance)
            bulletSpawn = CGPoint(x: (playerNode?.position.x)! , y: (playerNode?.position.y)! + (playerNode?.size.height)!/2 + 5.0)
        case 1: //RIGHT
            switch thePlayer!.bulletType {
            case 0:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            case 1:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)! + spread)
                secondOffScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
                thirdOffScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)! - spread)
            default:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            }
//            offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            bulletSpawn = CGPoint(x: (playerNode?.position.x)! + (playerNode?.size.width)!/2 + 5.0, y: (playerNode?.position.y)!)
        case 2: //DOWN
            switch thePlayer!.bulletType {
            case 0:
                offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! - bulletDistance)
            case 1:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + spread, y: (playerNode?.position.y)! - bulletDistance)
                secondOffScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! - bulletDistance)
                thirdOffScreenPos = CGPoint(x: (playerNode?.position.x)! - spread, y: (playerNode?.position.y)! - bulletDistance)
            default:
                offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! - bulletDistance)
            }
//            offScreenPos = CGPoint(x: (playerNode?.position.x)!, y: (playerNode?.position.y)! - bulletDistance)
            bulletSpawn = CGPoint(x: (playerNode?.position.x)! , y: (playerNode?.position.y)! - (playerNode?.size.height)!/2 - 5.0)
        case 3: //LEFT
            switch thePlayer!.bulletType {
            case 0:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)!)
            case 1:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)! + spread)
                secondOffScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)!)
                thirdOffScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)! - spread)
            default:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)!)
            }
//            offScreenPos = CGPoint(x: (playerNode?.position.x)! - bulletDistance, y: (playerNode?.position.y)!)
            bulletSpawn = CGPoint(x: (playerNode?.position.x)! - (playerNode?.size.width)!/2 - 5.0, y: (playerNode?.position.y)!)
        default:
            switch thePlayer!.bulletType {
            case 0:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            case 1:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)! + spread)
                secondOffScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
                thirdOffScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)! + spread)
            default:
                offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            }
//            offScreenPos = CGPoint(x: (playerNode?.position.x)! + bulletDistance, y: (playerNode?.position.y)!)
            bulletSpawn = (playerNode?.position)!
        }
        
        switch thePlayer!.bulletType {
        case 0:
            spawnBullet(bulletSpawn!, offScreenPos!, bulletID)
        case 1:
            spawnBullet(bulletSpawn!, offScreenPos!, bulletID)
            spawnBullet(bulletSpawn!, secondOffScreenPos!, bulletID)
            spawnBullet(bulletSpawn!, thirdOffScreenPos!, bulletID)
        default:
            spawnBullet(bulletSpawn!, offScreenPos!, bulletID)

        }
        playSound(soundID: 1)
        print("FIRE!!!")
    }
    
    func initializeMenu() {
        guard let playButtonImage = UIImage(named: "PlayButton") else {
            return
        }
        var texture = SKTexture(image: playButtonImage)
        let playButton = SKSpriteNode(texture: texture)
        var pbWidth = (playerNode?.size.height)! * 5.0
        var scalar = pbWidth / texture.size().width
        playButton.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        playButton.physicsBody = SKPhysicsBody(rectangleOf: healthBar!.size)
        playButton.physicsBody!.affectedByGravity = false
        playButton.physicsBody!.isDynamic = false
        playButton.position = CGPoint(x: frame.width - frame.width/4, y: frame.height - frame.height/4)
        playButton.name = "playButton"
        addChild(playButton)
        
        guard let settingButtonImage = UIImage(named: "SettingsButton") else {
            return
        }
        texture = SKTexture(image: settingButtonImage)
        let settingsButton = SKSpriteNode(texture: texture)
        pbWidth = (playerNode?.size.height)! * 4.0
        scalar = pbWidth / texture.size().width
        settingsButton.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        settingsButton.physicsBody = SKPhysicsBody(rectangleOf: healthBar!.size)
        settingsButton.physicsBody!.affectedByGravity = false
        settingsButton.physicsBody!.isDynamic = false
        settingsButton.position = CGPoint(x: frame.width/4, y: frame.height/2 - 40.0)
        settingsButton.name = "settingsButton"
        addChild(settingsButton)
        
        guard let quitButtonImage = UIImage(named: "QuitButton") else {
            return
        }
        texture = SKTexture(image: quitButtonImage)
        let quitButton = SKSpriteNode(texture: texture)
        pbWidth = (playerNode?.size.height)! * 4.0
        scalar = pbWidth / texture.size().width
        quitButton.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        quitButton.physicsBody = SKPhysicsBody(rectangleOf: healthBar!.size)
        quitButton.physicsBody!.affectedByGravity = false
        quitButton.physicsBody!.isDynamic = false
        quitButton.position = CGPoint(x: frame.width/4, y: frame.height/4 - 40.0)
        quitButton.name = "quitButton"
        addChild(quitButton)
    }
    
    func playSound(soundID: Int) {
        /*
         0: start_game
         1: shoot
         2: pickup health
         3: pickup coin
         4: pickup key
         5: pickup upgrade
         6: enemy hit
         7: open chest
         8: next level
         9: player hit
         10: open door
         */
        switch soundID {
        case 0:
//            let soundNode = SKAudioNode(fileNamed: "start_game.mp3")
//            soundNode.run(<#T##action: SKAction##SKAction#>)
//            addChild(soundNode)
            let sound = SKAction.playSoundFileNamed("start_game.mp3", waitForCompletion: false)
            run(sound)
        case 1:
            let sound = SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false)
            run(sound)
        case 2:
            let sound = SKAction.playSoundFileNamed("pickup_health.mp3", waitForCompletion: false)
            run(sound)
        case 3:
            let sound = SKAction.playSoundFileNamed("pickup_coin.mp3", waitForCompletion: false)
            run(sound)
        case 4:
            let sound = SKAction.playSoundFileNamed("pickup_key.mp3", waitForCompletion: false)
            run(sound)
        case 5:
            let sound = SKAction.playSoundFileNamed("pickup_upgrade.mp3", waitForCompletion: false)
            run(sound)
        case 6:
            let sound = SKAction.playSoundFileNamed("enemy_hit.mp3", waitForCompletion: false)
            run(sound)
        case 7:
            let sound = SKAction.playSoundFileNamed("open_chest.mp3", waitForCompletion: false)
            run(sound)
        case 8:
            let sound = SKAction.playSoundFileNamed("next_level.mp3", waitForCompletion: false)
            run(sound)
        case 9:
            let sound = SKAction.playSoundFileNamed("player_hit.mp3", waitForCompletion: false)
            run(sound)
        case 10:
            let sound = SKAction.playSoundFileNamed("open_door.mp3", waitForCompletion: false)
            run(sound)
        default:
            print("Oof")
        }
    }
    
    func initializeGame() {
        gameMap = [[0, 0, 0], [0, 5, 0], [0, 0, 0]]
        roomsVisited = []
        
        /* Room ID's:
         0: Empty
         1: Monster fight
         2: Chest
         3: Shop
         4: Boss
         5: Spawn
        */
        let bossRoom = getRoom()
//        print("bossRoom", bossRoom)
        gameMap[bossRoom.1][bossRoom.0] = 4
        let chestRoom = getRoom()
        gameMap[chestRoom.1][chestRoom.0] = 2
        let shopRoom = getRoom()
        gameMap[shopRoom.1][shopRoom.0] = 3
        makePath(dest: bossRoom, lastMoved: 0)
        makePath(dest: chestRoom, lastMoved: 0)
        
        for child in scene!.children {
            if let child = child as? SKSpriteNode {
                let str = (child.name)! //its coliding with the side of the screen
//                let range = str.startIndex..<str.index(before: str.endIndex)
                if (str == "player" || str == "background") {

                } else {
                    child.removeFromParent()
                }
            }
        }
        
        //Create health bar
        guard let healthImage = UIImage(named: "Health_Meter_10") else {
            return
        }
        var texture = SKTexture(image: healthImage)
        healthBar = SKSpriteNode(texture: texture)
        let hbWidth = (playerNode?.size.height)! * 1.5
        var scalar = hbWidth / texture.size().width
        healthBar!.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        healthBar!.physicsBody = SKPhysicsBody(rectangleOf: healthBar!.size)
        healthBar!.physicsBody!.affectedByGravity = false
        healthBar!.physicsBody!.isDynamic = false
        healthBar!.position = CGPoint(x: frame.width/45.0 + healthBar!.size.width/2, y: frame.height - frame.height/35.0 - healthBar!.size.height/2)
        healthBar!.name = "healthBar"
        addChild(healthBar!)
        
        //Create coin image
        guard let coinImage = UIImage(named: "Coin") else {
            return
        }
        texture = SKTexture(image: coinImage)
        let coinLab = SKSpriteNode(texture: texture)
        let cWidth = healthBar!.size.height / 3.0 //(playerNode?.size.height)! / 3.0
        scalar = cWidth / texture.size().width
        coinLab.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        coinLab.physicsBody = SKPhysicsBody(rectangleOf: coinLab.size)
        coinLab.physicsBody!.affectedByGravity = false
        coinLab.physicsBody!.isDynamic = false
        coinLab.position = CGPoint(x: healthBar!.position.x + (3.0 * (healthBar!.size.width/4)), y: healthBar!.position.y + healthBar!.size.width/4)//CGPoint(x: frame.width/45.0 + coinLab.size.width/2, y: frame.height - frame.height/35.0 - coinLab.size.height/2)
        coinLab.name = "coinLab"
        addChild(coinLab)
        
        //Create coin label
        coinLabel = SKLabelNode(text: "x" + String(thePlayer!.coins))
        coinLabel!.fontSize = 20
        coinLabel!.fontColor = UIColor.black
        coinLabel!.horizontalAlignmentMode = .left
        coinLabel!.verticalAlignmentMode = .center
        coinLabel!.position = CGPoint(x: coinLab.position.x + (coinLab.size.width/3 * 2), y: coinLab.position.y)
        coinLabel!.name = "coinAmount"
        addChild(coinLabel!)
        
        //Create key image
        guard let keyImage = UIImage(named: "Key") else {
            return
        }
        texture = SKTexture(image: keyImage)
        let keyLab = SKSpriteNode(texture: texture)
        let kWidth = healthBar!.size.height / 3.0 //(playerNode?.size.height)! / 3.0
        scalar = kWidth / texture.size().width
        keyLab.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        keyLab.physicsBody = SKPhysicsBody(rectangleOf: coinLab.size)
        keyLab.physicsBody!.affectedByGravity = false
        keyLab.physicsBody!.isDynamic = false
        keyLab.position = CGPoint(x: healthBar!.position.x + (3.0 * (healthBar!.size.width/4)), y: healthBar!.position.y - healthBar!.size.width/4)//CGPoint(x: frame.width/45.0 + coinLab.size.width/2, y: frame.height - frame.height/35.0 - coinLab.size.height/2)
        keyLab.name = "keyLab"
        addChild(keyLab)
        
        //Create key label
        keysLabel = SKLabelNode(text: "x" + String(thePlayer!.keys))
        keysLabel!.fontSize = 20
        keysLabel!.fontColor = UIColor.black
        keysLabel!.horizontalAlignmentMode = .left
        keysLabel!.verticalAlignmentMode = .center
        keysLabel!.position = CGPoint(x: keyLab.position.x + (keyLab.size.width/3 * 2), y: keyLab.position.y)
        keysLabel!.name = "keysAmount"
        addChild(keysLabel!)
        
        //Create score label
        scoreLabel = SKLabelNode(text: "Score: " + String(thePlayer!.score))
        scoreLabel!.fontSize = 20
        scoreLabel!.fontColor = UIColor.black
        scoreLabel!.horizontalAlignmentMode = .left
        scoreLabel!.verticalAlignmentMode = .center
        scoreLabel!.position = CGPoint(x: healthBar!.position.x - healthBar!.size.width/2, y: healthBar!.position.y - (healthBar!.size.height/3 * 2))
        scoreLabel!.name = "score"
        addChild(scoreLabel!)
        
        
        for _ in 0..<2 {
            let room = getRoom()
            gameMap[room.1][room.0] = 1
        }
        
        print("After extras")
        print(gameMap[0])
        print(gameMap[1])
        print(gameMap[2])
        
        enterRoom(id: 5, loc: (1, 1), spawnLocation: CGPoint(x: frame.width/2, y: frame.height/2))
        
    }
    
    func enterRoom(id: Int, loc: (Int, Int), spawnLocation: CGPoint) {
        fader.run(SKAction.fadeOut(withDuration: 0.25)) //you forgot to add the fader as a child also make it black
        fader.run(SKAction.fadeIn(withDuration: 0.25))
        print("room id: ", id)
        print("room loc:, ", loc)
        print(gameMap[0])
        print(gameMap[1])
        print(gameMap[2])
                
//        playerNode?.position = CGPoint(x: frame.width/2, y: frame.height/2)
//        childNode(withName: "player")?.position = CGPoint(x: frame.width/2, y: frame.height/2)
        childNode(withName: "player")?.run(SKAction.move(to: spawnLocation, duration: 0.0))

        
        for door in roomDoors {
            door.node!.removeFromParent()
        }
        for enemy in enemyStructs {
            enemy.spriteNode!.removeFromParent()
        }
        roomDoors = []
        enemyStructs = []
        for i in 0..<spawnedEnemies.count {
            spawnedEnemies[i] = false
        }
//        print(spawnedEnemies)
        
        for child in scene!.children {
            if let _ = child as? SKSpriteNode {
                let str = (child.name)! //its coliding with the side of the screen
                let range = str.startIndex..<str.index(before: str.endIndex)
                if (str[range] == "enemy" || str == "stand" || str[range] == "door" || str == "coin" || str == "chest" || str == "chest_open" || str == "key" || str == "bullet" || str == "upgrade") {
                    child.removeFromParent()
                }
            }
        }
        
        spawnFour(loc: loc)
        var visitedAlready: Bool = false
        for i in roomsVisited {
            if i == loc {
                visitedAlready = true
            }
        }
        
        roomsVisited.append(loc)
        
        switch id {
        case 0:
            print("How? Its empty")
        case 1:
            print("Enemies")
            if (visitedAlready) {
            } else {
                spawnEnemy(numEnemies: Int.random(in: 2..<7))
            }
        case 2:
            print("Chest")
            if (visitedAlready) {
                spawnEmptyChest(pos: CGPoint(x: frame.width/2, y: frame.height/2))
            } else {
                spawnChest(pos: CGPoint(x: frame.width/2, y: frame.height/2))
            }
        case 3:
            print("Shop")
            print(roomsVisited)
            if (visitedAlready) {
            } else {
                print("spawn upgrade")
                spawnUpgrade(pos: CGPoint(x: frame.width/2, y: frame.height/2 + playerNode!.size.height/2))
            }
            spawnStand()
        case 4:
            print("Boss")
            spawnBoss()
        case 5:
            print("Spawn")
        default:
            print("Oof")
        }
    }
    
    func despawnMenu() {
        for child in scene!.children {
            if let child = child as? SKSpriteNode {
                let str = (child.name)! //its coliding with the side of the screen
//                let range = str.startIndex..<str.index(before: str.endIndex)
                if (str == "playButton" || str == "settingsButton" || str == "quitButton") {
                    child.removeFromParent()
                }
            }
        }
        playSound(soundID: 0)
    }
    
    func spawnFour(loc: (Int, Int)) {
        //Top
//        print("mid")
//        print(gameMap[loc.0][loc.1])
//
//        print("up")
//        print(gameMap[loc.0][loc.1+1])
//
//        print("right")
//        print(gameMap[loc.0+1][loc.1])
//
//        print("down")
//        print(gameMap[loc.0][loc.1-1])
//
//        print("left")
//        print(gameMap[loc.0-1][loc.1])
        
        
        if (loc.1-1 < 0 || gameMap[loc.1-1][loc.0] == 0) {
            // swapped (loc.1-1, loc.0)
            // normal (loc.0, loc.1-1)
            spawnDoor(pos: CGPoint(x: frame.width/2, y: frame.height), mapLoc: loc, nextMapLoc: (loc.0, loc.1), rotated: false, name: "door0", locked: true, visible: false)
//            print((loc.1-1, loc.0), " is locked")
//            //print("gameMap[loc.1-1][loc.0]", gameMap[loc.1-1][loc.0])
//            print("loc.1-1", loc.1-1)
        } else {
            spawnDoor(pos: CGPoint(x: frame.width/2, y: frame.height), mapLoc: loc, nextMapLoc: (loc.0, loc.1-1), rotated: false, name: "door0", locked: false, visible: true)
//            print((loc.1-1, loc.0), " is not locked")
//            print("gameMap[loc.1-1][loc.0]", gameMap[loc.1-1][loc.0])
        }
        
        //Right
        if (loc.0+1 > 2 || gameMap[loc.1][loc.0+1] == 0) {
            // swapped (loc.1, loc.0+1)
            // normal (loc.0+1, loc.1)
            spawnDoor(pos: CGPoint(x: frame.width, y: frame.height / 2), mapLoc: loc, nextMapLoc: (loc.0, loc.1), rotated: true, name: "door1", locked: true, visible: false)
//            print((loc.1, loc.0+1), " is locked")
//            //print("gameMap[loc.1][loc.0+1]", gameMap[loc.1][loc.0+1])
//            print("loc.0+1", loc.0+1)

        } else {
            spawnDoor(pos: CGPoint(x: frame.width, y: frame.height / 2), mapLoc: loc, nextMapLoc: (loc.0+1, loc.1), rotated: true, name: "door1", locked: false, visible: true)
//            print((loc.1, loc.0+1), " is not locked")
//            print("gameMap[loc.1][loc.0+1]", gameMap[loc.1][loc.0+1])
        }
        
        //Bottom
        if (loc.1+1 > 2 || gameMap[loc.1+1][loc.0] == 0) {
            // swapped (loc.1+1, loc.0)
            // normal (loc.0, loc.1+1)
            spawnDoor(pos: CGPoint(x: frame.width/2, y: 0.0), mapLoc: loc, nextMapLoc: (loc.0, loc.1), rotated: false, name: "door2", locked: true, visible: false)
//            print((loc.1+1, loc.0), " is locked")
//            //print("gameMap[loc.1+1][loc.0]", gameMap[loc.1+1][loc.0])
//            print("loc.1+1", loc.1+1)

        } else {
            spawnDoor(pos: CGPoint(x: frame.width/2, y: 0.0), mapLoc: loc, nextMapLoc: (loc.0, loc.1+1), rotated: false, name: "door2", locked: false, visible: true)
//            print((loc.1+1, loc.0), " is not locked")
//            print("gameMap[loc.1+1][loc.0]", gameMap[loc.1+1][loc.0])
        }

        //Left
        if (loc.0-1 < 0 || gameMap[loc.1][loc.0-1] == 0) {
            // swapped (loc.1, loc.0-1)
            // normal (loc.0-1, loc.1)
            spawnDoor(pos: CGPoint(x: 0.0, y: frame.height / 2), mapLoc: loc, nextMapLoc: (loc.0, loc.1), rotated: true, name: "door3", locked: true, visible: false)
//            print((loc.1, loc.0-1), " is locked")
//            //print("gameMap[loc.1][loc.0-1]", gameMap[loc.1][loc.0-1])
//            print("loc.0-1", loc.0-1)
        } else {
            spawnDoor(pos: CGPoint(x: 0.0, y: frame.height / 2), mapLoc: loc, nextMapLoc: (loc.0-1, loc.1), rotated: true, name: "door3", locked: false, visible: true)
//            print((loc.1, loc.0-1), " is not locked")
//            print("gameMap[loc.1][loc.0-1]", gameMap[loc.1][loc.0-1])
        }
        
    }
    
    func spawnDoor(pos: CGPoint, mapLoc: (Int, Int), nextMapLoc: (Int, Int), rotated: Bool, name: String, locked: Bool, visible: Bool) {
        var door_VS: String = ""
        var doorS: String = ""
        if gameMap[nextMapLoc.1][nextMapLoc.0] == 4 {
            door_VS = "Boss_Door_Vertical"
            doorS = "Boss_Door"
        } else {
            door_VS = "Door_Vertical"
            doorS = "Door"
        }
        guard let doorImage = rotated ? UIImage(named: door_VS) : UIImage(named: doorS) else {
            return
        }
        let texture = SKTexture(image: doorImage)
        let door = SKSpriteNode(texture: texture)
        let dWidth = (playerNode?.size.width)! * CGFloat(2.0)
        let scalar = dWidth / (rotated ? texture.size().height : texture.size().width)
//        if (rotated) {
//            door.size = CGSize(width: texture.size().height * scalar, height: texture.size().width * scalar)
//        } else {
        door.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
//        }
        door.physicsBody = SKPhysicsBody(rectangleOf: door.size)
        door.physicsBody?.categoryBitMask = CollisionTypes.door.rawValue
        door.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        door.physicsBody?.collisionBitMask = 0
        door.physicsBody?.usesPreciseCollisionDetection = true
        door.physicsBody?.affectedByGravity = false
        //door.physicsBody?.isDynamic = false
        door.position = pos
        door.name = name
        if (visible) {
            addChild(door)
        }
        let newDoor = Door.init(room: mapLoc, next: nextMapLoc, nextID: gameMap[nextMapLoc.1][nextMapLoc.0], key: false, open: !locked, pos: pos, node: door)
        roomDoors.append(newDoor)
    }
    
    func makePath(dest: (Int, Int), lastMoved: Int) -> Bool {
         if lastMoved == 0 {//1 - dest.0 < 1 - dest.1 { //move y
             let next = dest.1 < 1 ? dest.1 + 1 : dest.1 - 1
            print("lastMoved: ", String(lastMoved), "dest: ", dest, " | next: ", String(next))
            print(gameMap[0])
            print(gameMap[1])
            print(gameMap[2])
             if (gameMap[next][dest.0] == 5) { //spawn room
                 return true
             } else if (gameMap[next][dest.0] == 4) { //boss room

             } else if (gameMap[dest.1][next] == 0) {
                 gameMap[dest.1][next] = 1
                 return makePath(dest: (dest.0, next), lastMoved: 1)
             }
             else {
                 return makePath(dest: (dest.0, next), lastMoved: 1)
             }
         }
        if lastMoved == 1 {// 1 - dest.0 >= 1 - dest.1 { //move x
            let next = dest.0 < 1 ? dest.0 + 1 : dest.0 - 1
            print("lastMoved: ", String(lastMoved), "dest: ", dest, " | next: ", String(next))
            print(gameMap[0])
             print(gameMap[1])
             print(gameMap[2])
             //print("next: ", next, "dest1: ", dest.1)
            if (gameMap[dest.1][next] == 5) { //spawn room
                return true
            } else if (gameMap[dest.1][next] == 4) { //boss room

            } else if (gameMap[dest.1][next] == 0) {
                gameMap[dest.1][next] = 1
                return makePath(dest: (next, dest.1), lastMoved: 0)
            }
            else {
                return makePath(dest: (next, dest.1), lastMoved: 0)
            }
        }
        return makePath(dest: dest, lastMoved: lastMoved)
    }
    
    func getRoom() -> (Int, Int) {
        let room: (Int, Int) = (Int.random(in: 0..<3), Int.random(in: 0..<3))
        if (gameMap[room.1][room.0] == 0) {
            return room
        }
        else {
            return getRoom()
        }
    }
    
    func addPlayer(_ position: CGPoint) {
        guard let playerImage = UIImage(named: "Player_Default") else {
            return
        }
        let pSize = getPlayerDims(size: playerImage.size)
        let texture = SKTexture(image: playerImage)
        let player = SKSpriteNode(texture: texture)
        //var pSize: CGSize = CGSize(width: UIScreen.main.bounds.width / 10.0, height: UIScreen.main.bounds.width / 10.0)
//        player.physicsBody = SKPhysicsBody(texture: texture, size: pSize)/*player.size*/
//        player.physicsBody!.affectedByGravity = false
        player.size = pSize
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.enemy.rawValue | CollisionTypes.door.rawValue | CollisionTypes.coin.rawValue | CollisionTypes.chest.rawValue | CollisionTypes.stairs.rawValue | CollisionTypes.upgrade.rawValue
        player.physicsBody?.collisionBitMask = player.physicsBody!.contactTestBitMask
        player.physicsBody?.usesPreciseCollisionDetection = true
        player.color = .black
        player.position = position
        player.name = "player"
        addChild(player)
        thePlayer?.spriteNode = player
        //print("parent: ", player.parent)
        playerNode = player
    }
    
    func spawnBoss() {
        guard let bossImage = UIImage(named: "Enemy") else {
            return
        }
        let texture = SKTexture(image: bossImage)
        let boss = SKSpriteNode(texture: texture)
        let eWidth = (playerNode?.size.width)! * 5.0
        //let eHeight = (playerNode?.size.height)! / CGFloat(1.5)
        let scalar = eWidth / texture.size().width
        boss.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        boss.physicsBody = SKPhysicsBody(rectangleOf: boss.size)
//            enemy.physicsBody?.isDynamic = false
        boss.physicsBody?.mass = 0.00
        boss.physicsBody?.restitution = 0.75
        boss.physicsBody?.categoryBitMask = CollisionTypes.enemy.rawValue
        boss.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue | CollisionTypes.bullet.rawValue | CollisionTypes.enemy.rawValue
        boss.physicsBody?.collisionBitMask = boss.physicsBody!.contactTestBitMask
        boss.physicsBody?.usesPreciseCollisionDetection = true
        //enemy.physicsBody!.contactTestBitMask = enemy.physicsBody!.collisionBitMask
        boss.physicsBody?.affectedByGravity = false
        boss.position = CGPoint(x: frame.width/2, y: frame.height/2)
        boss.name = "boss"
        
        theBoss = Enemy.init()
        //newEnemy.arrayIndex = i
        theBoss!.spriteNode = boss
        theBoss!.damage = 40
        theBoss!.health = 200
        theBoss!.speed = Double.random(in: 5...6)
        enemyStructs.append(theBoss!)
//            enemy.setValue(i, forKey: "enemyIndex")
//            print(enemy.value(forKey: "enemyIndex"))
        //print("mass: ", enemy.physicsBody?.mass)
        addChild(boss)
    }
    
    func spawnEnemy(numEnemies: Int) {
        for i in 0..<numEnemies {
            guard let enemyImage = UIImage(named: "Enemy") else {
                return
            }
            let texture = SKTexture(image: enemyImage)
            let enemy = SKSpriteNode(texture: texture)
            let sIndex = getEnemySpawnLocation()
            let eWidth = (playerNode?.size.width)! / CGFloat(1.5)
            //let eHeight = (playerNode?.size.height)! / CGFloat(1.5)
            let scalar = eWidth / texture.size().width
            enemy.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
//            enemy.physicsBody?.isDynamic = false
            enemy.physicsBody?.mass = 0.00
            enemy.physicsBody?.restitution = 0.75
            enemy.physicsBody?.categoryBitMask = CollisionTypes.enemy.rawValue
            enemy.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue | CollisionTypes.bullet.rawValue | CollisionTypes.enemy.rawValue
            enemy.physicsBody?.collisionBitMask = enemy.physicsBody!.contactTestBitMask
            enemy.physicsBody?.usesPreciseCollisionDetection = true
            //enemy.physicsBody!.contactTestBitMask = enemy.physicsBody!.collisionBitMask
            enemy.physicsBody?.affectedByGravity = false
            enemy.position = enemySpawns[sIndex]
            enemy.name = "enemy" + String(i)
            
            var newEnemy = Enemy.init()
            newEnemy.arrayIndex = i
            newEnemy.spriteNode = enemy
            newEnemy.speed = Double.random(in: 1...3)
            enemyStructs.append(newEnemy)
//            enemy.setValue(i, forKey: "enemyIndex")
//            print(enemy.value(forKey: "enemyIndex"))
            //print("mass: ", enemy.physicsBody?.mass)
            addChild(enemy)
        }
    }
    
    func getEnemySpawnLocation() -> Int {
        let sLocation = Int.random(in: 0..<12)
        if (spawnedEnemies[sLocation]) {
            return getEnemySpawnLocation()
        } else {
            spawnedEnemies[sLocation] = true
            return sLocation
        }
    }
    
    func spawnBullet(_ position: CGPoint, _ offScreenPos: CGPoint, _ bulletID: Int) {
        guard let bulletImage = UIImage(named: "Bullet") else {
            return
        }
        var bulletSpeed: Double?
        var bSize: CGSize?
        switch bulletID {
        case 0:
            bSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(3.0)), height: ((playerNode?.size.height)! / CGFloat(3.0)))
            bulletSpeed = 3.0
        default:
            bSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(3.0)), height: ((playerNode?.size.height)! / CGFloat(3.0)))
            bulletSpeed = 3.0
        }
        
        let texture = SKTexture(image: bulletImage)
        let bullet = SKSpriteNode(texture: texture)
        
        bullet.size = bSize!
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2.0)
        bullet.physicsBody?.categoryBitMask = CollisionTypes.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = CollisionTypes.enemy.rawValue
        bullet.physicsBody?.collisionBitMask = 0
//        bullet.physicsBody?.isDynamic = false
        bullet.physicsBody?.allowsRotation = false
        bullet.physicsBody?.affectedByGravity = false
        bullet.position = position
        bullet.name = "bullet"
        addChild(bullet)
        bullet.run(SKAction.move(to: offScreenPos, duration: bulletSpeed!))
    }
    
    func getPlayerDims(size: CGSize) -> CGSize {
        var smaller: CGFloat = 0.0
        if (UIScreen.main.bounds.width < UIScreen.main.bounds.height) {
            smaller = UIScreen.main.bounds.width / 7.5
        }
        else {
            smaller = UIScreen.main.bounds.height / 7.5
        }
        let scalar = smaller / size.width
        let pSize = CGSize(width: size.width * scalar, height: size.height * scalar)
        return pSize
    }
    
    func collisions(between obj1: SKNode, obj2: SKNode, hasIndex: Int) {
//        print("collision")
//        print("obj1: ", obj1, "obj2",  obj2, "hasIndex: ", hasIndex)
        var obj1Name: String = ""
        var obj2Name: String = ""
        switch hasIndex {
        case 0:
            //first has index
            let str = (obj1.name)! //its coliding with the side of the screen
            let range = str.startIndex..<str.index(before: str.endIndex)
            obj1Name = String(str[range])
            obj2Name = (obj2.name)!
        case 1:
            //second has index
            let str = (obj2.name)! //its coliding with the side of the screen
            let range = str.startIndex..<str.index(before: str.endIndex)
            obj1Name = (obj1.name)!
            obj2Name = String(str[range])
        case 2:
            //both have index
            let str = (obj1.name)! //its coliding with the side of the screen
            let range = str.startIndex..<str.index(before: str.endIndex)
            let str2 = (obj2.name)! //its coliding with the side of the screen
            let range2 = str2.startIndex..<str2.index(before: str2.endIndex)
            obj1Name = String(str[range])
            obj2Name = String(str2[range2])
        default:
            //neither have index
            obj1Name = obj1.name!
            obj2Name = obj2.name!
        }
//
//        print("obj1: ", obj1Name)
//        print("obj2: ", obj2Name)

        
        if (obj1Name == "enemy") {
            if (obj2Name == "bullet") {
                //enemy take damage
                print("bullet hit enemy")
                //bumpEnemy(enemy: enemy)
                destroy(object: obj2)
                hitEnemy(enemy: obj1)
            }
            else if (obj2Name == "player") {
                //player take damage
                playerHit(enemy: obj1)
                print("Player Hit")
                print(String(obj1.name!), " hit player")
            }
            else if (obj2Name == "enemy") {
                bumpEnemies(enemy1: obj1, enemy2: obj2)
            }
        } else if (obj1.name == "boss") {
            if (obj2Name == "bullet") {
                //enemy take damage
                print("bullet hit enemy")
                //bumpEnemy(enemy: enemy)
                destroy(object: obj2)
                hitEnemy(enemy: obj1)
            }
            else if (obj2Name == "player") {
                //player take damage
                playerHit(enemy: obj1)
                print("Player Hit")
                print(String(obj1.name!), " hit player")
            }
            else if (obj2Name == "enemy") {
                bumpEnemies(enemy1: obj1, enemy2: obj2)
            }
        } else if (obj1Name == "door") {
            print("doorHit")
            if (obj2Name == "player") {
//                print("player hit door")
//                print(gameMap[0])
//                print(gameMap[1])
//                print(gameMap[2])
                
                if (!enemiesAlive()) {
                    tryWalkThroughDoor(doorNode: obj1)
                }
            }
        } else if (obj1Name == "coin") {
            print("coin hit")
            if (obj2Name == "player") {
                print("player hit coin")
                pickUpCoin(coin: obj1)
            }
        } else if (obj1Name == "chest") {
            print("chest hit")
            if (obj2Name == "player") {
                print("player hit coin")
                openChest(chest: obj1)
            }
        } else if (obj1Name == "key") {
            print("key hit")
            if (obj2Name == "player") {
                print("player hit key")
                pickUpKey(key: obj1)
                //openChest(chest: obj1)
            }
        } else if (obj1Name == "heart") {
            print("heart hit")
            if (obj2Name == "player") {
                print("player hit key")
                //pickUpKey(key: obj1)
                pickUpHeart(heart: obj1)
                //openChest(chest: obj1)
            }
        } else if (obj1Name == "stairs") {
            print("stairs hit")
            if (obj2Name == "player") {
                print("player hit key")
                //pickUpKey(key: obj1)
                nextLevel(stairs: obj1)
                //openChest(chest: obj1)
            }
        } else if (obj1Name == "upgrade") {
               print("stairs hit")
               if (obj2Name == "player") {
                   print("player hit key")
                   //pickUpKey(key: obj1)
                pickUpUpgrade(upgrade: obj1)
                //nextLevel(stairs: obj1)
                   //openChest(chest: obj1)
               }
           }
    }
    
    func destroy(object: SKNode) {
        object.removeFromParent()
    }
    
    func bumpEnemies(enemy1: SKNode, enemy2: SKNode) {
        print("enemies bumped")
        var enemy1NewPos: CGPoint?
        var enemy2NewPos: CGPoint?
        if (enemy1.position.y > enemy2.position.y) {
            enemy1NewPos = CGPoint(x: enemy1.position.x, y: enemy1.position.y + 10.0)
            enemy2NewPos = CGPoint(x: enemy2.position.x, y: enemy1.position.y - 10.0)
        } else {
            enemy1NewPos = CGPoint(x: enemy1.position.x, y: enemy1.position.y - 15.0)
            enemy2NewPos = CGPoint(x: enemy2.position.x, y: enemy1.position.y + 15.0)
        }
        if (enemy1.position.x > enemy2.position.x) {
            enemy1NewPos = CGPoint(x: enemy1.position.x + 15.0, y: enemy1NewPos!.y)
            enemy2NewPos = CGPoint(x: enemy2.position.x - 15.0, y: enemy2NewPos!.y)
        } else {
            enemy1NewPos = CGPoint(x: enemy1.position.x - 15.0, y: enemy1NewPos!.y)
            enemy2NewPos = CGPoint(x: enemy2.position.x + 15.0, y: enemy2NewPos!.y)
        }
        
//        let str = (nodeA.name)! //its coliding with the side of the screen
//        let range = str.startIndex..<str.index(before: str.endIndex)
//        let str2 = (nodeB.name)!
//        let range2 = str2.startIndex..<str2.index(before: str2.endIndex)
        let range1 = enemy1.name!.index(before: enemy1.name!.endIndex)..<(enemy1.name!.endIndex)
        let eIndex1 = Int(enemy1.name![range1])
        let range2 = enemy2.name!.index(before: enemy2.name!.endIndex)..<(enemy2.name!.endIndex)
        let eIndex2 = Int(enemy2.name![range2])
        
//        print("index1: ", eIndex1)
//        print("index2: ", eIndex2)
//
//        print("enemy1 pos: ", enemy1.position)
//        print("enemy1 new pos: ", enemy1NewPos)
//
//        print("enemy2 pos: ", enemy2.position)
//        print("enemy2 new pos: ", enemy2NewPos)
        
        childNode(withName: enemy1.name!)?.run(SKAction.move(to: enemy1NewPos!, duration: 0.0))
        childNode(withName: enemy2.name!)?.run(SKAction.move(to: enemy2NewPos!, duration: 0.0))

//        enemyStructs[eIndex1!].spriteNode!.position = enemy1NewPos!
//        enemyStructs[eIndex2!].spriteNode!.position = enemy2NewPos!

//        enemy1.position = enemy1NewPos!
//        enemy2.position = enemy2NewPos!
//        enemy1.run(SKAction.move(to: enemy1NewPos!, duration: 0.0001))
//        enemy2.run(SKAction.move(to: enemy2NewPos!, duration: 0.0001))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
//        print("nodeA: ", nodeA)
//        print("nodeB: ", nodeB)
        if let a = contact.bodyA.node as? SKScene {
            // nodeA is a SKScene.
        }
        else if let b = contact.bodyB.node as? SKScene {
            // nodeB is a SKScene.
        }
        else {
            let str = (nodeA.name)! //its coliding with the side of the screen
            let range = str.startIndex..<str.index(before: str.endIndex)
            let str2 = (nodeB.name)!
            let range2 = str2.startIndex..<str2.index(before: str2.endIndex)
//            print("str1: ", str[range])
//            print("str2: ", str2[range2])
            if str[range] == "enemy" {
                if (str2[range2] == "enemy") {
                    collisions(between: nodeA, obj2: nodeB, hasIndex: 2)
                } else {
                    collisions(between: nodeA, obj2: nodeB, hasIndex: 0)
                }
            } else if str2[range2] == "enemy" {
                if (str[range] == "enemy") {
                    collisions(between: nodeB, obj2: nodeA, hasIndex: 2)
                } else {
                    collisions(between: nodeB, obj2: nodeA, hasIndex: 0)
                }
            } else if str[range] == "door" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 0)
            } else if str2[range2] == "door" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 0)
            } else if str == "coin" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "coin" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "chest" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "chest" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "key" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "key" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "heart" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "heart" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "boss" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "boss" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "stairs" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "stairs" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            } else if str == "upgrade" {
                collisions(between: nodeA, obj2: nodeB, hasIndex: 10)
            } else if str2 == "upgrade" {
                collisions(between: nodeB, obj2: nodeA, hasIndex: 10)
            }
        }
    }
    
    func bumpEnemy(enemy: SKNode) {
        let moveTo: CGPoint = CGPoint(x: abs(enemy.position.x - (playerNode?.position.x)!) / 10, y: abs(enemy.position.y - (playerNode?.position.y)!) / 10)
        enemy.run(SKAction.move(to: moveTo, duration: 0.2))
    }
    
    func tryWalkThroughDoor(doorNode: SKNode) {
        let range = doorNode.name!.index(before: doorNode.name!.endIndex)..<(doorNode.name!.endIndex)
        let doorIndex = Int(doorNode.name![range])
        let door = roomDoors[doorIndex!]
        print("next id: ", door.nextID)
        let spawnPos = getSpawnPos(doorNode: doorNode)
        if (door.nextID == 4) { //boss door
            if (thePlayer!.keys >= 1) {
                thePlayer!.keys -= 1
                keysLabel!.text = "x" + String(thePlayer!.keys)
                enterRoom(id: door.nextID, loc: door.next, spawnLocation: spawnPos)
                playSound(soundID: 10)
            }
        }
        else if (door.open) {
            print("open door")
            enterRoom(id: door.nextID, loc: door.next, spawnLocation: spawnPos)
            playSound(soundID: 10)
        } else {
            print("closed door")
            return
        }
    }
    
    func getSpawnPos(doorNode: SKNode) -> CGPoint {
        var spawnPos: CGPoint?
        let range = doorNode.name!.index(before: doorNode.name!.endIndex)..<(doorNode.name!.endIndex)
        let doorIndex = Int(doorNode.name![range])
        let door = roomDoors[doorIndex!]
        
        if (door.room.1 < door.next.1) { //going down
            print("down")
            spawnPos = CGPoint(x: frame.width/2, y: frame.height - frame.height/5)
        } else if (door.room.1 > door.next.1) { //going up
            print("up")
            spawnPos = CGPoint(x: frame.width/2, y: frame.height/5)

        }
        else if (door.room.0 < door.next.0) { //going right
            print("right")
            spawnPos = CGPoint(x: frame.width/5.0, y: frame.height/2)
        } else if (door.room.0 > door.next.0) { //going left
            print("left")
            spawnPos = CGPoint(x: frame.width - frame.width/5.0, y: frame.height/2)
        }
        return spawnPos!
    }
    
    func enemiesAlive() -> Bool {
//        guard let str = self.childNode(withName: "str[range]") else { return } //its coliding with the side of the screen
//        let range = str.startIndex..<str.index(before: str.endIndex)
        var foundOne: Bool = false
        for child in scene!.children {
            if let _ = child as? SKSpriteNode {
                let str = (child.name)! //its coliding with the side of the screen
                let range = str.startIndex..<str.index(before: str.endIndex)
                if (str[range] == "enemy" || str == "boss") {
                    foundOne = true
                }
            }
        }
        return foundOne
    }
    
    
    
    func hitEnemy(enemy: SKNode) {
        
//        let str2 = (contact.bodyB.node?.name)!
//        let range2 = str.startIndex..<str.index(before: str.endIndex)
        let range = enemy.name!.index(before: enemy.name!.endIndex)..<(enemy.name!.endIndex)
        let sIndex = Int(enemy.name![range])
        if (enemy.name == "boss") {
            theBoss!.health -= thePlayer!.bulletDamage
            if (theBoss!.health <= 0) {
                bossDied(boss: enemy)
            }
        } else {
            enemyStructs[sIndex!].health -= thePlayer!.bulletDamage
            if (enemyStructs[sIndex!].health <= 0) {
                enemyDied(enemy: enemy)
            }
        }
        playSound(soundID: 6)
    }
    
    func playerHit(enemy: SKNode) {
        let range = enemy.name!.index(before: enemy.name!.endIndex)..<(enemy.name!.endIndex)
        let eIndex = Int(enemy.name![range])
        var damageTaken: Int = 0
        if (enemy.name == "boss") {
            damageTaken = 30
        } else {
            damageTaken = enemyStructs[eIndex!].damage
        }
        //print("damage taken: ", enemyStructs[eIndex!].damage)
        thePlayer!.health = thePlayer!.health - damageTaken
        //healthLabel!.text = "Health: " + String(thePlayer!.health)
        updatePlayerHealth()
//        print("player: ", thePlayer!)
        playSound(soundID: 9)
    }
    
    func updatePlayerHealth() {
        print("playerhealth: ", Int(thePlayer!.health/10))
        var switcher = Int(thePlayer!.health/10)
        if (switcher <= 0) {
            switcher = 0
        }
        if (switcher >= 10) {
            switcher = 10
        }
        switch switcher {
        case 0:
            print("0")
            guard let healthImage = UIImage(named: "Health_Meter_0") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 1:
            print("10")
            guard let healthImage = UIImage(named: "Health_Meter_1") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 2:
            print("20")
            guard let healthImage = UIImage(named: "Health_Meter_2") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 3:
            print("30")
            guard let healthImage = UIImage(named: "Health_Meter_3") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 4:
            print("40")
            guard let healthImage = UIImage(named: "Health_Meter_4") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 5:
            print("50")
            guard let healthImage = UIImage(named: "Health_Meter_5") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 6:
            print("60")
            guard let healthImage = UIImage(named: "Health_Meter_6") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 7:
            print("70")
            guard let healthImage = UIImage(named: "Health_Meter_7") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 8:
            print("80")
            guard let healthImage = UIImage(named: "Health_Meter_8") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 9:
            print("90")
            guard let healthImage = UIImage(named: "Health_Meter_9") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        case 10:
            print("100")
            guard let healthImage = UIImage(named: "Health_Meter_10") else {
                return
            }
            let texture = SKTexture(image: healthImage)
            healthBar!.texture = texture
        default:
            print("default")
        }
    }
    
    func bossDied(boss: SKNode) {
        boss.removeFromParent()
        thePlayer!.score += 200
        spawnStairs(pos: CGPoint(x: frame.width/2, y: frame.height/2))
        print("He dead")
    }
    
    func nextLevel(stairs: SKNode) {
        print("nextLevel")
        stairs.removeFromParent()
        initializeGame()
    }
    
    func enemyDied(enemy: SKNode) {
        let range = enemy.name!.index(before: enemy.name!.endIndex)..<(enemy.name!.endIndex)
        let eIndex = Int(enemy.name![range])
        //add to players score
        thePlayer!.score += enemyStructs[eIndex!].score
        scoreLabel!.text = "Score: " + String(thePlayer!.score)
        //see if they drop anything
        let coinDrop = Int.random(in: 0...100)
        let heartDrop = Int.random(in: 0...100)
        if (coinDrop <= enemyStructs[eIndex!].dropChance && heartDrop <= enemyStructs[eIndex!].dropChance) {
            let coinPos = CGPoint(x: enemy.position.x + 10, y: enemy.position.y)
            let heartPos = CGPoint(x: enemy.position.x - 10, y: enemy.position.y)
            dropCoin(pos: coinPos)
            dropHealth(pos: heartPos)
        } else if (coinDrop <= enemyStructs[eIndex!].dropChance) {
            dropCoin(pos: enemy.position)
        } else if (heartDrop <= enemyStructs[eIndex!].dropChance) {
            dropHealth(pos: enemy.position)
        }
        //remove them
        enemy.removeFromParent()
    }
    
    func dropCoin (pos: CGPoint) {
//        print("dropCoin")
        guard let coinImage = UIImage(named: "Coin") else {
            return
        }
        let cSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(4.0)), height: ((playerNode?.size.height)! / CGFloat(4.0)))
        
        let texture = SKTexture(image: coinImage)
        let coin = SKSpriteNode(texture: texture)
        
        coin.size = cSize
        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2.0)
        coin.physicsBody?.categoryBitMask = CollisionTypes.coin.rawValue
        coin.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        coin.physicsBody?.collisionBitMask = coin.physicsBody!.categoryBitMask
        coin.physicsBody?.allowsRotation = false
        coin.physicsBody?.affectedByGravity = false
        coin.position = pos
        coin.name = "coin"
        addChild(coin)
    }
    
    func dropHealth(pos: CGPoint) {
        guard let heartImage = UIImage(named: "Heart") else {
            return
        }
        let texture = SKTexture(image: heartImage)
        let heart = SKSpriteNode(texture: texture)
        let hWidth = playerNode!.size.height / CGFloat(4.0)
        let scalar = hWidth / texture.size().width
        heart.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        heart.physicsBody = SKPhysicsBody(circleOfRadius: heart.size.width / 2.0)
        heart.physicsBody?.categoryBitMask = CollisionTypes.coin.rawValue
        heart.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        heart.physicsBody?.collisionBitMask = heart.physicsBody!.categoryBitMask
        heart.physicsBody?.allowsRotation = false
        heart.physicsBody?.affectedByGravity = false
        heart.position = pos
        heart.name = "heart"
        addChild(heart)
    }
    
    func spawnChest (pos: CGPoint) {
//        print("spawnChest")
        guard let chestImage = UIImage(named: "Chest") else {
            return
        }
        let cSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(1.25)), height: ((playerNode?.size.height)! / CGFloat(1.25)))
        
        let texture = SKTexture(image: chestImage)
        let chest = SKSpriteNode(texture: texture)
        
        chest.size = cSize
        chest.physicsBody = SKPhysicsBody(rectangleOf: chest.size)
        chest.physicsBody?.categoryBitMask = CollisionTypes.chest.rawValue
        chest.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        chest.physicsBody?.collisionBitMask = chest.physicsBody!.categoryBitMask
//        coin.physicsBody?.isDynamic = false
        chest.physicsBody?.allowsRotation = false
        chest.physicsBody?.affectedByGravity = false
        chest.position = pos
        chest.name = "chest"
        addChild(chest)
    }
    
    func spawnEmptyChest(pos: CGPoint) {
        guard let openChestImage = UIImage(named: "Chest_Open") else {
            return
        }
        let cSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(1.25)), height: ((playerNode?.size.height)! / CGFloat(1.25)))
        
        let texture = SKTexture(image: openChestImage)
        let chest = SKSpriteNode(texture: texture)
        chest.size = cSize
        chest.physicsBody = SKPhysicsBody(rectangleOf: chest.size)
        chest.physicsBody!.affectedByGravity = false
        chest.physicsBody!.isDynamic = false
        chest.position = pos
        chest.name = "chest_open"
        addChild(chest)
        
        playSound(soundID: 7)
    }
    
    func spawnStairs(pos: CGPoint) {
        guard let stairImage = UIImage(named: "Stairs") else {
            return
        }
        let texture = SKTexture(image: stairImage)
        let stairs = SKSpriteNode(texture: texture)
        let sWidth = playerNode!.size.height
        let scalar = sWidth / texture.size().width
        stairs.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        stairs.physicsBody = SKPhysicsBody(circleOfRadius: stairs.size.width / 2.0)
        stairs.physicsBody?.categoryBitMask = CollisionTypes.stairs.rawValue
        stairs.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        stairs.physicsBody?.collisionBitMask = stairs.physicsBody!.categoryBitMask
        stairs.physicsBody?.allowsRotation = false
        stairs.physicsBody?.affectedByGravity = false
        stairs.position = pos
        stairs.name = "stairs"
        addChild(stairs)
    }
    
    func openChest(chest: SKNode) {
        spawnKey(chestPos: chest.position)
        spawnEmptyChest(pos: chest.position)
        chest.removeFromParent()
    }
    
    func spawnStand() {
        guard let chestImage = UIImage(named: "ItemDisplay") else {
            return
        }
        let iSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(1.25)), height: ((playerNode?.size.height)! / CGFloat(1.25)))
        
        let texture = SKTexture(image: chestImage)
        let stand = SKSpriteNode(texture: texture)
        
        stand.size = iSize
        stand.zPosition = -1
//        stand.physicsBody = SKPhysicsBody(rectangleOf: stand.size)
//        stand.physicsBody!.categoryBitMask = CollisionTypes.chest.rawValue
//        stand.physicsBody!.contactTestBitMask = CollisionTypes.player.rawValue
//        stand.physicsBody!.collisionBitMask = stand.physicsBody!.categoryBitMask
//        stand.physicsBody!.allowsRotation = false
//        stand.physicsBody!.affectedByGravity = false
//        stand.physicsBody!.isDynamic = false
        stand.position = CGPoint(x: frame.width/2, y: frame.height/2)
        stand.name = "stand"
        addChild(stand)
    }
    
    func spawnUpgrade(pos: CGPoint) {
        guard let upgradeImage = UIImage(named: "Upgrade_Trishot") else {
            return
        }
        let uSize = CGSize(width: ((playerNode?.size.height)! / CGFloat(1.5)), height: ((playerNode?.size.height)! / CGFloat(1.5)))
        
        let texture = SKTexture(image: upgradeImage)
        let upgrade = SKSpriteNode(texture: texture)
        
        upgrade.size = uSize
        upgrade.physicsBody = SKPhysicsBody(rectangleOf: upgrade.size)
        upgrade.physicsBody!.categoryBitMask = CollisionTypes.upgrade.rawValue
        upgrade.physicsBody!.contactTestBitMask = CollisionTypes.player.rawValue
        upgrade.physicsBody!.collisionBitMask = upgrade.physicsBody!.categoryBitMask
        upgrade.physicsBody!.allowsRotation = false
        upgrade.physicsBody!.affectedByGravity = false
        upgrade.position = pos
        upgrade.name = "upgrade"
        addChild(upgrade)
    }
    
    func spawnKey(chestPos: CGPoint) {
//        print("spawnChest")
        guard let keyImage = UIImage(named: "Key") else {
            return
        }
        let texture = SKTexture(image: keyImage)
        let key = SKSpriteNode(texture: texture)
        let cWidth = (playerNode?.size.width)! / CGFloat(1.5)
        let scalar = cWidth / texture.size().width
        key.size = CGSize(width: texture.size().width * scalar, height: texture.size().height * scalar)
        key.physicsBody = SKPhysicsBody(rectangleOf: key.size)
        key.physicsBody?.categoryBitMask = CollisionTypes.chest.rawValue
        key.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        key.physicsBody?.collisionBitMask = key.physicsBody!.categoryBitMask
//        coin.physicsBody?.isDynamic = false
        key.physicsBody?.allowsRotation = false
        key.physicsBody?.affectedByGravity = false
        key.position = CGPoint(x: chestPos.x, y: chestPos.y - frame.height/4.0)
        key.name = "key"
        addChild(key)
    }
    
    func pickUpCoin (coin: SKNode) {
        //var player = childNode(withName: "player")?.run(SKAction.move(to: CGPoint(x: frame.width/2, y: frame.height/2), duration: 0.0))
//        var c: Int = thePlayer!.coins += 1
//        coinLabel!.text = "Coins: " + String(c)
//        var c = thePlayer?.coins += 1
//
//        print("c: ", c)
//        coinLabel?.text = "Coins: " + String(c)
        thePlayer!.coins = thePlayer!.coins + 1
        coinLabel!.text = "x" + String(thePlayer!.coins)        //coinLabel?.text = "Coins: " + String(thePlayer!.coins)
//        print("player: ", thePlayer!)
        playSound(soundID: 3)
        coin.removeFromParent()
    }
    
    func pickUpKey(key: SKNode) {
        thePlayer!.keys = thePlayer!.keys + 1
        keysLabel!.text = "x" + String(thePlayer!.keys)
//        print("player: ", thePlayer!)
        playSound(soundID: 4)
        key.removeFromParent()
    }
    
    func pickUpUpgrade(upgrade: SKNode) {
        thePlayer!.bulletType = 1
        thePlayer!.bulletDamage = 10
//        keysLabel!.text = "x" + String(thePlayer!.keys)
//        print("player: ", thePlayer!)
        playSound(soundID: 5)
        upgrade.removeFromParent()
    }
    
    func pickUpHeart(heart: SKNode) {
        let projectedH = thePlayer!.health + 20
        if (projectedH < 0) {
            thePlayer!.health = 0
        } else if (projectedH > 100) {
            thePlayer!.health = 100
        } else {
            thePlayer!.health = projectedH
        }
        updatePlayerHealth()
        //keysLabel!.text = "x" + String(thePlayer!.keys)
//        print("player: ", thePlayer!)
        playSound(soundID: 2)
        heart.removeFromParent()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        if let touch = touches.first {
            let node = atPoint(touch.location(in: self))
            print("node", node)
            
            if (node.name == "playButton") {
                despawnMenu()
            } else if (node.name == "settingsButton") {
                print("Settings")
            } else if (node.name == "quitButton") {
                print("Quit")
            } else {
                print("nothing touched")
                despawnMenu()
            }
        }
    }
    
    func setRandomStickColor() {
        let randomColor = UIColor.random()
        moveJoystick.handleColor = randomColor
        rotateJoystick.handleColor = randomColor
    }
    
    func setRandomSubstrateColor() {
        let randomColor = UIColor.random()
        moveJoystick.baseColor = randomColor
        rotateJoystick.baseColor = randomColor
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        for enemy in enemyStructs {
            //enemy.spriteNode?.run(SKAction())
            enemy.spriteNode!.run(SKAction.move(to: playerNode!.position, duration: TimeInterval(enemy.speed)))
        }
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
    }
}
