#include "Noise.h"

#include "../../../../Oss/SimplexNoise.h"

namespace ForiverEngine
{
	float Noise::Simplex1D(float x)
	{
		return SimplexNoise::noise(x);
	}

	float Noise::Simplex2D(float x, float y)
	{
		return SimplexNoise::noise(x, y);
	}

	float Noise::Simplex3D(float x, float y, float z)
	{
		return SimplexNoise::noise(x, y, z);
	}
}
