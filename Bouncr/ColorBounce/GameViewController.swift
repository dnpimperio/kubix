//
//  Made by Imperio, Aguirre, Embodo, Soria, and Dolor.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let view = self.view as? SKView else { return }

        let scene = MenuScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill

        view.presentScene(scene)
        view.ignoresSiblingOrder = true

        // Uncomment for debug info during development:
        // view.showsFPS = true
        // view.showsNodeCount = true
        // view.showsPhysics = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
