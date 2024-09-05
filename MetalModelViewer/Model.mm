//
//  Model.m
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/5/24.
//

#import "Model.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "MathLibrary.hpp"

@interface Model ()
@property (retain, readonly, nonatomic) NSArray<MTKMesh *> *meshes;
@end

@implementation Model

- (instancetype)initWithType:(ModelType)type device:(id<MTLDevice>)device vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor {
    if (self = [super init]) {
        _scale = 1.f;
        
        if (type == ModelTypeGround) {
            MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
            
            MDLMesh *mdlMesh = [[MDLMesh alloc] initPlaneWithExtent:simd::make_float3(1.f, 1.f, 1.f)
                                                           segments:simd::make_uint2(1, 1)
                                                       geometryType:MDLGeometryTypeTriangles
                                                          allocator:allocator];
            [allocator release];
            
            mdlMesh.vertexDescriptor = vertexDescriptor;
            
            NSError * _Nullable error = nil;
            MTKMesh *mtkMesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:device error:&error];
            [mdlMesh release];
            assert(error == nil);
            
            _meshes = [[NSArray alloc] initWithObjects:mtkMesh, nil];
            [mtkMesh release];
            
            _tiling = 16;
        } else {
            NSString *name;
            switch (type) {
                case ModelTypeLowpolyHouse:
                    name = @"lowpoly-house";
                    break;
                case ModelTypePancakes:
                    name = @"pancakes";
                    break;
                case ModelTypeTVRetro:
                    name = @"tv_retro";
                    break;
                default:
                    abort();
            }
            
            NSURL *url = [NSBundle.mainBundle URLForResource:name withExtension:UTTypeUSDZ.preferredFilenameExtension];
            
            assert(url != nil);
            assert([NSFileManager.defaultManager fileExistsAtPath:url.path]);
            
            MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
            
            NSError * _Nullable error = nil;
            
            MDLAsset *asset = [[MDLAsset alloc] initWithURL:url
                                           vertexDescriptor:vertexDescriptor
                                            bufferAllocator:allocator
                                           preserveTopology:NO
                                                      error:&error];
            
            [allocator release];
            assert(error == nil);
            
            NSArray<MTKMesh *> *meshes = [MTKMesh newMeshesFromAsset:asset device:device sourceMeshes:NULL error:&error];
            _meshes = [meshes retain];
            [meshes release];
            
            _tiling = 1;
        }
    }
    
    return self;
}

- (void)dealloc {
    [_meshes release];
    [super dealloc];
}

- (void)renderInEncoder:(id<MTLRenderCommandEncoder>)encoder uniforms:(Uniforms)uniforms params:(Params)params {
    uniforms.modelMatrix = [self modelMatrix];
    params.tiling = _tiling;
    
    [encoder setTriangleFillMode:MTLTriangleFillModeFill];
    [encoder setVertexBytes:&uniforms length:sizeof(Uniforms) atIndex:static_cast<NSUInteger>(BufferIndex::UniformsBuffer)];
    [encoder setFragmentBytes:&params length:sizeof(Params) atIndex:static_cast<NSUInteger>(BufferIndex::ParamsBuffer)];
    
    for (MTKMesh *mesh in self.meshes) {
//        [encoder setVertexBuffers:<#(id<MTLBuffer>  _Nullable const * _Nonnull)#> offsets:<#(const NSUInteger * _Nonnull)#> withRange:<#(NSRange)#>]
        [mesh.vertexBuffers enumerateObjectsUsingBlock:^(MTKMeshBuffer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [encoder setVertexBuffer:obj.buffer offset:0 atIndex:idx];
        }];
        
        for (MTKSubmesh *submesh in mesh.submeshes) {
//            [encoder setFragmentTexture:<#(nullable id<MTLTexture>)#> atIndex:<#(NSUInteger)#>]
            [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                indexCount:submesh.indexCount
                                 indexType:submesh.indexType
                               indexBuffer:[submesh.indexBuffer buffer]
                         indexBufferOffset:submesh.indexBuffer.offset];
        }
    }
}

- (simd::float4x4)modelMatrix {
    simd::float4x4 translation = MathLibrary::float4x4FromFloat3Translation(_position);
    simd::float4x4 rotation = MathLibrary::float4x4FromRotationXYZAngle(_rotation);
    simd::float4x4 scale = MathLibrary::float4x4FromScale(_scale);
    
    return translation * (rotation * scale);
}

@end
