//
//  VirtualControllerButton.swift
//  Limon
//
//  Created by Jarrod Norwell on 10/18/23.
//  Edited by Pliz
//

import Foundation
import UIKit

class VirtualControllerButton : UIView {
    enum ButtonType : String, Codable {
        case // xyba buttons
            a = "a.circle", 
            b = "b.circle", 
            x = "x.circle", 
            y = "y.circle"
        case // menu buttons
            minus = "minus.circle", 
            plus = "plus.circle"
        case // dpad buttons
            dpadUp = "arrowtriangle.up.circle", 
            dpadLeft = "arrowtriangle.left.circle", 
            dpadDown = "arrowtriangle.down.circle",
            dpadRight = "arrowtriangle.right.circle"
        case // shoulder buttons
            l = "l.button.roundedbottom.horizontal", 
            r = "r.button.roundedbottom.horizontal"
        case // z buttons
            zl = "zl.button.roundedtop.horizontal",
            zr = "zr.button.roundedtop.horizontal"
        // case // joystick buttons
        //     ls = "l.joystick.press.down", 
        //     rs = "r.joystick.press.down"
        // case // dropdown buttons
        //     dropdown = "chevron.down.circle",
        //     general = "gearshape.circle", 
        //     hide = "eye.circle", 
        //     special = "star.circle", 
        //     volume = "speaker.wave.2.circle"
        // case // general
        //     pause = "pause.circle", 
        //     home = "house.circle"
        // case // special buttons
        //     turbo = "bolt.circle", 
        //     toggle = "arrow.down.to.line.circle"
        // case // hide buttons
        //     hide_ui = "eye.slash.circle",
        //     hide_dpad = "l.joystick"
        // case // volume buttons
        //     mute = "speaker.slash.circle",
        //     volDown = "speaker.minus",
        //     volUp = "speaker.plus"
        // case // custom buttons
        //     target = "scope"

        var systemName: String {           
            switch self {
                default: return rawValue
            }
        }
    }
    
    var imageView: UIImageView!
    fileprivate var colors: UIImage.SymbolConfiguration
    fileprivate var pointSize: CGFloat
    
    let buttonColors: (UIColor, UIColor)
    let buttonType: ButtonType
    var virtualButtonDelegate: VirtualControllerButtonDelegate
    init(buttonColors: (UIColor, UIColor), buttonType: ButtonType, virtualButtonDelegate: VirtualControllerButtonDelegate, shouldHide: Bool) {
        self.buttonColors = buttonColors
        self.buttonType = buttonType
        self.virtualButtonDelegate = virtualButtonDelegate
        self.colors = .init(paletteColors: [])
        self.pointSize = if buttonType == .minus || buttonType == .plus { 32 } else { 40 }
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        colors = if buttonType.systemName == "circle"/* || [ButtonType.l, ButtonType.zl, ButtonType.r, ButtonType.zr].contains(buttonType)*/ {
            .init(paletteColors: [buttonColors.0, buttonColors.1])
        } else {
            .init(paletteColors: [buttonColors.0, buttonColors.1])
        }
        
        imageView = .init(image: .init(systemName: buttonType.systemName)?
            .applyingSymbolConfiguration(.init(pointSize: pointSize, weight: .regular, scale: .large))?
            .applyingSymbolConfiguration(colors))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = shouldHide ? 0 : 1
        imageView.isUserInteractionEnabled = shouldHide ? false : true
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        addConstraints([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        virtualButtonDelegate.touchDown(buttonType)
        if buttonType.systemName == "circle"/* || [ButtonType.l, ButtonType.zl, ButtonType.r, ButtonType.zr].contains(buttonType)*/ {
            guard let image = UIImage(systemName: buttonType.systemName.appending(".fill"))?
                .applyingSymbolConfiguration(.init(pointSize: pointSize, weight: .regular, scale: .large))?
                .applyingSymbolConfiguration(colors) else {
                return
            }
            
            if #available(iOS 17, *) {
                imageView.setSymbolImage(image, contentTransition: .automatic)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        virtualButtonDelegate.touchUpInside(buttonType)
        if buttonType.systemName == "circle"/* || [ButtonType.l, ButtonType.zl, ButtonType.r, ButtonType.zr].contains(buttonType)*/ {
            guard let image = UIImage(systemName: buttonType.systemName)?
                .applyingSymbolConfiguration(.init(pointSize: pointSize, weight: .regular, scale: .large))?
                .applyingSymbolConfiguration(colors) else {
                return
            }
            
            if #available(iOS 17, *) {
                imageView.setSymbolImage(image, contentTransition: .automatic)
            }
        }
    }
}
