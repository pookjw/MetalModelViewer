//
//  Common.h
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/4/24.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

enum class Attribute {
    Position = 0,
    Normal = 1,
    UV = 2
};

enum class Layout {
    VertexBuffer = 0,
    UVBuffer = 1
};

enum class BufferIndex {
    VertexBuffer = 0,
    UVBuffer = 1,
    UniformsBuffer = 11,
    ParamsBuffer = 12
};

typedef struct {
    simd::float4x4 modelMatrix;
    simd::float4x4 viewMatrix;
    simd::float4x4 projectionMatrix;
} Uniforms;

typedef struct {
    uint width, height;
    uint tiling;
} Params;

enum class TextureIndices {
    BaseColor = 0
};

#endif /* Common_h */
