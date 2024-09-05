//
//  MathLibrary.cpp
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/5/24.
//

#include "MathLibrary.hpp"
#include <numbers>

std::float_t MathLibrary::degreeFromRadians(std::float_t radians) {
    return radians * 180.f / std::numbers::pi_v<std::float_t>;
}

std::float_t MathLibrary::radiansFromDegrees(std::float_t degrees) {
    return degrees * std::numbers::pi_v<std::float_t> / 180.f;
}

simd::float4x4 MathLibrary::float4x4FromFloat3Translation(simd::float3 translation) {
    simd::float4x4 matrix (simd::make_float4(1.f, 0.f, 0.f, 0.f),
                           simd::make_float4(0.f, 1.f, 0.f, 0.f),
                           simd::make_float4(0.f, 0.f, 1.f, 0.f),
                           simd::make_float4(translation, 1.f));
    
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromFloat3Scale(simd::float3 scale) {
    simd::float4x4 matrix (simd::make_float4(scale.x, 0.f, 0.f, 0.f),
                           simd::make_float4(0.f, scale.y, 0.f, 0.f),
                           simd::make_float4(0.f, 0.f, scale.z, 0.f),
                           simd::make_float4(0.f, 0.f, 0.f, 1.f));
    
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromScale(std::float_t scale) {
    simd::float4x4 matrix = matrix_identity_float4x4;
    matrix.columns[3].w = (1.f / scale);
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromRotationXAngle(std::float_t xAngle) {
    simd::float4x4 matrix (simd::make_float4(1.f, 0.f, 0.f, 0.f),
                           simd::make_float4(0.f, std::cos(xAngle), std::sin(xAngle), 0.f),
                           simd::make_float4(0.f, -std::sin(xAngle), std::cos(xAngle), 0.f),
                           simd::make_float4(0.f, 0.f, 0.f, 1.f));
    
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromRotationYAngle(std::float_t yAngle) {
    simd::float4x4 matrix (simd::make_float4(std::cos(yAngle), 0.f, -std::sin(yAngle), 0.f),
                           simd::make_float4(0.f, 1.f, 0.f, 0.f),
                           simd::make_float4(std::sin(yAngle), 0.f, std::cos(yAngle), 0.f),
                           simd::make_float4(0.f, 0.f, 0.f, 1.f));
    
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromRotationZAngle(std::float_t zAngle) {
    simd::float4x4 matrix (simd::make_float4(std::cos(zAngle), std::sin(zAngle), 0.f, 0.f),
                           simd::make_float4(-std::sin(zAngle), std::cos(zAngle), 0.f, 0.f),
                           simd::make_float4(0.f, 0.f, 1.f, 0.f),
                           simd::make_float4(0.f, 0.f, 0.f, 1.f));
    
    return matrix;
}

simd::float4x4 MathLibrary::float4x4FromRotationXYZAngle(simd::float3 angle) {
    simd::float4x4 rotationX = MathLibrary::float4x4FromRotationXAngle(angle.x);
    simd::float4x4 rotationY = MathLibrary::float4x4FromRotationYAngle(angle.y);
    simd::float4x4 rotationZ = MathLibrary::float4x4FromRotationZAngle(angle.z);
    
    return rotationX * rotationY * rotationZ;
}


simd::float4x4 MathLibrary::float4x4FromRotationYXZAngle(simd::float3 angle) {
    simd::float4x4 rotationX = MathLibrary::float4x4FromRotationXAngle(angle.x);
    simd::float4x4 rotationY = MathLibrary::float4x4FromRotationYAngle(angle.y);
    simd::float4x4 rotationZ = MathLibrary::float4x4FromRotationZAngle(angle.z);
    
    return rotationY * rotationX * rotationZ;
}

simd::float3x3 MathLibrary::upperLeftFloat3x3FromFloat4x4(simd::float4x4 matrix) {
    simd::float3x3 result (matrix.columns[0].xyz,
                           matrix.columns[1].xyz,
                           matrix.columns[2].xyz);
    
    return result;
}

simd::float4x4 MathLibrary::projectionFloat4x4(std::float_t fov, std::float_t near, std::float_t far, std::float_t aspect, bool lhs) {
    std::float_t y = 1.f / std::tan(fov * 0.5f);
    std::float_t x = y / aspect;
    std::float_t z = lhs ? (far / (far - near)) : (far / (near - far));
    
    simd::float4x4 result (simd::make_float4(x, 0.f, 0.f, 0.f),
                           simd::make_float4(0.f, y, 0.f, 0.f),
                           simd::make_float4(0.f, 0.f, z, lhs ? 1.f : -1.f),
                           simd::make_float4(0.f, 0.f, z * near * (lhs ? -1.f : 1.f), 0.f));
    
    return result;
}

simd::float4x4 MathLibrary::float4x4FromEye(std::float_t eye, simd::float3 center, simd::float3 up) {
    simd::float3 z = simd::normalize(center - eye);
    simd::float3 x = simd::normalize(simd::cross(up, z));
    simd::float3 y = simd::cross(z, x);
    
    simd::float4x4 result (simd::make_float4(x.x, y.x, z.x, 0.f),
                           simd::make_float4(x.y, y.y, z.y, 0.f),
                           simd::make_float4(x.z, y.z, z.z, 0.f),
                           simd::make_float4(-simd::dot(x, eye), -simd::dot(y, eye), -simd::dot(z, eye), 1.f));
    
    return result;
}

simd::float4x4 MathLibrary::float4x4FromOrthographicRect(CGRect rect, std::float_t near, std::float_t far) {
    std::float_t left = CGRectGetMinX(rect);
    std::float_t right = CGRectGetMaxX(rect);
    std::float_t top = CGRectGetMinY(rect);
    std::float_t bottom = CGRectGetMaxY(rect);
    
    simd::float4x4 result (simd::make_float4(2.f / (right - left), 0.f, 0.f, 0.f),
                           simd::make_float4(0.f, 2.f / (top - bottom), 0.f, 0.f),
                           simd::make_float4(0.f, 0.f, 1.f / (far - near), 0.f),
                           simd::make_float4((left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1.f));
    
    return result;
}

simd::float4x4 MathLibrary::float4x4FromDouble4x4(simd::double4x4 matrix) {
    simd::float4x4 result (simd::make_float4(matrix.columns[0].x, matrix.columns[0].y, matrix.columns[0].z, matrix.columns[0].w),
                           simd::make_float4(matrix.columns[1].x, matrix.columns[1].y, matrix.columns[1].z, matrix.columns[1].w),
                           simd::make_float4(matrix.columns[2].x, matrix.columns[2].y, matrix.columns[2].z, matrix.columns[2].w),
                           simd::make_float4(matrix.columns[3].x, matrix.columns[3].y, matrix.columns[3].z, matrix.columns[3].w));
    
    return result;
}

simd::float4 MathLibrary::float4FromDouble4(simd::double4 matrix) {
    simd::float4 result = simd::make_float4(matrix.x, matrix.y, matrix.z, matrix.z);
    return result;
}

simd::float3x3 MathLibrary::float3x3FromNormalFloat4x4(simd::float4x4 matrix) {
    return simd::transpose(simd::inverse(MathLibrary::upperLeftFloat3x3FromFloat4x4(matrix)));
}
