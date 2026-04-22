// 
//  Made by Imperio, Aguirre, Embodo, Soria, and Dolor.
//

import SpriteKit

// MARK: - Box Side
enum BoxSide: Int, CaseIterable {
    case top = 0, right = 1, bottom = 2, left = 3

    var color: UIColor {
        switch self {
        case .top:    return UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1) // Blue
        case .right:  return UIColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1) // Yellow
        case .bottom: return UIColor(red: 1.00, green: 0.22, blue: 0.22, alpha: 1) // Red
        case .left:   return UIColor(red: 0.65, green: 0.20, blue: 1.00, alpha: 1) // Purple
        }
    }

    var imageName: String {
        switch self {
        case .top:    return "side_blue"
        case .right:  return "side_yellow"
        case .bottom: return "side_red"
        case .left:   return "side_purple"
        }
    }
}

// MARK: - Ball Role
enum BallRole { case top, bottom }

// MARK: - Ball Node
class BallNode: SKShapeNode {
    var currentSide: BoxSide
    let role: BallRole

    init(role: BallRole, radius: CGFloat) {
        self.role = role
        self.currentSide = role == .top ? .top : .bottom
        super.init()
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        self.path = path
        self.fillColor = currentSide.color
        self.strokeColor = UIColor.white.withAlphaComponent(0.6)
        self.lineWidth = 2.5
        self.zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func updateColor(_ side: BoxSide) {
        currentSide = side
        fillColor = side.color
        run(.sequence([.scale(to: 1.35, duration: 0.08), .scale(to: 1.0, duration: 0.10)]))
    }
}

// MARK: - Game Scene
class GameScene: SKScene {

    // MARK: - Nodes
    private var boxNode: SKNode!
    private var boxSideNodes: [BoxSide: SKSpriteNode] = [:]
    private var topBall: BallNode!
    private var bottomBall: BallNode!
    private var scoreLabel: SKLabelNode!
    private var livesContainer: SKNode!
    private var countdownLabel: SKLabelNode!

    // MARK: - State
    private var score          = 0
    private var lives          = 3
    private var combo          = 0    // consecutive correct hits
    private var rotationIndex  = 0
    private var isGameOver     = false
    private var isCountingDown = true

    // Combo label node
    private var comboLabel: SKLabelNode!

    // MARK: - Responsive Layout
    private var minDim:        CGFloat { min(frame.width, frame.height) }
    private var boxSize:       CGFloat { minDim * 0.38 }
    private var sideThickness: CGFloat { max(10, boxSize * 0.085) }
    private var ballRadius:    CGFloat { max(10, boxSize * 0.11) }
    private var boxCenterY:    CGFloat { frame.midY }
    private var ceilingY:      CGFloat { frame.maxY - ballRadius - 10 }
    private var floorY:        CGFloat { frame.minY + ballRadius + 10 }
    private var scoreFontSize: CGFloat { minDim * 0.13 }

    // Ball travel edges
    private var topBallBoxEdge:    CGFloat { boxCenterY + boxSize / 2 + sideThickness / 2 + ballRadius }
    private var bottomBallBoxEdge: CGFloat { boxCenterY - boxSize / 2 - sideThickness / 2 - ballRadius }
    private var topLegDist:        CGFloat { ceilingY - topBallBoxEdge }
    private var bottomLegDist:     CGFloat { bottomBallBoxEdge - floorY }

    private let ballSpeed: CGFloat = 170

    // MARK: - Entry
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1)
        setupBackground()
        setupBox()
        setupBalls()
        setupUI()
        startCountdown()
    }

    // MARK: - Background
    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "background")
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.size = frame.size
        bg.zPosition = -10
        addChild(bg)
    }

    // MARK: - Box
    private func setupBox() {
        boxNode = SKNode()
        boxNode.position = CGPoint(x: frame.midX, y: boxCenterY)
        boxNode.zPosition = 5
        addChild(boxNode)
        buildBoxSides()
    }

    private func buildBoxSides() {
        boxNode.removeAllChildren()
        boxSideNodes.removeAll()

        let half = boxSize / 2
        let t    = sideThickness
        let hSize = CGSize(width: boxSize, height: t)
        let vSize = CGSize(width: t, height: boxSize)

        let configs: [(BoxSide, CGPoint, CGSize, CGFloat)] = [
            (.right,  CGPoint(x:  half, y: 0),     vSize, 1),
            (.left,   CGPoint(x: -half, y: 0),     vSize, 1),
            (.top,    CGPoint(x: 0,     y:  half), hSize, 2),
            (.bottom, CGPoint(x: 0,     y: -half), hSize, 2),
        ]

        for (side, pos, size, z) in configs {
            let visual: SKSpriteNode
            if UIImage(named: side.imageName) != nil {
                visual = SKSpriteNode(imageNamed: side.imageName)
                visual.size = size
            } else {
                visual = SKSpriteNode(color: side.color, size: size)
            }
            visual.position = pos
            visual.zPosition = z
            visual.name = "side_\(side.rawValue)"
            boxNode.addChild(visual)
            boxSideNodes[side] = visual
        }
    }

    // MARK: - Balls
    private func setupBalls() {
        topBall    = BallNode(role: .top,    radius: ballRadius)
        bottomBall = BallNode(role: .bottom, radius: ballRadius)
        topBall.position    = CGPoint(x: frame.midX, y: ceilingY)
        bottomBall.position = CGPoint(x: frame.midX, y: floorY)
        addChild(topBall)
        addChild(bottomBall)
    }

    // MARK: - Countdown
    private func startCountdown() {
        isCountingDown = true

        countdownLabel = SKLabelNode(text: "3")
        countdownLabel.fontName = "AvenirNext-Heavy"
        countdownLabel.fontSize = minDim * 0.28
        countdownLabel.fontColor = .white
        countdownLabel.alpha = 0
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY - minDim * 0.14)
        countdownLabel.zPosition = 50
        addChild(countdownLabel)

        // "Get Ready" label above the number
        let ready = SKLabelNode(text: "GET READY")
        ready.fontName = "AvenirNext-Bold"
        ready.fontSize = minDim * 0.06
        ready.fontColor = UIColor(white: 1, alpha: 0.7)
        ready.position = CGPoint(x: frame.midX, y: frame.midY + minDim * 0.08)
        ready.zPosition = 50
        ready.alpha = 0
        ready.name = "readyLabel"
        addChild(ready)
        ready.run(.fadeIn(withDuration: 0.3))

        runCountdownStep(count: 3, readyNode: ready)
    }

    private func runCountdownStep(count: Int, readyNode: SKNode) {
        guard count > 0 else {
            // Countdown done — remove labels and start game
            countdownLabel.run(.fadeOut(withDuration: 0.2))
            readyNode.run(.sequence([
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ]))
            countdownLabel.run(.sequence([
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ]))
            isCountingDown = false
            startBallMovement()
            return
        }

        countdownLabel.text = "\(count)"
        countdownLabel.setScale(1.4)

        countdownLabel.run(.sequence([
            .fadeIn(withDuration: 0.05),
            .group([
                .scale(to: 1.0, duration: 0.35),
                .sequence([
                    .wait(forDuration: 0.6),
                    .fadeOut(withDuration: 0.2)
                ])
            ]),
            .wait(forDuration: 0.15),
            .run { [weak self] in
                self?.runCountdownStep(count: count - 1, readyNode: readyNode)
            }
        ]))

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Ball Movement
    private func startBallMovement() {
        animateTopBall()
        let offset = TimeInterval(topLegDist / ballSpeed)
        bottomBall.run(.sequence([
            .wait(forDuration: offset),
            .run { [weak self] in self?.animateBottomBall() }
        ]))
    }

    private func animateTopBall() {
        guard !isGameOver else { return }
        let dur = TimeInterval(topLegDist / ballSpeed)
        topBall.run(.sequence([
            .move(to: CGPoint(x: frame.midX, y: topBallBoxEdge), duration: dur),
            .run { [weak self] in
                guard let self = self, !self.isGameOver else { return }
                self.evaluateHit(ball: self.topBall, geometricSide: .top)
            },
            .move(to: CGPoint(x: frame.midX, y: ceilingY), duration: dur),
            .run { [weak self] in
                guard let self = self, !self.isGameOver else { return }
                self.topBall.updateColor(self.randomSide(excluding: self.topBall.currentSide))
                self.animateTopBall()
            }
        ]))
    }

    private func animateBottomBall() {
        guard !isGameOver else { return }
        let dur = TimeInterval(bottomLegDist / ballSpeed)
        bottomBall.run(.sequence([
            .move(to: CGPoint(x: frame.midX, y: bottomBallBoxEdge), duration: dur),
            .run { [weak self] in
                guard let self = self, !self.isGameOver else { return }
                self.evaluateHit(ball: self.bottomBall, geometricSide: .bottom)
            },
            .move(to: CGPoint(x: frame.midX, y: floorY), duration: dur),
            .run { [weak self] in
                guard let self = self, !self.isGameOver else { return }
                self.bottomBall.updateColor(self.randomSide(excluding: self.bottomBall.currentSide))
                self.animateBottomBall()
            }
        ]))
    }

    // MARK: - Hit Evaluation
    private func evaluateHit(ball: BallNode, geometricSide: BoxSide) {
        let visual = visualSide(for: geometricSide)
        if ball.currentSide == visual {
            handleCorrectHit(ball: ball)
        } else {
            handleWrongHit(ball: ball)
        }
    }

    private func visualSide(for geometric: BoxSide) -> BoxSide {
        let raw = (geometric.rawValue - rotationIndex + 4) % 4
        return BoxSide(rawValue: raw)!
    }

    private func randomSide(excluding current: BoxSide) -> BoxSide {
        return BoxSide.allCases.filter { $0 != current }.randomElement() ?? .top
    }

    // MARK: - Correct Hit
    private func handleCorrectHit(ball: BallNode) {
        combo += 1
        let points = combo >= 5 ? 3 : combo >= 3 ? 2 : 1   // bonus at streak 3 and 5
        score += points
        updateScoreUI()

        // Popup text
        let popupText = combo >= 5 ? "+3" : combo >= 3 ? "+2" : "+1"

        // Sound — bonus at combo 3+, regular hit otherwise
        if combo >= 3 {
            run(SKAction.playSoundFileNamed("bonus.wav", waitForCompletion: false))
        } else {
            run(SKAction.playSoundFileNamed("hit.wav", waitForCompletion: false))
        }

        let popup = SKLabelNode(text: popupText)
        popup.fontName = "AvenirNext-Heavy"
        popup.fontSize = minDim * 0.06
        popup.fontColor = combo >= 3 ? UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1) : .white
        popup.position = ball.position
        popup.zPosition = 50
        popup.alpha = 0
        addChild(popup)
        let dir: CGFloat = ball.role == .top ? -1 : 1
        popup.run(.sequence([
            .fadeIn(withDuration: 0.05),
            .group([
                .moveBy(x: 0, y: dir * 55, duration: 0.5),
                .sequence([.wait(forDuration: 0.2), .fadeOut(withDuration: 0.3)])
            ]),
            .removeFromParent()
        ]))

        // Update combo label
        updateComboUI()
    }

    // MARK: - Wrong Hit (lose a life)
    private func handleWrongHit(ball: BallNode) {
        guard !isGameOver else { return }
        combo = 0
        updateComboUI()
        lives -= 1
        updateLivesUI()
        run(SKAction.playSoundFileNamed("wrong.wav", waitForCompletion: false))
        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        // Flash the ball red briefly
        ball.fillColor = .red
        ball.run(.sequence([
            .wait(forDuration: 0.25),
            .run { ball.fillColor = ball.currentSide.color }
        ]))

        if lives <= 0 {
            triggerGameOver()
        }
        // If lives remain, game continues — balls keep moving
    }

    // MARK: - Rotation
    private func rotateBox() {
        guard !isGameOver, !isCountingDown else { return }
        rotationIndex = (rotationIndex + 1) % 4
        let r = SKAction.rotate(byAngle: -.pi / 2, duration: 0.20)
        r.timingMode = .easeInEaseOut
        boxNode.run(r)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Game Over
    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        topBall.removeAllActions()
        bottomBall.removeAllActions()

        let previous = UserDefaults.standard.integer(forKey: "HighScore")
        if score > previous {
            UserDefaults.standard.set(score, forKey: "HighScore")
        }

        UINotificationFeedbackGenerator().notificationOccurred(.error)
        run(SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.showGameOver()
        }
    }

    private func showGameOver() {
        let overlay = SKShapeNode(rect: frame)
        overlay.fillColor = UIColor(white: 0, alpha: 0.78)
        overlay.strokeColor = .clear
        overlay.zPosition = 100
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(.fadeIn(withDuration: 0.3))

        func lbl(_ text: String, font: String, size: CGFloat, y: CGFloat) -> SKLabelNode {
            let l = SKLabelNode(text: text)
            l.fontName = font; l.fontSize = size
            l.fontColor = .white; l.alpha = 0
            l.position = CGPoint(x: frame.midX, y: y); l.zPosition = 110
            return l
        }

        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        let isNewBest = score == highScore && score > 0

        let mid  = frame.midY
        let go   = lbl("GAME OVER",         font: "AvenirNext-Heavy",  size: minDim * 0.11,  y: mid + frame.height * 0.12)
        let sc   = lbl("Score: \(score)",   font: "AvenirNext-Bold",   size: minDim * 0.07,  y: mid + frame.height * 0.05)
        let hs   = lbl(isNewBest ? "NEW BEST!" : "Best: \(highScore)",
                                             font: "AvenirNext-Bold",   size: minDim * 0.05,  y: mid + frame.height * 0.00)
        let menu = lbl("← Menu",            font: "AvenirNext-Medium", size: minDim * 0.055, y: mid - frame.height * 0.09)

        hs.fontColor  = isNewBest ? UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1) : UIColor(white: 1, alpha: 0.55)
        menu.name = "menuButton"

        [go, sc, hs, menu].forEach { addChild($0) }
        go.run(.sequence([.wait(forDuration: 0.15), .fadeIn(withDuration: 0.3)]))
        sc.run(.sequence([.wait(forDuration: 0.25), .fadeIn(withDuration: 0.3)]))
        hs.run(.sequence([.wait(forDuration: 0.32), .fadeIn(withDuration: 0.3)]))
        menu.run(.sequence([
            .wait(forDuration: 0.4), .fadeIn(withDuration: 0.3),
            .repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.75), .fadeAlpha(to: 0.85, duration: 0.75)]))
        ]))
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Read the top safe area inset so score clears the notch / Dynamic Island
        let topInset = view?.safeAreaInsets.top ?? 44
        let safePad:  CGFloat = topInset + scoreFontSize * 0.9   // extra breathing room

        // Score label — below the safe area, top center
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Heavy"
        scoreLabel.fontSize = scoreFontSize
        scoreLabel.fontColor = .white
        scoreLabel.alpha = 0.9
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - safePad)
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        // Combo label — just below score
        comboLabel = SKLabelNode(text: "")
        comboLabel.fontName = "AvenirNext-Bold"
        comboLabel.fontSize = minDim * 0.045
        comboLabel.fontColor = UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        comboLabel.verticalAlignmentMode = .top
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.position = CGPoint(x: frame.midX, y: frame.maxY - safePad - scoreFontSize - 4)
        comboLabel.zPosition = 20
        addChild(comboLabel)

        // Lives icons — top right
        livesContainer = SKNode()
        livesContainer.zPosition = 20
        addChild(livesContainer)
        updateLivesUI()

        // Tap hint — bottom center
        let hint = SKLabelNode(text: "TAP TO ROTATE")
        hint.fontName = "AvenirNext-Medium"
        hint.fontSize = minDim * 0.033
        hint.fontColor = UIColor(white: 1, alpha: 0.28)
        hint.position = CGPoint(x: frame.midX, y: frame.maxY * 0.05)
        hint.zPosition = 20
        addChild(hint)
        hint.run(.sequence([.wait(forDuration: 5), .fadeOut(withDuration: 1)]))
    }

    private func updateScoreUI() {
        scoreLabel.text = "\(score)"
        scoreLabel.run(.sequence([.scale(to: 1.22, duration: 0.07), .scale(to: 1, duration: 0.1)]))
    }

    private func updateComboUI() {
        if combo >= 5 {
            comboLabel.text = "COMBO x\(combo)"
        } else if combo >= 3 {
            comboLabel.text = "COMBO x\(combo)"
        } else if combo >= 2 {
            comboLabel.text = "COMBO x\(combo)"
        } else {
            comboLabel.text = ""
        }
        if combo >= 3 {
            comboLabel.run(.sequence([.scale(to: 1.15, duration: 0.07), .scale(to: 1, duration: 0.1)]))
        }
    }

    // MARK: - Lives UI
    private func updateLivesUI() {
        livesContainer.removeAllChildren()

        // Icon size: 7.5% of screen width, capped so 3 icons always fit
        let maxTotalWidth = frame.width * 0.38           // max space for all icons
        let rawIconSize   = frame.width * 0.075
        let padding       = rawIconSize * 0.35
        let iconSize      = min(rawIconSize, (maxTotalWidth - padding * 2) / 3)

        // Safe right margin: 4% of screen width minimum, so icons never touch the edge
        let safeMargin    = frame.width * 0.05
        let topInset      = view?.safeAreaInsets.top ?? 44
        let iconY         = frame.maxY - topInset - iconSize * 0.8

        // Rightmost icon edge = frame.maxX - safeMargin - half icon
        let rightEdge     = frame.maxX - safeMargin - iconSize / 2

        for i in 0..<lives {
            // i=0 is leftmost, i=lives-1 is rightmost
            let iconX = rightEdge - CGFloat(lives - 1 - i) * (iconSize + padding)

            if UIImage(named: "life_icon") != nil {
                let icon = SKSpriteNode(imageNamed: "life_icon")
                icon.size = CGSize(width: iconSize, height: iconSize)
                icon.position = CGPoint(x: iconX, y: iconY)
                icon.zPosition = 20
                livesContainer.addChild(icon)
            } else {
                let heart = SKLabelNode(text: "♥")
                heart.fontSize = iconSize
                heart.fontColor = UIColor(red: 1, green: 0.25, blue: 0.35, alpha: 1)
                heart.verticalAlignmentMode = .center
                heart.position = CGPoint(x: iconX, y: iconY)
                heart.zPosition = 20
                livesContainer.addChild(heart)
            }
        }
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isCountingDown { return }
        if isGameOver { goToMenu(); return }
        rotateBox()
    }

    private func goToMenu() {
        let menu = MenuScene(size: frame.size)
        menu.scaleMode = .resizeFill
        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.5))
    }

    private func restartGame() {
        removeAllChildren(); removeAllActions()
        score = 0; lives = 3; combo = 0; rotationIndex = 0
        isGameOver = false; isCountingDown = true
        setupBackground(); setupBox(); setupBalls()
        setupUI(); startCountdown()
    }
}
