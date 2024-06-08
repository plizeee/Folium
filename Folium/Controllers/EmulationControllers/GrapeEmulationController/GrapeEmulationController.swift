//
//  GrapeEmulationController.swift
//  Folium-iOS
//
//  Created by Jarrod Norwell on 16/4/2024.
//

import Foundation
import GameController
import Grape
import Metal
// import MetalFX
import MetalKit
import SDL2
import UIKit

typealias GrapeCallback = @convention(c)(UnsafeMutableRawPointer?, UnsafeMutablePointer<UInt8>?, Int32) -> Void
class GrapeEmulationController : EmulationScreensController {
    fileprivate var grape: Grape = .shared
    fileprivate var isRunning: Bool = false
    
    fileprivate var audioDeviceID: SDL_AudioDeviceID!
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate var commandQueue: MTLCommandQueue!
    fileprivate var pipelineDescriptor: MTLRenderPipelineDescriptor!
    fileprivate var pipelineState: MTLRenderPipelineState!
    fileprivate var primaryTexture, secondaryTexture: MTLTexture!
    
    override init(_ core: Core, _ game: AnyHashable? = nil) {
        super.init(core, game)
        guard let game = game as? GrapeManager.Library.Game else {
            return
        }
        
        grape.insert(game: game.fileDetails.url)
        
        configureAudio()
        configureMetal()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        var gearButtonConfiguration = UIButton.Configuration.borderless()
        gearButtonConfiguration.buttonSize = .small
        gearButtonConfiguration.image = .init(systemName: "gearshape.fill")?
            .applyingSymbolConfiguration(.init(paletteColors: [.label]))
        
        let button = UIButton(configuration: gearButtonConfiguration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.menu = menu(button)
        button.showsMenuAsPrimaryAction = true
        view.addSubview(button)
        button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5).isActive = true
        button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5).isActive = true
        
        NotificationCenter.default.addObserver(forName: .init("sceneDidChange"), object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let state = userInfo["state"] as? Int else {
                return
            }
            
            self.grape.setPaused(state == 0)
            button.menu = self.menu(button)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            guard let game = game as? GrapeManager.Library.Game else {
                return
            }
            
            if game.gameType == .nds {
                grape.updateScreenLayout(with: secondaryScreen.frame.size)
            }
            
            Thread.setThreadPriority(1.0)
            Thread.detachNewThread(step)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let game = game as? GrapeManager.Library.Game else {
            return
        }
        
        coordinator.animate { _ in } completion: { _ in
            if game.gameType == .nds {
                self.grape.updateScreenLayout(with: self.secondaryScreen.frame.size)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let game = game as? GrapeManager.Library.Game, let touch = touches.first, touch.view == secondaryScreen, game.gameType == .nds else {
            return
        }
        
        grape.touchBegan(at: touch.location(in: secondaryScreen))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let game = game as? GrapeManager.Library.Game, game.gameType == .nds else {
            return
        }
        
        grape.touchEnded()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let game = game as? GrapeManager.Library.Game, let touch = touches.first, touch.view == secondaryScreen, game.gameType == .nds else {
            return
        }
        
        grape.touchMoved(at: touch.location(in: secondaryScreen))
    }
    
    override func controllerDidConnect(_ notification: Notification) {
        super.controllerDidConnect(notification)
        guard let controller = notification.object as? GCController, let extendedGamepad = controller.extendedGamepad else {
            return
        }
        
        extendedGamepad.dpad.up.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadUp) : self.touchUpInside(.dpadUp)
        }
        
        extendedGamepad.dpad.down.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadDown) : self.touchUpInside(.dpadDown)
        }
        
        extendedGamepad.dpad.left.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadLeft) : self.touchUpInside(.dpadLeft)
        }
        
        extendedGamepad.dpad.right.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadRight) : self.touchUpInside(.dpadRight)
        }
        
        extendedGamepad.buttonOptions?.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.minus) : self.touchUpInside(.minus)
        }
        
        extendedGamepad.buttonMenu.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.plus) : self.touchUpInside(.plus)
        }
        
        extendedGamepad.buttonA.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.a) : self.touchUpInside(.a)
        }
        
        extendedGamepad.buttonB.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.b) : self.touchUpInside(.b)
        }
        
        extendedGamepad.buttonX.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.x) : self.touchUpInside(.x)
        }
        
        extendedGamepad.buttonY.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.y) : self.touchUpInside(.y)
        }
        
        extendedGamepad.leftShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.l) : self.touchUpInside(.l)
        }
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }

        // Default to using the triggers for the shoulder buttons
        extendedGamepad.leftTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.l) : self.touchUpInside(.l)
        }

        // Default to using the triggers for the shoulder buttons
        extendedGamepad.rightTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }

        // Default to using the left thumbstick for the dpad
        extendedGamepad.leftThumbstick.valueChangedHandler = { dpad, x, y in
            x > 0.5 ? self.touchDown(.dpadRight) : self.touchUpInside(.dpadRight)
            x < -0.5 ? self.touchDown(.dpadLeft) : self.touchUpInside(.dpadLeft)
            y < -0.5 ? self.touchDown(.dpadDown) : self.touchUpInside(.dpadDown)
            y > 0.5 ? self.touchDown(.dpadUp) : self.touchUpInside(.dpadUp)
        }
        
        // Experimenting with using the right thumbstick for touch input, turns out it's not very good
        // extendedGamepad.rightThumbstick.valueChangedHandler = { dpad, x, y in
        //     let x = (x + 1) * 128 // convert from -1 to 1 to 0 to 256
        //     let y = (-y + 1) * 96 // convert from -1 to 1 to 0 to 192
            
        //     if(x == 128 && y == 96) {
        //         self.grape.touchEnded()
        //     } else {
        //         self.grape.touchBegan(at: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        //     }
        // }
    }
    
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
        switch buttonType {
        case .dpadUp:
            grape.virtualControllerButtonDown(6)
        case .dpadDown:
            grape.virtualControllerButtonDown(7)
        case .dpadLeft:
            grape.virtualControllerButtonDown(5)
        case .dpadRight:
            grape.virtualControllerButtonDown(4)
        case .minus:
            grape.virtualControllerButtonDown(2)
        case .plus:
            grape.virtualControllerButtonDown(3)
        case .a:
            grape.virtualControllerButtonDown(0)
        case .b:
            grape.virtualControllerButtonDown(1)
        case .x:
            grape.virtualControllerButtonDown(10)
        case .y:
            grape.virtualControllerButtonDown(11)
        case .l:
            grape.virtualControllerButtonDown(9)
        case .r:
            grape.virtualControllerButtonDown(8)
        default:
            break
        }
    }
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
        switch buttonType {
        case .dpadUp:
            grape.virtualControllerButtonUp(6)
        case .dpadDown:
            grape.virtualControllerButtonUp(7)
        case .dpadLeft:
            grape.virtualControllerButtonUp(5)
        case .dpadRight:
            grape.virtualControllerButtonUp(4)
        case .minus:
            grape.virtualControllerButtonUp(2)
        case .plus:
            grape.virtualControllerButtonUp(3)
        case .a:
            grape.virtualControllerButtonUp(0)
        case .b:
            grape.virtualControllerButtonUp(1)
        case .x:
            grape.virtualControllerButtonUp(10)
        case .y:
            grape.virtualControllerButtonUp(11)
        case .l:
            grape.virtualControllerButtonUp(9)
        case .r:
            grape.virtualControllerButtonUp(8)
        default:
            break
        }
    }
    
    fileprivate func menu(_ button: UIButton) -> UIMenu {
        if #available(iOS 16, *) {
            .init(preferredElementSize: .medium, children: [
                UIAction(title: grape.isPaused() ? "Play" : "Pause", image: .init(systemName: grape.isPaused() ? "play.fill" : "pause.fill"), handler: { action in
                    self.grape.setPaused(!self.grape.isPaused())
                    button.menu = self.menu(button)
                }),
                UIAction(title: "Stop & Exit", image: .init(systemName: "stop.fill"), attributes: [.destructive, .disabled], handler: { action in })
            ])
        } else {
            .init(children: [
                UIAction(title: grape.isPaused() ? "Play" : "Pause", image: .init(systemName: grape.isPaused() ? "play.fill" : "pause.fill"), handler: { action in
                    self.grape.setPaused(!self.grape.isPaused())
                    button.menu = self.menu(button)
                }),
                UIAction(title: "Stop & Exit", image: .init(systemName: "stop.fill"), attributes: [.destructive, .disabled], handler: { action in })
            ])
        }
    }
    
    @objc fileprivate func step() {
        while !grape.isPaused() {
            grape.step()
        }
    }
}

extension GrapeEmulationController {
    fileprivate func configureAudio() {
        SDL_SetMainReady()
        SDL_InitSubSystem(SDL_INIT_AUDIO)
        
        let callback: GrapeCallback = { userdata, stream, len in
            guard let userdata else {
                return
            }
            
            let viewController = Unmanaged<GrapeEmulationController>.fromOpaque(userdata).takeUnretainedValue()
            SDL_memcpy(stream, viewController.grape.audioBuffer(), Int(len))
        }
        
        var spec = SDL_AudioSpec()
        spec.callback = callback
        spec.userdata = Unmanaged.passUnretained(self).toOpaque()
        spec.channels = 2
        spec.format = SDL_AudioFormat(AUDIO_S16)
        spec.freq = 48000
        spec.samples = 1024
        
        audioDeviceID = SDL_OpenAudioDevice(nil, 0, &spec, nil, 0)
        SDL_PauseAudioDevice(audioDeviceID, 0)
    }
    
    func configureMetal() {
        guard let game = game as? GrapeManager.Library.Game, let device else {
            return
        }
        
        let isGBA = game.gameType == .gba
        let upscalingFilter = grape.useUpscalingFilter()
        let upscalingFactor = Int(grape.useUpscalingFactor())
        
        var width = isGBA ? 240 : 256
        var height = isGBA ? 160 : 192
        
        if [0, 1, 2].contains(upscalingFilter) {
            width *= upscalingFactor
            height *= upscalingFactor
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        primaryTexture = device.makeTexture(descriptor: textureDescriptor)
        secondaryTexture = device.makeTexture(descriptor: textureDescriptor)
        
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return
        }
        
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
        
        pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        commandQueue = device.makeCommandQueue()
    }
    
    override func draw(in view: MTKView) {
        guard let game = game as? GrapeManager.Library.Game, let device, let primaryScreen = primaryScreen as? MTKView else {
            return
        }
        
        func draw(_ texture: MTLTexture, _ view: MTKView, _ videoBuffer: UnsafeMutablePointer<UInt32>, _ width: Int, _ height: Int) {
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Failed to create pipeline state: \(error)")
            }
            
            func update(_ texture: MTLTexture, _ data: UnsafeMutablePointer<UInt32>, _ width: Int, _ height: Int) {
                texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: data,
                    bytesPerRow: width * MemoryLayout<UInt32>.stride)
            }
            
            update(texture, videoBuffer, width, height)
            
            // func updateUpscaled(_ data: UnsafeMutablePointer<UInt32>, _ width: Int, _ height: Int) {
            //     let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            //     textureDescriptor.usage = [.renderTarget, .shaderRead]
            //     textureDescriptor.storageMode = .private
            //     upscaledTexture = device.makeTexture(descriptor: textureDescriptor)
            // }
            
            guard let drawable = view.currentDrawable, let commandBuffer = commandQueue.makeCommandBuffer(),
                let renderPassDescriptor = view.currentRenderPassDescriptor else {
                return
            }
            
            // if MTLFXSpatialScalerDescriptor.supportsDevice(device) {
            //     updateUpscaled(videoBuffer, width, height)
            //
            //     let spatialDescriptor = MTLFXSpatialScalerDescriptor()
            //     spatialDescriptor.inputWidth = width
            //     spatialDescriptor.inputHeight = height
            //     spatialDescriptor.outputWidth = width
            //     spatialDescriptor.outputHeight = height
            //     spatialDescriptor.colorTextureFormat = .rgba8Unorm
            //     spatialDescriptor.outputTextureFormat = .rgba8Unorm
            //
            //     guard let scaler = spatialDescriptor.makeSpatialScaler(device: device) else {
            //         return
            //     }
            //
            //     scaler.colorTexture = texture
            //     scaler.outputTexture = upscaledTexture
            //
            //
            //     scaler.encode(commandBuffer: commandBuffer)
            // }
            
            guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            renderCommandEncoder.setRenderPipelineState(pipelineState)
            renderCommandEncoder.setFragmentTexture(texture, index: 0)
            // renderCommandEncoder.setFragmentTexture(upscaledTexture, index: 0)
            renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderCommandEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        let isGBA = game.gameType == .gba
        let upscalingFilter = grape.useUpscalingFilter()
        let upscalingFactor = Int(grape.useUpscalingFactor())
        
        var width = isGBA ? 240 : 256
        var height = isGBA ? 160 : 192
        
        if [0, 1, 2].contains(upscalingFilter) {
            width *= upscalingFactor
            height *= upscalingFactor
        }
        
        let videoBuffer = grape.videoBuffer(isGBA: isGBA)
        
        draw(primaryTexture, primaryScreen, videoBuffer, width, height)
        
        if !isGBA {
            guard let secondaryScreen = secondaryScreen as? MTKView else {
                return
            }
            
            let videoBuffer = videoBuffer.advanced(by: width * height)
            
            draw(secondaryTexture, secondaryScreen, videoBuffer, width, height)
        }
    }
}
