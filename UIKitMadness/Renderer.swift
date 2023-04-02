//
//  Renderer.swift
//  UIKitMadness
//
//  Created by Bogdan Petru on 31.03.2023.
//

import Foundation
import MetalKit
class Renderer
{
    
    private var isInitialized = false
    private var device: MTLDevice!
    private var metalLayer: CAMetalLayer!
    private var vertexBuffer: MTLBuffer!
    let vertexData: [Float] = [
        //    x     y       r    g    b    a
            -0.8,  0.4,    1.0, 0.0, 1.0, 1.0,
             0.4, -0.8,    0.0, 1.0, 1.0, 1.0,
             0.8,  0.8,    1.0, 1.0, 0.0, 1.0,
    ]
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var shouldRedrawFlag: Bool = true
    private var timer: CADisplayLink!
    private var defaultLibrary: MTLLibrary!
    
    private func run_compute_task(from library : any MTLLibrary)
    {
        //incarcam programul shader din fisier
        let computeProgram = library.makeFunction(name: "add_two_values")!
    
        //pregatim pipeline-ul de executie
        let computePipeline = try! device.makeComputePipelineState(function: computeProgram)
        
        //cate 32 fire de executie pe 8 grupuri. 32*8=256 - pt 256 de numere
        let threadsPerThreadgroup = MTLSize(width: 32, height: 1, depth: 1)
        let threadgroupCount = MTLSize(width: 8, height: 1, depth: 1)
        
        //fie 256 elemente
        let elementCount = 256
        
        //creaza "vectori"(buffere) pe GPU
        let inputBufferA = device.makeBuffer(length: MemoryLayout<Float>.size*elementCount, options: .storageModeShared)!
        let inputBufferB = device.makeBuffer(length: MemoryLayout<Float>.size*elementCount, options: .storageModeShared)!
        let inputBufferC = device.makeBuffer(length: MemoryLayout<Float>.size*elementCount, options: .storageModeShared)!
        //deschide cutiile
        let inputsA = inputBufferA.contents().assumingMemoryBound(to: Float.self)
        let inputsB = inputBufferB.contents().assumingMemoryBound(to: Float.self)
        
        
        //pune valori in A si in B
        for i in 0..<elementCount{
            inputsA[i] = Float(i)
            inputsB[i] = Float(elementCount-i)
        }
        
        //creaza bufferul de comenzi pentru a fi trimis pe pipeline
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        //creaza codorul de comenzi
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        //leaga codorul de pipeline
        commandEncoder.setComputePipelineState(computePipeline)
        
        //incarcam datele la [[buffer(0)]], [[buffer(1)]] si [[buffer(2)]]
        commandEncoder.setBuffer(inputBufferA, offset: 0, index: 0)
        commandEncoder.setBuffer(inputBufferB, offset: 0, index: 1)
        commandEncoder.setBuffer(inputBufferC, offset: 0, index: 2)
        
        //trimite sarcina la GPU
        commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)
        
        //impachetam
        commandEncoder.endEncoding()
        
        //cand se termina, afiseaza pe ecran
        commandBuffer.addCompletedHandler{_ in
            let output = inputBufferC.contents().assumingMemoryBound(to: Float.self)
            for i in 0..<elementCount{
                print(output[i])
            }
        }
        //acum ruleaza
        commandBuffer.commit()
    }
    public func initialize(boundToSurface surface: CALayer)
    {
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = surface.frame
        surface.addSublayer(metalLayer)
        
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData)
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize,options: [])
        
        
        defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment");
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex");
        
        let pipelineStateDescriptior = MTLRenderPipelineDescriptor()
        
        pipelineStateDescriptior.vertexFunction = vertexProgram
        pipelineStateDescriptior.fragmentFunction = fragmentProgram
        pipelineStateDescriptior.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 6
        
        pipelineStateDescriptior.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptior)
        
        commandQueue = device.makeCommandQueue()
        isInitialized = true
    }
    public func start_compute()
    {
        if(!self.isInitialized){
            fatalError("Renderer is not initialized. Run Renderer.initialize(boundToSurface: CALayer)")}
        run_compute_task(from: defaultLibrary)
    }
    private func render()
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
        renderEncoder.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        //shouldRedrawFlag = false
        
    }
    @objc func gameloop()
    {
        autoreleasepool()
        {
            //print("\(round(1 / (timer.targetTimestamp - timer.timestamp))) FPS")
            self.render()
            
        }
    }
    public func start()
    {
        if(!self.isInitialized){
            fatalError("Renderer is not initialized. Run Renderer.initialize(boundToSurface: CALayer)")}
        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)
    }
}
