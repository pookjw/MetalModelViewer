//
//  MathLibrary.hpp
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/5/24.
//

#import <simd/simd.h>
#import <CoreGraphics/CoreGraphics.h>

namespace MathLibrary {
std::float_t degreeFromRadians(std::float_t radians);
std::float_t radiansFromDegrees(std::float_t degrees);
simd::float4x4 float4x4FromFloat3Translation(simd::float3 translation);
simd::float4x4 float4x4FromFloat3Scale(simd::float3 scale);
simd::float4x4 float4x4FromScale(std::float_t scale);
simd::float4x4 float4x4FromRotationXAngle(std::float_t xAngle);
simd::float4x4 float4x4FromRotationYAngle(std::float_t yAngle);
simd::float4x4 float4x4FromRotationZAngle(std::float_t zAngle);
simd::float4x4 float4x4FromRotationXYZAngle(simd::float3 angle);
simd::float4x4 float4x4FromRotationYXZAngle(simd::float3 angle);
simd::float3x3 upperLeftFloat3x3FromFloat4x4(simd::float4x4 matrix);
simd::float4x4 projectionFloat4x4(std::float_t fov, std::float_t near, std::float_t far, std::float_t aspect, bool lhs = true);
simd::float4x4 float4x4FromEye(std::float_t eye, simd::float3 center, simd::float3 up);
simd::float4x4 float4x4FromOrthographicRect(CGRect rect, std::float_t near, std::float_t far);
simd::float4x4 float4x4FromDouble4x4(simd::double4x4 matrix);
simd::float4 float4FromDouble4(simd::double4 matrix);
simd::float3x3 float3x3FromNormalFloat4x4(simd::float4x4 matrix);
}
