////
////  Room.swift
////  Not_A_Binding_Of_Isaac_Ripoff
////
////  Created by Chip Whiteside on 12/9/19.
////  Copyright © 2019 Chip Whiteside. All rights reserved.
////
//
//import Foundation
//import SpriteKit
//import GameplayKit
//
//class Room: SKScene {
//    
//    var baseZ: CGFloat = 3
//    var movingZ: CGFloat = 10
//    var targetZ: CGFloat = 11
//    
//    var currentScore: SKLabelNode!
//    var playerPositions: [(Int, Int)] = []
//    var gameBG: SKShapeNode!
//    
//    //R (2,3)
//    //L (1,0)
//    //U (3,1)
//    //D (0,2)
//    
//    override func didMove(to view: SKView) {
////        game = GameManager(scene: self)
//        initializeGameView()
//        
//        var rand1 = Int.random(in: 0...3)
//        var rand2 = Int.random(in: 0...3);
//        
////        åString(randBlock.value)
//        
//        let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeR))
//        swipeRight.direction = .right
//        view.addGestureRecognizer(swipeRight)
//        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeL))
//        swipeLeft.direction = .left
//        view.addGestureRecognizer(swipeLeft)
//        let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeU))
//        swipeUp.direction = .up
//        view.addGestureRecognizer(swipeUp)
//        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeD))
//        swipeDown.direction = .down
//        view.addGestureRecognizer(swipeDown)
//    }
//    
//    @objc func swipeR() {
//        whenSwiped(dir: 0)
//    }
//    @objc func swipeL() {
//        whenSwiped(dir: 1)
//    }
//    @objc func swipeU() {
//        whenSwiped(dir: 2)
//    }
//    @objc func swipeD() {
//        whenSwiped(dir: 3)
//    }
//    
//    func whenSwiped(dir: Int) {
//        var curBlock: Block
//        switch dir {
//        case 0:
//            curBlock = gameArray[2][3]
//            for _ in 0...11 {
//                if curBlock.value != 0 {
//                    analyzeBlock(block: curBlock, i: curBlock.i, j: curBlock.j, dir: dir)
//                }
//                curBlock = whatIsNext(i: curBlock.i, j: curBlock.j, dir: dir)
//            }
//        case 1:
//            curBlock = gameArray[1][0]
//            for _ in 0...11 {
//                if curBlock.value != 0 {
//                    analyzeBlock(block: curBlock, i: curBlock.i, j: curBlock.j, dir: dir)
//                }
//                curBlock = whatIsNext(i: curBlock.i, j: curBlock.j, dir: dir)
//            }
//        case 2:
//            curBlock = gameArray[3][1]
//            for _ in 0...11 {
//                if curBlock.value != 0 {
//                    analyzeBlock(block: curBlock, i: curBlock.i, j: curBlock.j, dir: dir)
//                }
//                curBlock = whatIsNext(i: curBlock.i, j: curBlock.j, dir: dir)
//            }
//        case 3:
//            curBlock = gameArray[0][2]
//            for _ in 0...11 {
//                if curBlock.value != 0 {
//                    analyzeBlock(block: curBlock, i: curBlock.i, j: curBlock.j, dir: dir)
//                }
//                curBlock = whatIsNext(i: curBlock.i, j: curBlock.j, dir: dir)
//            }
//        default:
//            print("Invalid Direction")
//        }
//    }
//    
//    func analyzeBlock(block: Block, i: Int, j: Int, dir: Int) {
//        let adjacent = getAdjacent(i: i, j: j, dir: dir)
//        if adjacent.value == 0 {
//            analyzeBlock(block: block, i: adjacent.i, j: adjacent.j, dir: dir)
//        }
//    }
//    
//    func getAdjacent(i: Int, j: Int, dir: Int) -> Block {
//        switch dir {
//        case 0:
//            return gameArray[i+1][j]
//        case 1:
//            return gameArray[i-1][j]
//        case 2:
//            return gameArray[i][j-1]
//        default:
//            return gameArray[i][j+1]
//        }
//    }
//    
//    func whatIsNext(i: Int, j: Int, dir: Int) -> Block {
//        switch dir {
//        case 0:
//            if j > 0 {
//                return gameArray[i][j-1]
//            }
//            else if i > 0 {
//                return gameArray[i-1][3]
//            }
//            else {
//                return gameArray[i][j]
//            }
//        case 1:
//            if j < 3 {
//                return gameArray[i][j+1]
//            }
//            else if i < 3 {
//                return gameArray[i+1][0]
//            }
//            else {
//                return gameArray[i][j]
//            }
//        case 2:
//            if i > 0 {
//                return gameArray[i-1][j]
//            }
//            else if j < 3 {
//                return gameArray[3][j+1]
//            }
//            else {
//                return gameArray[i][j]
//            }
//        case 3:
//            if i < 3 {
//                return gameArray[i+1][j]
//            }
//            else if j > 0 {
//                return gameArray[0][j-1] //errors
//            }
//            else {
//                return gameArray[i][j]
//            }
//        default:
//            print("Invalid Direction")
//            return gameArray[i][j]
//        }
//    }
//    
//    
//    
//    
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//    }
//    
//    private func initializeGameView() {
//        let width = frame.size.width - 200
//        let height = width
//        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
//        gameBG = SKShapeNode(rect: rect, cornerRadius: 0.02)
//        gameBG.fillColor = SKColor.blue
//        gameBG.zPosition = 2
//        gameBG.isHidden = false
//        self.addChild(gameBG)
//        //6
//        createGameBoard(width: width, height: height)
//    }
//    
//    private func createGameBoard(width: CGFloat, height: CGFloat) {
//        let pointSpace: CGFloat = width / 4.0
//        let numRows = 4
//        let numCols = 4
//        var x = CGFloat(width / -2) + (pointSpace / 2)
//        var y = CGFloat(height / 2) - (pointSpace / 2)
//        let cellWidth = pointSpace * 0.8
//        //loop through rows and columns, create cells
//        for i in 0...numRows - 1 {
//            var blockArray: [Block] = []
//            for j in 0...numCols - 1 {
//                let cellNode = SKShapeNode(rectOf: CGSize(width: cellWidth, height: cellWidth))
//                let labelNode = SKLabelNode(text: "0")
//                labelNode.fontSize = pointSpace * 0.9
//                labelNode.fontColor = SKColor.clear
//                labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
//                cellNode.strokeColor = SKColor.black
//                cellNode.fillColor = SKColor.black
//                cellNode.zPosition = 2
//                cellNode.position = CGPoint(x: x, y: y)
//                cellNode.zPosition = baseZ
//                //add to array of cells -- then add to game board
//                cellNode.addChild(labelNode)
//                gameBG.addChild(cellNode)
//                blockArray.append(Block(xPos: x, yPos: y, i: i, j: j, sNode: cellNode, lNode: labelNode, value: 0))
//                //iterate x
//                x += pointSpace
//            }
//            gameArray.append(blockArray)
//            //reset x, iterate y
//            x = CGFloat(width / -2) + (pointSpace / 2)
//            y -= pointSpace
//        }
//    }
//    
//    //move a block to a previously empty spot
//    func moveBlock(movingB: Block, targetB: Block, dir: Int) {
//        let ogPos: CGPoint = movingB.sNode.position
//        
//        movingB.sNode.zPosition = 10
//        targetB.sNode.zPosition = 11
//        
//        //let moveDuration =
//        //move node
//        let moveRect = SKAction.move(to: targetB.sNode.position, duration: moveDuration(movingB: movingB, targetB: targetB, dir: dir))
//        movingB.sNode.run(moveRect)
//    }
//    
//    //move a block to a matching block location
//    func mergeBlock(movingB: Block, targetB: Block, dir: Int) {
//        let ogPos: CGPoint = movingB.sNode.position
//        
//        movingB.sNode.zPosition = movingZ
//        targetB.sNode.zPosition = targetZ
//        
//        //let moveDuration =
//        //move node
//        let moveRect = SKAction.move(to: targetB.sNode.position, duration: moveDuration(movingB: movingB, targetB: targetB, dir: dir))
//        movingB.sNode.run(moveRect)
//    }
//    
//    func moveDuration(movingB: Block, targetB: Block, dir: Int) -> Double {
//        switch dir {
//        case 0: //right
//            return Double(targetB.xPos - movingB.xPos) / 3.0
//        case 1: //left
//            return Double(movingB.xPos - targetB.xPos) / 3.0
//        case 2: //up
//            return Double(movingB.yPos - targetB.yPos) / 3.0
//        case 3: //down
//            return Double(targetB.yPos - movingB.yPos) / 3.0
//        default:
//            return 1.0
//        }
//    }
//    
//    func doneMoving(ogPos: CGPoint, movedB: Block, targetB: Block) {
//        //set the blocks new values
//        gameArray[targetB.i][targetB.j].value = gameArray[movedB.i][movedB.j].value
//        gameArray[targetB.i][targetB.j].lNode.fontSize = gameArray[movedB.i][movedB.j].lNode.fontSize
//        gameArray[movedB.i][movedB.j].value = 0
//        
//        //set z values back to default
//        gameArray[targetB.i][targetB.j].sNode.zPosition = baseZ
//        gameArray[movedB.i][movedB.j].sNode.zPosition = baseZ
//        
//        //move the moved block back to og spot
//        gameArray[movedB.i][movedB.j].sNode.position = ogPos
//
//    }
//    
//    func doneMerging(ogPos: CGPoint, movedB: Block, targetB: Block) {
//        //set the blocks new values
//        gameArray[targetB.i][targetB.j].value *= 2
//        gameArray[targetB.i][targetB.j].lNode.fontSize = CGFloat(checkFontSize(mult: 0.9, val: gameArray[targetB.i][targetB.j].value))
//        gameArray[movedB.i][movedB.j].value = 0
//        
//        //set z values back to default
//        gameArray[targetB.i][targetB.j].sNode.zPosition = baseZ
//        gameArray[movedB.i][movedB.j].sNode.zPosition = baseZ
//        
//        //move the moved block back to og spot
//        gameArray[movedB.i][movedB.j].sNode.position = ogPos
//    }
//    
//    func checkFontSize(mult: Double, val: Int) -> Double {
//        if (val/10 > 0) {
//            return checkFontSize(mult: mult - 0.2, val: val / 10)
//        }
//        else {
//            return mult
//        }
//    }
//}
