#pragma once

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

float FE_Noise_Simplex1D(float x);
float FE_Noise_Simplex2D(float x, float y);
float FE_Noise_Simplex3D(float x, float y, float z);

#ifdef __cplusplus
}
#endif
