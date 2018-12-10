//
//  ViewController.swift
//  Segregation
//
//  Created by SHINGAI YOSHIMI on 2018/11/30.
//  Copyright © 2018 SHINGAI YOSHIMI. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    enum Group: UInt32 {
        case red = 0
        case blue = 1
        
        var color: UIColor {
            switch self {
            case .red:
                return .red
            case .blue:
                return .blue
            }
        }
    }
    var interval: TimeInterval = 0
    private let simulator = Simulator(size: UIScreen.main.bounds.size, count: 1000)
    private var dots:[UIView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(render))
        displayLink.add(to: RunLoop.current, forMode: .default)
    }
    
    @objc private func render() {
        let objects = simulator.execute()
        for (i, object) in objects.enumerated() {
            if dots.count <= i {
                generateDot(group: object.group)
            }
            let dot = dots[i]
            dot.center = CGPoint(x: CGFloat(object.x), y: CGFloat(object.y))
        }
    }
    
    private func generateDot(group: UInt32) {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        dot.layer.cornerRadius = 10
        dot.backgroundColor = Group(rawValue: group)!.color.withAlphaComponent(0.5)
        view.addSubview(dot)
        dots.append(dot)
    }
}
