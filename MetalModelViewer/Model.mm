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
@property (retain, readonly, nonatomic) NSArray<MTKMesh *> *mtkMeshes;
@property (retain, readonly, nonatomic) NSArray<MDLMesh *> *mdlMeshes;
@property (retain, readonly, nonatomic, nullable) NSDictionary<NSString *, id<MTLTexture>> *texturesByStringValue;
@end

@implementation Model

- (instancetype)initWithType:(ModelType)type device:(id<MTLDevice>)device vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor {
    if (self = [super init]) {
        _scale = 1.f;
        _tiling = 1;
        _type = type;
        
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
            assert(error == nil);
            
            _mtkMeshes = [[NSArray alloc] initWithObjects:mtkMesh, nil];
            _mdlMeshes = [[NSArray alloc] initWithObjects:mdlMesh, nil];
            [mtkMesh release];
            [mdlMesh release];
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
            
            [asset loadTextures];
            
            NSArray<MDLMesh *> *mdlMeshes;
            NSArray<MTKMesh *> *mtkMeshes = [MTKMesh newMeshesFromAsset:asset device:device sourceMeshes:&mdlMeshes error:&error];
            
            MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
            NSDictionary<MTKTextureLoaderOption, id> *textureLoaderOptions = @{
                MTKTextureLoaderOptionOrigin: MTKTextureLoaderOriginBottomLeft,
                MTKTextureLoaderOptionGenerateMipmaps: @YES
            };
            
            NSMutableDictionary<NSString *, id<MTLTexture>> *texturesByStringValue = [NSMutableDictionary new];
            [mtkMeshes enumerateObjectsUsingBlock:^(MTKMesh * _Nonnull mesh, NSUInteger idx, BOOL * _Nonnull stop) {
                MDLMesh *mdlMesh = mdlMeshes[idx];
                
                [mesh.submeshes enumerateObjectsUsingBlock:^(MTKSubmesh * _Nonnull submesh, NSUInteger idx, BOOL * _Nonnull stop) {
                    MDLSubmesh *mdlSubmesh = mdlMesh.submeshes[idx];
                    MDLMaterial *mdlMaterial = mdlSubmesh.material;
                    
                    MDLMaterialProperty * _Nullable property = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticBaseColor];
                    if (property == nil) return;
                    if (property.type != MDLMaterialPropertyTypeTexture) return;
                    
                    MDLTexture *mdlTexture = property.textureSamplerValue.texture;
                    NSError * _Nullable error = nil;
                    
                    id<MTLTexture> texture = [textureLoader newTextureWithMDLTexture:mdlTexture options:textureLoaderOptions error:&error];
                    assert(error == nil);
                    
                    texturesByStringValue[property.stringValue] = texture;
                    [texture release];
                }];
            }];
            
            [textureLoader release];
            
            _mtkMeshes = [mtkMeshes retain];
            _mdlMeshes = [mdlMeshes retain];
            _texturesByStringValue = [texturesByStringValue retain];
            [mtkMeshes release];
            [texturesByStringValue release];
        }
    }
    
    return self;
}

- (void)dealloc {
    [_mtkMeshes release];
    [_mdlMeshes release];
    [_texturesByStringValue release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else {
        auto casted = static_cast<Model *>(other);
        return _type == casted->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

- (void)renderInEncoder:(id<MTLRenderCommandEncoder>)encoder uniforms:(Uniforms)uniforms params:(Params)params {
    uniforms.modelMatrix = [self modelMatrix];
    params.tiling = _tiling;
    
    [encoder setTriangleFillMode:MTLTriangleFillModeFill];
    [encoder setVertexBytes:&uniforms length:sizeof(Uniforms) atIndex:static_cast<NSUInteger>(BufferIndex::UniformsBuffer)];
    [encoder setFragmentBytes:&params length:sizeof(Params) atIndex:static_cast<NSUInteger>(BufferIndex::ParamsBuffer)];
    
    [self.mtkMeshes enumerateObjectsUsingBlock:^(MTKMesh * _Nonnull mtkMesh, NSUInteger idx, BOOL * _Nonnull stop) {
        MDLMesh *mdlMesh = self.mdlMeshes[idx];
        
        //        [encoder setVertexBuffers:<#(id<MTLBuffer>  _Nullable const * _Nonnull)#> offsets:<#(const NSUInteger * _Nonnull)#> withRange:<#(NSRange)#>]
        [mtkMesh.vertexBuffers enumerateObjectsUsingBlock:^(MTKMeshBuffer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [encoder setVertexBuffer:obj.buffer offset:0 atIndex:idx];
        }];
        
        [mtkMesh.submeshes enumerateObjectsUsingBlock:^(MTKSubmesh * _Nonnull mtkSubmesh, NSUInteger idx, BOOL * _Nonnull stop) {
            MDLSubmesh *mdlSubmesh = mdlMesh.submeshes[idx];
            
            MDLMaterial *mdlMaterial = mdlSubmesh.material;
            
            MDLMaterialProperty * _Nullable property = [mdlMaterial propertyWithSemantic:MDLMaterialSemanticBaseColor];
            if (property != nil && property.type == MDLMaterialPropertyTypeTexture) {
                [encoder setFragmentTexture:self.texturesByStringValue[property.stringValue] atIndex:static_cast<NSUInteger>(TextureIndices::BaseColor)];
            }
            
            [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                indexCount:mtkSubmesh.indexCount
                                 indexType:mtkSubmesh.indexType
                               indexBuffer:[mtkSubmesh.indexBuffer buffer]
                         indexBufferOffset:mtkSubmesh.indexBuffer.offset];
        }];
    }];
}

- (simd::float4x4)modelMatrix {
    simd::float4x4 translation = MathLibrary::float4x4FromFloat3Translation(_position);
    simd::float4x4 rotation = MathLibrary::float4x4FromRotationXYZAngle(_rotation);
    simd::float4x4 scale = MathLibrary::float4x4FromScale(_scale);
    
    return translation * (rotation * scale);
}

@end
