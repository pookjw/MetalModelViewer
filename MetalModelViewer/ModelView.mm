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
#include "MathLibrary.hpp"

// early_fragment_tests 써보기

@interface ModelView ()
@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (retain, nonatomic, readonly) id<MTLDevice> device;
@property (retain, nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (retain, nonatomic, readonly) id<MTLRenderPipelineState> renderPipelineState;
@property (retain, nonatomic, readonly) id<MTLDepthStencilState> depthStencilState;
@property (retain, nonatomic, readonly) Model *groundModel;
@property (assign, nonatomic) float timer;
@property (assign, nonatomic) Uniforms uniforms;
@property (assign, nonatomic) Params params;
@property (retain, nonatomic, readonly) UIUpdateLink *updateLink;
@property (retain, nonatomic, readonly) NSMutableSet<Model *> *models;
@property (nonatomic, readonly, nullable) Model *model;
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
        
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"model_viewer::vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"model_viewer::fragment_main"];
        [library release];
        
        //
        
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        [vertexFunction release];
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        [fragmentFunction release];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIOWithError([self vertexDescriptor], &error);
        assert(error == nil);
        renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        
        id<MTLRenderPipelineState> renderpipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        [renderPipelineDescriptor release];
        assert(error == nil);
        
        //
        
        MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDescriptor.depthWriteEnabled = YES;
        
        id<MTLDepthStencilState> depthStencilState = [device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        [depthStencilDescriptor release];
        
        //
        
        Model *groundModel = [[Model alloc] initWithType:ModelTypeGround device:device vertexDescriptor:[self vertexDescriptor]];
        groundModel.tiling = 16;
        
        //
        
        UIUpdateLink *updateLink = [UIUpdateLink updateLinkForView:self actionTarget:self selector:@selector(didTriggerUpdateLink:)];
        updateLink.requiresContinuousUpdates = YES;
        updateLink.wantsLowLatencyEventDispatch = YES;
        updateLink.preferredFrameRateRange = CAFrameRateRangeMake(0.f, 30.f, 30.f);
        updateLink.enabled = YES;
        
        //
        
        _device = [device retain];
        _commandQueue = [commandQueue retain];
        _renderPipelineState = [renderpipelineState retain];
        _depthStencilState = [depthStencilState retain];
        _groundModel = [groundModel retain];
        _uniforms.viewMatrix = simd::inverse(MathLibrary::float4x4FromFloat3Translation(simd::make_float3(0.f, 1.f, -4.f)));
        _updateLink = [updateLink retain];
        _models = [NSMutableSet new];
        
        [commandQueue release];
        [renderpipelineState release];
        [depthStencilState release];
        [groundModel release];
        
        //
        
//        self.modelType = ModelTypePancakes;
        self.modelType = ModelTypeLowpolyHouse;
    }
    
    return self;
}

- (void)dealloc {
    [_device release];
    [_commandQueue release];
    [_renderPipelineState release];
    [_depthStencilState release];
    [_groundModel release];
    [_models release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    std::float_t aspect = size.width / size.height;
    
    _uniforms.projectionMatrix = MathLibrary::projectionFloat4x4(MathLibrary::radiansFromDegrees(70.f),
                                                                 0.1f,
                                                                 100.f,
                                                                 aspect);
    
    _params.width = size.width;
    _params.height = size.height;
    
//    [self draw];
}

- (CAMetalLayer *)metalLayer {
    return static_cast<CAMetalLayer *>(self.layer);
}

- (void)setModelType:(ModelType)modelType {
    _modelType = modelType;
    
    //
    
    for (Model *model in self.models) {
        if (model.type == self.modelType) {
            return;
        }
    }
    
    Model *model = [[Model alloc] initWithType:modelType device:_device vertexDescriptor:[self vertexDescriptor]];
    [self.models addObject:model];
    [model release];
}

- (Model *)model {
    for (Model *model in self.models) {
        if (model.type == self.modelType) {
            return model;
        }
    }
    
    return nil;
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
    vertexDescriptor.attributes[static_cast<NSInteger>(Attribute::UV)] = uvVertexAttribute;
    [uvVertexAttribute release];
    
    offset += sizeof(simd_float2);
    
    MDLVertexBufferLayout *uvBufferLayout = [[MDLVertexBufferLayout alloc] initWithStride:offset];
    vertexDescriptor.layouts[static_cast<NSInteger>(Layout::UVBuffer)] = uvBufferLayout;
    [uvBufferLayout release];
    
    //
    
    return [vertexDescriptor autorelease];
}

- (void)didTriggerUpdateLink:(UIUpdateLink *)sender {
    [self draw];
}

- (void)draw {
    CAMetalLayer *metalLayer = self.metalLayer;
    
    if (CGRectEqualToRect(metalLayer.frame, CGRectNull)) return;
    if (CGRectEqualToRect(metalLayer.frame, CGRectZero)) return;
    
    metalLayer.drawableSize = metalLayer.bounds.size;
    
    id<CAMetalDrawable> _Nullable drawable = [metalLayer nextDrawable];
    if (drawable == nil) return;
    
    MTLRenderPassColorAttachmentDescriptor *colorAttachmentDescriptor = [MTLRenderPassColorAttachmentDescriptor new];
    colorAttachmentDescriptor.texture = drawable.texture;
    colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.f, 1.f, 0.8f, 1.f);
    colorAttachmentDescriptor.loadAction = MTLLoadActionClear;
    colorAttachmentDescriptor.storeAction = MTLStoreActionStore;
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor;
    [colorAttachmentDescriptor release];
    renderPassDescriptor.renderTargetWidth = CGRectGetWidth(metalLayer.bounds);
    renderPassDescriptor.renderTargetHeight = CGRectGetHeight(metalLayer.bounds);
    
    // TODO
    CGSize drawableSize = metalLayer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                          width:drawableSize.width
                                                                                         height:drawableSize.height
                                                                                      mipmapped:NO];
    descriptor.usage = MTLTextureUsageRenderTarget;
    descriptor.storageMode = MTLStorageModePrivate;
    id<MTLTexture> depthTexture = [_device newTextureWithDescriptor:descriptor];
    renderPassDescriptor.depthAttachment.texture = depthTexture;
    [depthTexture release];
    
    //
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderPassDescriptor release];
    
    [renderCommandEncoder setRenderPipelineState:_renderPipelineState];
    [renderCommandEncoder setDepthStencilState:_depthStencilState];
    
    //
    
//    _timer += 0.005f;

    //
    
    Model *selectedModel = self.model;
    selectedModel->_rotation.x = std::sin(_timer);
    [selectedModel renderInEncoder:renderCommandEncoder uniforms:_uniforms params:_params];
    
    //
    
    _groundModel->_scale = 40.f;
    _groundModel->_rotation.z = MathLibrary::radiansFromDegrees(90.f);
    _groundModel->_rotation.y = std::sin(_timer);
    
//    [_groundModel renderInEncoder:renderCommandEncoder uniforms:_uniforms params:_params];
    
    //
    
    [renderCommandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
