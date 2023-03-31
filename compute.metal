//
//  compute.metal
//  UIKitMadness
//
//  Created by Bogdan Petru on 31.03.2023.
//

#include <metal_stdlib>
using namespace metal;
kernel void add_two_values(constant float *inputsA [[buffer(0)]],
                           constant float *inputsB [[buffer(1)]],
                           device float *outputs [[buffer(2)]],
                           uint index [[thread_position_in_grid]])
{
    outputs[index] = inputsA[index]+inputsB[index];
}
