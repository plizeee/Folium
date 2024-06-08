//
//  VirtualControllerThumbstick.swift
//  Folium
//
//  Created by Jarrod Norwell on 24/5/2024.
//  Edited by Pliz
//

import Foundation
import UIKit

class VirtualControllerThumbstick : UIView {
    enum ThumbstickType : Int {
        case thumbstickLeft, thumbstickRight
    }
    
    fileprivate var stickImageView: UIImageView!
    fileprivate var circleView: UIView!
    fileprivate var maskLayer: CAShapeLayer!
    
    fileprivate var centerXConstraint, centerYConstraint,
    widthConstraint, heightConstraint: NSLayoutConstraint!
    
    var thumbstickType: ThumbstickType
    var virtualThumbstickDelegate: VirtualControllerThumbstickDelegate
    weak var parentView: VirtualControllerView?

    static let defaultConfiguration = UIImage.SymbolConfiguration(
        pointSize: 0, 
        weight: .regular, 
        scale: .default
    )

    static let movingConfiguration = UIImage.SymbolConfiguration(
        pointSize: 0, 
        weight: .light, 
        scale: .default
    )

    init(_ core: Core, _ thumbstickType: ThumbstickType, _ virtualThumbstickDelegate: VirtualControllerThumbstickDelegate, parentView: VirtualControllerView) {
        self.thumbstickType = thumbstickType
        self.virtualThumbstickDelegate = virtualThumbstickDelegate
        self.parentView = parentView
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        
        // Configure circleView as the border
        circleView = UIView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = .clear
        circleView.layer.borderColor = UIColor.systemGray.cgColor
        circleView.layer.borderWidth = 4
        circleView.layer.cornerRadius = 75 // Half of the width/height (adjust as needed)
        circleView.alpha = 0.5
        circleView.isHidden = true
        addSubview(circleView)
        
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 150), // Adjust as needed
            circleView.heightAnchor.constraint(equalToConstant: 150) // Adjust as needed
        ])
        
        // Configure stickImageView with default configuration and alpha
        stickImageView = .init(
            image: .init(
                systemName: "circle", 
                withConfiguration: VirtualControllerThumbstick.defaultConfiguration
            )?.applyingSymbolConfiguration(.init(
                paletteColors: [.systemGray]
            )))
        stickImageView.alpha = 0.5
        stickImageView.translatesAutoresizingMaskIntoConstraints = false

        switch thumbstickType {
            case .thumbstickLeft:
                if core != .cytrus {
                    stickImageView.alpha = 0
                }
            case .thumbstickRight:
                if core != .cytrus {
                    stickImageView.alpha = 0
                }
        }
        stickImageView.isUserInteractionEnabled = true
        addSubview(stickImageView)
        
        centerXConstraint = stickImageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerXConstraint.isActive = true
        centerYConstraint = stickImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraint.isActive = true
        
        widthConstraint = stickImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2)
        widthConstraint.isActive = true
        heightConstraint = stickImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.2)
        heightConstraint.isActive = true

        // Setup mask for circleView
        maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        circleView.layer.mask = maskLayer
        updateMask()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event) == self ? nil : super.hitTest(point, with: event)
    }
    
    fileprivate func position(in view: UIView, with location: CGPoint) -> (x: Float, y: Float) {
        let radius = view.frame.width / 2
        return (Float((location.x - radius) / radius), Float(-(location.y - radius) / radius))
    }
    
    private func updateMask() {
        let maskPath = UIBezierPath(rect: circleView.bounds)
        let thumbstickRadius = stickImageView.frame.width / 2
        let thumbstickCenter = CGPoint(x: circleView.bounds.midX + centerXConstraint.constant,
                                       y: circleView.bounds.midY + centerYConstraint.constant)
        let innerCirclePath = UIBezierPath(ovalIn: CGRect(
            x: thumbstickCenter.x - thumbstickRadius,
            y: thumbstickCenter.y - thumbstickRadius,
            width: stickImageView.frame.width,
            height: stickImageView.frame.height))
        maskPath.append(innerCirclePath)
        maskLayer.path = maskPath.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }

    private func fadeInCircleView() {
        circleView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.circleView.alpha = 0.5
        }
    }

    private func fadeOutCircleView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.circleView.alpha = 0
        }) { _ in
            self.circleView.isHidden = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }

        stickImageView.image = UIImage(
            systemName: "circle", 
            withConfiguration: VirtualControllerThumbstick.movingConfiguration
        )?.applyingSymbolConfiguration(.init(
            paletteColors: [.systemGray]
        ))
        
        widthConstraint.constant = 50 // Default 20
        heightConstraint.constant = 50 // Default 20
        fadeInCircleView()
        // circleView.isHidden = false
        stickImageView.layoutIfNeeded()
        updateMask()

        if thumbstickType == .thumbstickLeft {
            parentView?.fadeDpadView()
        } else {
            parentView?.fadeXYBAView()
        }
        
        virtualThumbstickDelegate.touchDown(thumbstickType, position(in: self, with: touch.location(in: self)))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        stickImageView.image = UIImage(
            systemName: "circle", 
            withConfiguration: VirtualControllerThumbstick.defaultConfiguration
        )?.applyingSymbolConfiguration(.init(
            paletteColors: [.systemGray]
        ))

        centerXConstraint.constant = 0
        centerYConstraint.constant = 0
        widthConstraint.constant = 0
        heightConstraint.constant = 0
        fadeOutCircleView()
        // circleView.isHidden = true
        stickImageView.layoutIfNeeded()
        updateMask()

        if thumbstickType == .thumbstickLeft {
            parentView?.unfadeDpadView()
        } else {
            parentView?.unfadeXYBAView()
        }
        
        virtualThumbstickDelegate.touchUpInside(thumbstickType, (0, 0))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }

        let radius = circleView.bounds.width / 2

        let touchPoint = touch.location(in: self)
        let centerPoint = CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY)

        var translation = CGPoint(x: touchPoint.x - centerPoint.x, y: touchPoint.y - centerPoint.y)
        let distance = sqrt(translation.x * translation.x + translation.y * translation.y)

        if distance > radius {
            let scale = radius / distance
            translation.x *= scale
            translation.y *= scale
        }

        centerXConstraint.constant = translation.x
        centerYConstraint.constant = translation.y
        stickImageView.layoutIfNeeded()
        updateMask()

        virtualThumbstickDelegate.touchDragInside(thumbstickType, position(in: self, with: touch.location(in: self)))
    }
}
