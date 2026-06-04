#import "NoiseBridge.h"

#include "../CppWrapper/Noise.h"

float FE_Noise_Simplex1D(float x)
{
    return ForiverEngine::Noise::Simplex1D(x);
}

float FE_Noise_Simplex2D(float x, float y)
{
    return ForiverEngine::Noise::Simplex2D(x, y);
}

float FE_Noise_Simplex3D(float x, float y, float z)
{
    return ForiverEngine::Noise::Simplex3D(x, y, z);
}
