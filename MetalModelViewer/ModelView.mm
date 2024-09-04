//
//  ModelView.m
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ModelView.h"
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import "Common.h"

// early_fragment_tests 써보기

@interface ModelView ()
@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (retain, nonatomic, readonly) id<MTLDevice> device;
@property (retain, nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (retain, nonatomic, readonly) id<MTLRenderPipelineState> renderPipelineState;
@end

@implementation ModelView

+ (Class)layerClass {
    return CAMetalLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CAMetalLayer *metalLayer = self.metalLayer;
        id<MTLDevice> device = metalLayer.preferredDevice;
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        NSError * _Nullable error = nil;
        
        //
        
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatRGBA16Float;
        metalLayer.wantsExtendedDynamicRangeContent = YES;
        
        //
        
        
        
        //
        
        _device = [device retain];
        _commandQueue = [commandQueue retain];
        
        [library release];
        [commandQueue release];
    }
    
    return self;
}

- (void)dealloc {
    [_device release];
    [_commandQueue release];
    [_renderPipelineState release];
    [super dealloc];
}

- (CAMetalLayer *)metalLayer {
    return static_cast<CAMetalLayer *>(self.layer);
}

- (MDLVertexDescriptor *)vertexDescriptor {
    MDLVertexDescriptor *vertexDescriptor = [MDLVertexDescriptor new];
    
    NSUInteger offset = 0;
    
    //
    
    MDLVertexAttribute *positionVertexAttribute = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:offset bufferIndex:static_cast<NSUInteger>(Layout::VertexBuffer)];
    vertexDescriptor.attributes[static_cast<NSInteger>(Attribute::Position)] = positionVertexAttribute;
    [positionVertexAttribute release];
    
    offset += sizeof(simd_float3);
    
    //
    
    MDLVertexAttribute *normalVertexAttribute = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal format:MDLVertexFormatFloat3 offset:offset bufferIndex:static_cast<NSUInteger>(Layout::VertexBuffer)];
    vertexDescriptor.attributes[static_cast<NSInteger>(Attribute::Normal)] = normalVertexAttribute;
    [normalVertexAttribute release];
    
    offset += sizeof(simd_float3);
    
    //
    
    MDLVertexBufferLayout *vertexBufferLayout = [[MDLVertexBufferLayout alloc] initWithStride:offset];
    vertexDescriptor.layouts[static_cast<NSInteger>(Layout::VertexBuffer)] = vertexBufferLayout;
    [vertexBufferLayout release];
    
    offset = 0;
    
    //
    
    // UV는 Texture가 놓일 위치를 말한다.
    MDLVertexAttribute *uvVertexAttribute = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTextureCoordinate format:MDLVertexFormatFloat2 offset:offset bufferIndex:static_cast<NSUInteger>(Layout::UVBuffer)];
    vertexDescriptor.attributes[static_cast<NSInteger>(Layout::UVBuffer)] = uvVertexAttribute;
    [uvVertexAttribute release];
    
    offset += sizeof(simd_float2);
    
    MDLVertexBufferLayout *uvBufferLayout = [[MDLVertexBufferLayout alloc] initWithStride:offset];
    vertexDescriptor.layouts[static_cast<NSInteger>(Layout::UVBuffer)] = uvBufferLayout;
    [uvBufferLayout release];
    
    //
    
    return [vertexDescriptor autorelease];
}

@end
