//
//  ViewController.swift
//  UIKitMadness
//
//  Created by Bogdan Petru on 08.03.2023.
//

import UIKit
import Metal
import Combine

class ViewController: UIViewController {

    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var vertexBuffer: MTLBuffer!
    let vertexData: [Float] = [
        0.0,0.5,0.0,
        0.0,0.0,0.0,
        0.5,0.0,0.0,
        0.5,0.0,0.0,
        0.5,0.5,0.0,
        0.0,0.5,0.0
        
    ]
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    
    var timer: CADisplayLink!
    var shouldRedrawFlag: Bool = true
    var tickTimer : HPETimer = HPETimer()
    
    
    func normalize() -> Double
    {
        return 0.0
    }
    func render()
    {
        if !shouldRedrawFlag{
            return
        }
        guard let drawable = metalLayer?.nextDrawable() else {return}
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red:0.0,
            green: 128/256,
            blue:128/256,
            alpha:1.0
        )
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        
        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3,instanceCount: 1)
        renderEncoder.drawPrimitives(type:.triangle, vertexStart: 3, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        shouldRedrawFlag = false
        
    }

    @objc func gameloop()
    {
        autoreleasepool()
        {
            print("\(round(1 / (timer.targetTimestamp - timer.timestamp))) FPS")
            self.render()
            
        }
    }
    func executeOnTick()
    {
        print("Tick")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData)
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize,options: [])
        
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment");
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex");
        
        let pipelineStateDescriptior = MTLRenderPipelineDescriptor()
        
        pipelineStateDescriptior.vertexFunction = vertexProgram
        pipelineStateDescriptior.fragmentFunction = fragmentProgram
        pipelineStateDescriptior.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptior)
        
        commandQueue = device.makeCommandQueue()
        
        
        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)
        tickTimer.setCallback {
            self.executeOnTick()
        }
        tickTimer.start()

    }
}

