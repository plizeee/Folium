//
//  LMVirtualControllerView.swift
//  Limon
//
//  Created by Jarrod Norwell on 10/9/23.
//  Edited by Pliz
//

import Foundation
import UIKit

class PassthroughView : UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event) == self ? nil : super.hitTest(point, with: event)
    }
}

class VirtualControllerView : UIView {
    var virtualButtonDelegate: VirtualControllerButtonDelegate
    var virtualThumbstickDelegate: VirtualControllerThumbstickDelegate
    
    var dpadView, xybaView: PassthroughView!
    fileprivate var dpadUpButton, dpadLeftButton, dpadDownButton, dpadRightButton: VirtualControllerButton!
    
    var leftThumbstickView, rightThumbstickView: VirtualControllerThumbstick!
    
    fileprivate var aButton, bButton, xButton, yButton: VirtualControllerButton!
    
    fileprivate var minusButton, plusButton: VirtualControllerButton!
    
    fileprivate var lButton, zlButton, rButton, zrButton: VirtualControllerButton!
    
    fileprivate var portraitConstraints, landscapeConstraints: [[NSLayoutConstraint]]!
    
    fileprivate var core: Core
    init(_ core: Core, _ virtualButtonDelegate: VirtualControllerButtonDelegate, _ virtualThumbstickDelegate: VirtualControllerThumbstickDelegate) {
        self.core = core
        self.virtualButtonDelegate = virtualButtonDelegate
        self.virtualThumbstickDelegate = virtualThumbstickDelegate
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        portraitConstraints = []
        landscapeConstraints = []
        
        addDpadView()
        addXYBAView()
        
        addLThumbstickView()
        addRThumbstickView()
        
        if UIApplication.shared.statusBarOrientation == .portrait {
            addConstraints(portraitConstraints[0])
            addConstraints(portraitConstraints[1])
            addConstraints(portraitConstraints[2])
            addConstraints(portraitConstraints[3])
        } else {
            addConstraints(landscapeConstraints[0])
            addConstraints(landscapeConstraints[1])
            addConstraints(landscapeConstraints[2])
            addConstraints(landscapeConstraints[3])
        }

        let defaultColors: (UIColor, UIColor) = (.systemGray, .systemGray)
        
        switch core {
        case .cytrus:


            addDpadUp(false, buttonColors: defaultColors)
            addDpadLeft(false, buttonColors: defaultColors)
            addDpadDown(false, buttonColors: defaultColors)
            addDpadRight(false, buttonColors: defaultColors)
            
            addA(false, buttonColors: defaultColors)
            addB(false, buttonColors: defaultColors)
            addX(false, buttonColors: defaultColors)
            addY(false, buttonColors: defaultColors)
            
            addMinus(false, buttonColors: defaultColors)
            addPlus(false, buttonColors: defaultColors)
            
            addL(false, buttonColors: defaultColors)
            addR(false, buttonColors: defaultColors)
            addZL(false, buttonColors: defaultColors)
            addZR(false, buttonColors: defaultColors)
        case .grape:
            addDpadUp(false, buttonColors: defaultColors)
            addDpadLeft(false, buttonColors: defaultColors)
            addDpadDown(false, buttonColors: defaultColors)
            addDpadRight(false, buttonColors: defaultColors)
            
            addA(false, buttonColors: defaultColors)
            addB(false, buttonColors: defaultColors)
            addX(false, buttonColors: defaultColors)
            addY(false, buttonColors: defaultColors)
            
            addMinus(false, buttonColors: defaultColors)
            addPlus(false, buttonColors: defaultColors)
            
            addL(false, buttonColors: defaultColors)
            addR(false, buttonColors: defaultColors)
        case .kiwi:
            addDpadUp(false, buttonColors: defaultColors)
            addDpadLeft(false, buttonColors: defaultColors)
            addDpadDown(false, buttonColors: defaultColors)
            addDpadRight(false, buttonColors: defaultColors)

            addA(false, buttonColors: defaultColors)
            addB(false, buttonColors: defaultColors)
            
            // addA(false, buttonColors: core.buttonColors[.a] ?? (.systemRed, .systemGray))
            // addB(false, buttonColors: core.buttonColors[.b] ?? (.systemRed, .systemGray))
            
            addMinus(false, buttonColors: defaultColors)
            addPlus(false, buttonColors: defaultColors)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event) == self ? nil : super.hitTest(point, with: event)
    }
    
    func toggleConstraints() {
        if UIApplication.shared.statusBarOrientation == .portrait {
            addConstraints(portraitConstraints[0])
            addConstraints(portraitConstraints[1])
            addConstraints(portraitConstraints[2])
            addConstraints(portraitConstraints[3])
            
            removeConstraints(landscapeConstraints[0])
            removeConstraints(landscapeConstraints[1])
            removeConstraints(landscapeConstraints[2])
            removeConstraints(landscapeConstraints[3])
        } else {
            removeConstraints(portraitConstraints[0])
            removeConstraints(portraitConstraints[1])
            removeConstraints(portraitConstraints[2])
            removeConstraints(portraitConstraints[3])
            
            addConstraints(landscapeConstraints[0])
            addConstraints(landscapeConstraints[1])
            addConstraints(landscapeConstraints[2])
            addConstraints(landscapeConstraints[3])
        }
        
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    /*=============== ADD VIEWS ===============*/

    fileprivate func addDpadView() {
        dpadView = .init()
        dpadView.translatesAutoresizingMaskIntoConstraints = false
        dpadView.isUserInteractionEnabled = true
        addSubview(dpadView)
        let portraitWidthConstraint = if UIDevice.current.userInterfaceIdiom == .phone {
            dpadView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: -20)
        } else {
            dpadView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, multiplier: 1 / 5, constant: -20)
        }
        
        portraitConstraints.append([
            dpadView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            dpadView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            portraitWidthConstraint,
            dpadView.heightAnchor.constraint(equalTo: dpadView.widthAnchor)
        ])
        
        let landscapeHeightConstraint = if UIDevice.current.userInterfaceIdiom == .phone {
            dpadView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: 20)
        } else {
            dpadView.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor, multiplier: 1 / 5, constant: -20)
        }
        
        landscapeConstraints.append([
            landscapeHeightConstraint,
            dpadView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            dpadView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            dpadView.widthAnchor.constraint(equalTo: dpadView.heightAnchor)
        ])
        
        
        if UIApplication.shared.statusBarOrientation == .portrait {
            addConstraints(portraitConstraints[0])
        } else {
            addConstraints(landscapeConstraints[0])
        }
    }
    
    fileprivate func addXYBAView() {
        xybaView = .init()
        xybaView.translatesAutoresizingMaskIntoConstraints = false
        xybaView.isUserInteractionEnabled = true
        addSubview(xybaView)
        
        let portraitWidthConstraint = if UIDevice.current.userInterfaceIdiom == .phone {
            xybaView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: 20)
        } else {
            xybaView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, multiplier: 1 / 5, constant: -20)
        }
        
        portraitConstraints.append([
            xybaView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            portraitWidthConstraint,
            xybaView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            xybaView.heightAnchor.constraint(equalTo: xybaView.widthAnchor)
        ])
        
        let landscapeHeightConstraint = if UIDevice.current.userInterfaceIdiom == .phone {
            xybaView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: 20)
        } else {
            xybaView.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor, multiplier: 1 / 5, constant: -20)
        }
        
        landscapeConstraints.append([
            landscapeHeightConstraint,
            xybaView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            xybaView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            xybaView.widthAnchor.constraint(equalTo: xybaView.heightAnchor)
        ])
        
        if UIApplication.shared.statusBarOrientation == .portrait {
            addConstraints(portraitConstraints[1])
        } else {
            addConstraints(landscapeConstraints[1])
        }
    }
    
    fileprivate func addLThumbstickView() {
        leftThumbstickView = .init(core, .thumbstickLeft, virtualThumbstickDelegate)
        leftThumbstickView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftThumbstickView)
        
        portraitConstraints.append([
            leftThumbstickView.topAnchor.constraint(equalTo: dpadView.topAnchor),
            leftThumbstickView.leadingAnchor.constraint(equalTo: dpadView.leadingAnchor),
            leftThumbstickView.bottomAnchor.constraint(equalTo: dpadView.bottomAnchor),
            leftThumbstickView.trailingAnchor.constraint(equalTo: dpadView.trailingAnchor)
        ])
        
        landscapeConstraints.append([
            leftThumbstickView.topAnchor.constraint(equalTo: dpadView.topAnchor),
            leftThumbstickView.leadingAnchor.constraint(equalTo: dpadView.leadingAnchor),
            leftThumbstickView.bottomAnchor.constraint(equalTo: dpadView.bottomAnchor),
            leftThumbstickView.trailingAnchor.constraint(equalTo: dpadView.trailingAnchor)
        ])
    }
    
    fileprivate func addRThumbstickView() {
        rightThumbstickView = .init(core, .thumbstickRight, virtualThumbstickDelegate)
        rightThumbstickView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightThumbstickView)
        
        portraitConstraints.append([
            rightThumbstickView.topAnchor.constraint(equalTo: xybaView.topAnchor),
            rightThumbstickView.leadingAnchor.constraint(equalTo: xybaView.leadingAnchor),
            rightThumbstickView.bottomAnchor.constraint(equalTo: xybaView.bottomAnchor),
            rightThumbstickView.trailingAnchor.constraint(equalTo: xybaView.trailingAnchor)
        ])
        
        landscapeConstraints.append([
            rightThumbstickView.topAnchor.constraint(equalTo: xybaView.topAnchor),
            rightThumbstickView.leadingAnchor.constraint(equalTo: xybaView.leadingAnchor),
            rightThumbstickView.bottomAnchor.constraint(equalTo: xybaView.bottomAnchor),
            rightThumbstickView.trailingAnchor.constraint(equalTo: xybaView.trailingAnchor)
        ])
    }


    /*=============== ADD BUTTONS ===============*/

    fileprivate func addDpadUp(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        dpadUpButton = .init(buttonColors: buttonColors, buttonType: .dpadUp, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        dpadView.addSubview(dpadUpButton)
        
        addConstraints([
            dpadUpButton.topAnchor.constraint(equalTo: dpadView.topAnchor),
            dpadUpButton.widthAnchor.constraint(equalTo: dpadView.widthAnchor, multiplier: 1 / 3),
            dpadUpButton.heightAnchor.constraint(equalTo: dpadView.heightAnchor, multiplier: 1 / 3),
            dpadUpButton.centerXAnchor.constraint(equalTo: dpadView.centerXAnchor)
        ])
    }
    
    fileprivate func addDpadLeft(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        dpadLeftButton = .init(buttonColors: buttonColors, buttonType: .dpadLeft, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        dpadView.addSubview(dpadLeftButton)
        
        addConstraints([
            dpadLeftButton.leadingAnchor.constraint(equalTo: dpadView.leadingAnchor),
            dpadLeftButton.widthAnchor.constraint(equalTo: dpadView.widthAnchor, multiplier: 1 / 3),
            dpadLeftButton.heightAnchor.constraint(equalTo: dpadView.heightAnchor, multiplier: 1 / 3),
            dpadLeftButton.centerYAnchor.constraint(equalTo: dpadView.centerYAnchor)
        ])
    }
    
    fileprivate func addDpadDown(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        dpadDownButton = .init(buttonColors: buttonColors, buttonType: .dpadDown, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        dpadView.addSubview(dpadDownButton)
        
        addConstraints([
            dpadDownButton.bottomAnchor.constraint(equalTo: dpadView.bottomAnchor),
            dpadDownButton.widthAnchor.constraint(equalTo: dpadView.widthAnchor, multiplier: 1 / 3),
            dpadDownButton.heightAnchor.constraint(equalTo: dpadView.heightAnchor, multiplier: 1 / 3),
            dpadDownButton.centerXAnchor.constraint(equalTo: dpadView.centerXAnchor)
        ])
    }
    
    fileprivate func addDpadRight(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        dpadRightButton = .init(buttonColors: buttonColors, buttonType: .dpadRight, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        dpadView.addSubview(dpadRightButton)
        
        addConstraints([
            dpadRightButton.trailingAnchor.constraint(equalTo: dpadView.trailingAnchor),
            dpadRightButton.widthAnchor.constraint(equalTo: dpadView.widthAnchor, multiplier: 1 / 3),
            dpadRightButton.heightAnchor.constraint(equalTo: dpadView.heightAnchor, multiplier: 1 / 3),
            dpadRightButton.centerYAnchor.constraint(equalTo: dpadView.centerYAnchor)
        ])
    }
    
    fileprivate func addX(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        xButton = .init(buttonColors: buttonColors, buttonType: .x, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        xybaView.addSubview(xButton)
        
        addConstraints([
            xButton.topAnchor.constraint(equalTo: xybaView.topAnchor),
            xButton.widthAnchor.constraint(equalTo: xybaView.widthAnchor, multiplier: 1 / 3),
            xButton.heightAnchor.constraint(equalTo: xybaView.heightAnchor, multiplier: 1 / 3),
            xButton.centerXAnchor.constraint(equalTo: xybaView.centerXAnchor)
        ])
    }
    
    fileprivate func addY(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        yButton = .init(buttonColors: buttonColors, buttonType: .y, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        xybaView.addSubview(yButton)
        
        addConstraints([
            yButton.leadingAnchor.constraint(equalTo: xybaView.leadingAnchor),
            yButton.widthAnchor.constraint(equalTo: xybaView.widthAnchor, multiplier: 1 / 3),
            yButton.heightAnchor.constraint(equalTo: xybaView.heightAnchor, multiplier: 1 / 3),
            yButton.centerYAnchor.constraint(equalTo: xybaView.centerYAnchor)
        ])
    }
    
    fileprivate func addB(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        bButton = .init(buttonColors: buttonColors, buttonType: .b, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        xybaView.addSubview(bButton)
        
        addConstraints([
            bButton.bottomAnchor.constraint(equalTo: xybaView.bottomAnchor),
            bButton.widthAnchor.constraint(equalTo: xybaView.widthAnchor, multiplier: 1 / 3),
            bButton.heightAnchor.constraint(equalTo: xybaView.heightAnchor, multiplier: 1 / 3),
            bButton.centerXAnchor.constraint(equalTo: xybaView.centerXAnchor)
        ])
    }
    
    fileprivate func addA(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        aButton = .init(buttonColors: buttonColors, buttonType: .a, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        xybaView.addSubview(aButton)
        
        addConstraints([
            aButton.trailingAnchor.constraint(equalTo: xybaView.trailingAnchor),
            aButton.widthAnchor.constraint(equalTo: xybaView.widthAnchor, multiplier: 1 / 3),
            aButton.heightAnchor.constraint(equalTo: xybaView.heightAnchor, multiplier: 1 / 3),
            aButton.centerYAnchor.constraint(equalTo: xybaView.centerYAnchor)
        ])
    }
    
    fileprivate func addMinus(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        minusButton = .init(buttonColors: buttonColors, buttonType: .minus, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        dpadView.addSubview(minusButton)
        
        addConstraints([
            minusButton.bottomAnchor.constraint(equalTo: dpadView.bottomAnchor),
            minusButton.trailingAnchor.constraint(equalTo: dpadView.trailingAnchor),
            minusButton.widthAnchor.constraint(equalTo: dpadView.widthAnchor, multiplier: 1 / 5),
            minusButton.heightAnchor.constraint(equalTo: dpadView.heightAnchor, multiplier: 1 / 5)
        ])
    }
    
    fileprivate func addPlus(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        plusButton = .init(buttonColors: buttonColors, buttonType: .plus, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        xybaView.addSubview(plusButton)
        
        addConstraints([
            plusButton.leadingAnchor.constraint(equalTo: xybaView.leadingAnchor),
            plusButton.bottomAnchor.constraint(equalTo: xybaView.bottomAnchor),
            plusButton.widthAnchor.constraint(equalTo: xybaView.widthAnchor, multiplier: 1 / 5),
            plusButton.heightAnchor.constraint(equalTo: xybaView.heightAnchor, multiplier: 1 / 5)
        ])
    }

    fileprivate func addL(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        lButton = .init(buttonColors: buttonColors, buttonType: .l, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        addSubview(lButton)
        
        addConstraints([
            lButton.leadingAnchor.constraint(equalTo: xybaView.leadingAnchor, constant: -10),
            lButton.bottomAnchor.constraint(equalTo: xybaView.topAnchor, constant: 30), // Default -20 (higher means lower)
            lButton.trailingAnchor.constraint(equalTo: xybaView.centerXAnchor, constant: -30), // Default -10 (higher means bigger scale)
            lButton.heightAnchor.constraint(equalTo: lButton.widthAnchor, multiplier: 1 / 2) // Default 1 / 2
        ])
    }

    fileprivate func addZL(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        zlButton = .init(buttonColors: buttonColors, buttonType: .zl, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        addSubview(zlButton)
        
        addConstraints([
            zlButton.leadingAnchor.constraint(equalTo: dpadView.leadingAnchor, constant: -10),
            zlButton.bottomAnchor.constraint(equalTo: dpadView.topAnchor, constant: 30), // Default -20 (higher means lower)
            zlButton.trailingAnchor.constraint(equalTo: dpadView.centerXAnchor, constant: -30), // Default -10 (higher means bigger scale)
            zlButton.heightAnchor.constraint(equalTo: zlButton.widthAnchor, multiplier: 1 / 2) // Default 1 / 2
        ])
    }
        

    fileprivate func addR(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        rButton = .init(buttonColors: buttonColors, buttonType: .r, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        addSubview(rButton)
        
        addConstraints([
            rButton.leadingAnchor.constraint(equalTo: xybaView.centerXAnchor, constant: 30), // Default 10
            rButton.bottomAnchor.constraint(equalTo: xybaView.topAnchor, constant: 30), // Default -20
            rButton.trailingAnchor.constraint(equalTo: xybaView.trailingAnchor, constant: 10),
            rButton.heightAnchor.constraint(equalTo: rButton.widthAnchor, multiplier: 1 / 2) // Default 1 / 2
        ])
    }

    fileprivate func addZR(_ shouldHide: Bool, buttonColors: (UIColor, UIColor)) {
        zrButton = .init(buttonColors: buttonColors, buttonType: .zr, virtualButtonDelegate: virtualButtonDelegate, shouldHide: shouldHide)
        addSubview(zrButton)
        
        addConstraints([
            zrButton.leadingAnchor.constraint(equalTo: dpadView.centerXAnchor, constant: 30), // Default 10
            zrButton.bottomAnchor.constraint(equalTo: dpadView.topAnchor, constant: 30), // Default -20
            zrButton.trailingAnchor.constraint(equalTo: dpadView.trailingAnchor, constant: 10),
            zrButton.heightAnchor.constraint(equalTo: zrButton.widthAnchor, multiplier: 1 / 2) // Default 1 / 2
        ])
    }
    

    /*=============== FADE/UNFADE ===============*/

    func fade() {
        let minAlpha: CGFloat = 0
        UIView.animate(withDuration: 0.2) {
            self.dpadView.alpha = minAlpha
            self.xybaView.alpha = minAlpha
            
            self.lButton.alpha = minAlpha
            self.rButton.alpha = minAlpha
            
            if self.core == .cytrus {
                self.zlButton.alpha = minAlpha
                self.zrButton.alpha = minAlpha
            }
        }
    }
    
    func unfade() {
        UIView.animate(withDuration: 0.2) {
            self.dpadView.alpha = 0.5
            self.xybaView.alpha = 0.5
            
            self.lButton.alpha = 0.5
            self.rButton.alpha = 0.5
            
            if self.core == .cytrus {
                self.zlButton.alpha = 0.5
                self.zrButton.alpha = 0.5
            }
        }
    }
}
