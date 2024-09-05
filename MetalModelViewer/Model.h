//
//  Model.h
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/5/24.
//

#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import "Common.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ModelType) {
    ModelTypeGround,
    ModelTypeLowpolyHouse,
    ModelTypePancakes,
    ModelTypeTVRetro
};

@interface Model : NSObject {
@public simd::float3 _position;
@public simd::float3 _rotation;
@public float _scale;
}
@property (assign, nonatomic) ModelType type;
@property (assign, nonatomic) uint tiling;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(ModelType)type device:(id<MTLDevice>)device vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor;
- (void)renderInEncoder:(id<MTLRenderCommandEncoder>)encoder uniforms:(Uniforms)uniforms params:(Params)params;
@end

NS_ASSUME_NONNULL_END
