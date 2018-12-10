//
//  Simulator.swift
//  Segregation
//
//  Created by SHINGAI YOSHIMI on 2018/11/30.
//  Copyright © 2018 SHINGAI YOSHIMI. All rights reserved.
//

import Foundation
import MetalKit

struct Object {
    var group: UInt32 = 0
    var x: Float = 0
    var y: Float = 0
    var angle: Float = 0
}

class Simulator {
    private var objects:[Object] = []

    var device: MTLDevice? = MTLCreateSystemDefaultDevice()
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLComputePipelineState?
    var widthBuffer: MTLBuffer?
    var heightBuffer: MTLBuffer?

    init(size: CGSize, count: Int) {
        let defaultLibrary = device?.makeDefaultLibrary()
        guard let function = defaultLibrary?.makeFunction(name: "simulate") else {
            return
        }
        pipelineState = try! device?.makeComputePipelineState(function: function)
        commandQueue = device?.makeCommandQueue()
        
        var width = Float(size.width)
        var height = Float(size.height)
        widthBuffer = device?.makeBuffer(bytes: &width, length: MemoryLayout.size(ofValue: width), options: [])
        heightBuffer = device?.makeBuffer(bytes: &height, length: MemoryLayout.size(ofValue: height), options: [])
        
        [0,1].forEach{ group in
            for _ in 0..<count {
                generateObject(group: UInt32(group))
            }
        }
    }

    func execute() -> [Object] {
        guard let pipelineState = pipelineState,
            let outBuffer = device?.makeBuffer(bytes: objects, length: objects.byteLength, options: []) else {
                return objects
        }

        let commandBuffer = commandQueue?.makeCommandBuffer()

        let encoder = commandBuffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(pipelineState)

        let buffer = device?.makeBuffer(bytes: objects, length: objects.byteLength, options: [])
        var count = UInt32(objects.count)
        let countBuffer = device?.makeBuffer(bytes: &count, length: MemoryLayout.size(ofValue: count), options: [])

        encoder?.setBuffer(buffer, offset: 0, index: 0)
        encoder?.setBuffer(countBuffer, offset: 0, index: 1)
        encoder?.setBuffer(widthBuffer, offset: 0, index: 2)
        encoder?.setBuffer(heightBuffer, offset: 0, index: 3)
        encoder?.setBuffer(outBuffer, offset: 0, index: 4)

        let groupsize = MTLSize(width: 64, height: 1, depth: 1)
        let numgroups = MTLSize(width: (objects.count + groupsize.width - 1) / groupsize.width, height: 1, depth: 1)

        encoder?.dispatchThreadgroups(numgroups, threadsPerThreadgroup: groupsize)
        encoder?.endEncoding()

        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()

        let data = Data(bytesNoCopy: outBuffer.contents(), count: objects.byteLength, deallocator: .none)
        objects = data.withUnsafeBytes {
            [Object](UnsafeBufferPointer<Object>(start: $0, count: data.count/MemoryLayout<Object>.size))
        }

        return objects
    }
    
//    func execute() -> [Object] {
//        return objects.map { object in
//            let around = objects.filter{ other in
//                let w = object.x - other.x
//                let h = object.y - other.y
//                let dist = sqrtf(w*w + h*h)
//
//                return dist<20
//            }
//
//            let totalCount = around.count - 1 // subtract myself
//            let groupCount = around.filter{ $0.group == object.group }.count - 1 // subtract myself
//            if totalCount > 0 && Double(totalCount)*0.5 < Double(groupCount) {
//                return object
//            }
//
//            let translationX = sin(object.angle)
//            let translationY = cos(object.angle)
//
//            let size = UIScreen.main.bounds
//            var x = CGFloat(object.x + translationX)
//            x -= (x > size.width) ? size.width : 0
//            x += (x < 0) ? size.width : 0
//
//            var y = CGFloat(object.y + translationY)
//            y -= (x > size.height) ? size.height : 0
//            y += (x < 0) ? size.height : 0
//
//            return Object(group: object.group, x: Float(x), y: Float(y), angle: Float(object.angle))
//        }
//    }
}

private extension Simulator {
    func generateObject(group: UInt32) {
        let size = UIScreen.main.bounds
        
        let g = group
        let x = arc4random_uniform(UInt32(size.width))
        let y = arc4random_uniform(UInt32(size.height))
        let a = Double(arc4random_uniform(360)) * Double.pi/180
        
        let object = Object(group: g, x: Float(x), y: Float(y), angle: Float(a))
        objects.append(object)
    }
}

private extension Array {
    var byteLength: Int {
        return count * MemoryLayout<Element>.size
    }
}
