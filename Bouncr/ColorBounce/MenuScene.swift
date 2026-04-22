// 
//  Made by Imperio, Aguirre, Embodo, Soria, and Dolor.
//

import SpriteKit

class MenuScene: SKScene {

    private var minDim: CGFloat { min(frame.width, frame.height) }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1)
        setupBackground()
        setupUI()
    }

    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "background")
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.size = frame.size
        bg.zPosition = -10
        addChild(bg)
    }

    private func setupUI() {
        let mid = frame.midY

        // MARK: Game Title
        let title = SKLabelNode(text: "KUBIX")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = minDim * 0.11
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: mid + frame.height * 0.18)
        title.zPosition = 10
        title.alpha = 0
        addChild(title)
        title.run(.sequence([
            .wait(forDuration: 0.2),
            .fadeIn(withDuration: 0.5)
        ]))

        // MARK: High Score
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        let hsLabel = SKLabelNode(text: "BEST: \(highScore)")
        hsLabel.fontName = "AvenirNext-Bold"
        hsLabel.fontSize = minDim * 0.055
        hsLabel.fontColor = UIColor(white: 1, alpha: 0.6)
        hsLabel.position = CGPoint(x: frame.midX, y: mid + frame.height * 0.10)
        hsLabel.zPosition = 10
        hsLabel.alpha = 0
        addChild(hsLabel)
        hsLabel.run(.sequence([
            .wait(forDuration: 0.35),
            .fadeIn(withDuration: 0.5)
        ]))

        // MARK: Play Button — simple arrow
        let arrowLabel = SKLabelNode(text: "▶")
        arrowLabel.fontName             = "AvenirNext-Heavy"
        arrowLabel.fontSize             = minDim * 0.18
        arrowLabel.fontColor            = .white
        arrowLabel.verticalAlignmentMode   = .center
        arrowLabel.horizontalAlignmentMode = .center
        arrowLabel.position  = CGPoint(x: frame.midX, y: mid - frame.height * 0.02)
        arrowLabel.zPosition = 10
        arrowLabel.name      = "playButton"
        arrowLabel.alpha     = 0
        addChild(arrowLabel)

        arrowLabel.run(.sequence([
            .wait(forDuration: 0.5),
            .fadeIn(withDuration: 0.5),
            .repeatForever(.sequence([
                .scale(to: 1.08, duration: 0.8),
                .scale(to: 1.00, duration: 0.8)
            ]))
        ]))

        // MARK: Tap hint
        let hint = SKLabelNode(text: "TAP TO PLAY")
        hint.fontName = "AvenirNext-Medium"
        hint.fontSize = minDim * 0.033
        hint.fontColor = UIColor(white: 1, alpha: 0.35)
        hint.position = CGPoint(x: frame.midX, y: mid - frame.height * 0.14)
        hint.zPosition = 10
        hint.alpha = 0
        addChild(hint)
        hint.run(.sequence([
            .wait(forDuration: 0.7),
            .fadeIn(withDuration: 0.5),
            .repeatForever(.sequence([
                .fadeAlpha(to: 0.15, duration: 0.9),
                .fadeAlpha(to: 0.35, duration: 0.9)
            ]))
        ]))
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        // Tapping the play button OR anywhere launches the game
        if tapped.contains(where: { $0.name == "playButton" }) {
            launchGame()
        }
    }

    private func launchGame() {
        let game = GameScene(size: frame.size)
        game.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(game, transition: transition)
    }
}
