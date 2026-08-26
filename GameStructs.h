#pragma once
#include <cstdint>
#include <cmath>

struct FVector {
    float X, Y, Z;

    FVector() : X(0.0f), Y(0.0f), Z(0.0f) {}
    FVector(float x, float y, float z) : X(x), Y(y), Z(z) {}

    inline float Distance(const FVector& v) const {
        float dx = X - v.X;
        float dy = Y - v.Y;
        float dz = Z - v.Z;
        return sqrtf(dx * dx + dy * dy + dz * dz);
    }

    inline float Length() const {
        return sqrtf(X * X + Y * Y + Z * Z);
    }

    FVector operator-(const FVector& v) const {
        return FVector(X - v.X, Y - v.Y, Z - v.Z);
    }
};

struct FVector2D {
    float X, Y;

    FVector2D() : X(0.0f), Y(0.0f) {}
    FVector2D(float x, float y) : X(x), Y(y) {}
};

struct FRotator {
    float Pitch, Yaw, Roll;

    FRotator() : Pitch(0.0f), Yaw(0.0f), Roll(0.0f) {}
    FRotator(float p, float y, float r) : Pitch(p), Yaw(y), Roll(r) {}
};

struct FMinimalViewInfo {
    FVector Location;      // 0x00
    FRotator Rotation;     // 0x0C
    float FOV;             // 0x18
};