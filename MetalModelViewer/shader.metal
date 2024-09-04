//
//  shader.metal
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/5/24.
//

#include <metal_stdlib>
#import "Common.h"
using namespace metal;

namespace model_viewer {
    struct VertexIn {
        float4 position [[attribute(static_cast<int>(Attribute::Position))]];
        float3 normal [[attribute(static_cast<int>(Attribute::Normal))]];
        float2 uv [[attribute(static_cast<int>(Attribute::UV))]];
    };
    
    struct VertexOut {
        float4 position [[position]];
        float3 normal;
        float2 uv;
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                 constant Uniforms &uniforms [[buffer(static_cast<int>(BufferIndex::UniformsBuffer))]]) {
        return {};
    }
}
