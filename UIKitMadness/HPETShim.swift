//
//  HPETShim.swift
//  UIKitMadness
//
//  Created by Bogdan Petru on 27.03.2023.
//

import Foundation
import Combine

class HPETimer
{
    var storage: [AnyCancellable] = []
    var timer: HPET = HPET()
    init()
    {}
    init(timerCallback: @escaping () -> Void)
    {
        timer.timerFired
            .sink{_ in
                timerCallback()
            }
            .store(in: &storage)
    }
    func setCallback(_ callback: @escaping () -> Void)
    {
        timer.timerFired
            .sink{_ in
                callback()
            }
            .store(in: &storage)
    }
    func start()
    {
        timer.start(repeatDelay: 1/60)
    }
    deinit{
        stop()
    }
    func stop() {
        timer.stop()
    }
}
