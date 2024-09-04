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
    UniformsBuffer = 11
};

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

#endif /* Common_h */
