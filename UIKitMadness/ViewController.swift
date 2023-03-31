//
//  ViewController.swift
//  UIKitMadness
//
//  Created by Bogdan Petru on 08.03.2023.
//

import UIKit
class ViewController: UIViewController {

    let renderer = Renderer()
    var tickTimer : HPETimer = HPETimer()
    func executeOnTick()
    {
        print("Tick")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        renderer.initialize(boundToSurface: view.layer)
        renderer.start()
        tickTimer.setCallback {
            self.executeOnTick()
        }
        tickTimer.start()
    }
}

