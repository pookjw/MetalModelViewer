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
        float4 position [[attribute(static_cast<uint>(Attribute::Position))]];
        float3 normal [[attribute(static_cast<uint>(Attribute::Normal))]];
        float2 uv [[attribute(static_cast<uint>(Attribute::UV))]];
    };
    
    struct VertexOut {
        float4 position [[position]];
        float3 normal;
        float2 uv;
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                 constant Uniforms &uniforms [[buffer(static_cast<uint>(BufferIndex::UniformsBuffer))]]) {
        float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
        
        VertexOut out = {
            .position = position,
            .normal = in.normal,
            .uv = in.uv
        };
        
        return out;
    }
    
    [[early_fragment_tests]] // 알파 블랜딩에서 문제될 수 있음
    fragment float4 fragment_main(VertexOut in [[stage_in]],
                                  constant Params &params [[buffer(static_cast<uint>(BufferIndex::ParamsBuffer))]],
                                  texture2d<float> baseColorTexture [[texture(static_cast<uint>(TextureIndices::BaseColor))]]) {
        constexpr sampler textureSampler(filter::nearest,
                                         address::mirrored_repeat,
                                         mip_filter::nearest,
                                         max_anisotropy(8));
        
        float3 baseColor = baseColorTexture.sample(textureSampler, in.uv * params.tiling).rgb;
        
        return float4(baseColor, 1.f);
//        return float4(0.f, 1.f, 1.f, 1.f);
    }
}
