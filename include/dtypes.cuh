// Boilerplate vector space over data type Pt. Needs members x, y, and z.
#pragma once

#include <type_traits>


template<typename Pt>
struct Is_vector : public std::false_type {};

// float3
__device__ __host__ float3 operator+=(float3& a, const float3& b)
{
    a.x += b.x;
    a.y += b.y;
    a.z += b.z;
    return a;
}

__device__ __host__ float3 operator*=(float3& a, const float b)
{
    a.x *= b;
    a.y *= b;
    a.z *= b;
    return a;
}

template<>
struct Is_vector<float3> : public std::true_type {};

// float4
__device__ __host__ float4 operator+=(float4& a, const float4& b)
{
    a.x += b.x;
    a.y += b.y;
    a.z += b.z;
    a.w += b.w;
    return a;
}

__device__ __host__ float4 operator*=(float4& a, const float b)
{
    a.x *= b;
    a.y *= b;
    a.z *= b;
    a.w *= b;
    return a;
}

template<>
struct Is_vector<float4> : public std::true_type {};


// MAKE_PT(Pt, ...) makes data type Pt with x, y, z, and __VA_ARGS__ as members
#define MEMBER(component) float component
#define COMP_WISE_ADD(component) a.component += b.component
#define COMP_WISE_MULTIPLY(component) a.component *= b

#define MAKE_PT(Pt, ...)                                               \
    struct Pt {                                                        \
        MAP(MEMBER, x, y, z, __VA_ARGS__)                              \
                                                                       \
        friend __device__ __host__ Pt operator+=(Pt& a, const Pt& b)   \
        {                                                              \
            MAP(COMP_WISE_ADD, x, y, z, __VA_ARGS__)                   \
            return a;                                                  \
        }                                                              \
        friend __device__ __host__ Pt operator*=(Pt& a, const float b) \
        {                                                              \
            MAP(COMP_WISE_MULTIPLY, x, y, z, __VA_ARGS__)              \
            return a;                                                  \
        }                                                              \
    };                                                                 \
                                                                       \
    template<>                                                         \
    struct Is_vector<Pt> : public std::true_type {}

// ... where MAP(MACRO, ...) maps MACRO onto __VA_ARGS__, inspired by
// http://stackoverflow.com/questions/11761703/
// clang-format off
#define _MAP0(MACRO, x) MACRO(x);
#define _MAP1(MACRO, x, ...) MACRO(x); _MAP0(MACRO, __VA_ARGS__)
#define _MAP2(MACRO, x, ...) MACRO(x); _MAP1(MACRO, __VA_ARGS__)
#define _MAP3(MACRO, x, ...) MACRO(x); _MAP2(MACRO, __VA_ARGS__)
#define _MAP4(MACRO, x, ...) MACRO(x); _MAP3(MACRO, __VA_ARGS__)
#define _MAP5(MACRO, x, ...) MACRO(x); _MAP4(MACRO, __VA_ARGS__)
#define _MAP6(MACRO, x, ...) MACRO(x); _MAP5(MACRO, __VA_ARGS__)
#define _MAP7(MACRO, x, ...) MACRO(x); _MAP6(MACRO, __VA_ARGS__)
#define _MAP8(MACRO, x, ...) MACRO(x); _MAP7(MACRO, __VA_ARGS__)
#define _MAP9(MACRO, x, ...) MACRO(x); _MAP8(MACRO, __VA_ARGS__)
// clang-format on

#define _GET_10th(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, ...) _10
#define MAP(MACRO, ...)                                                     \
    _GET_10th(__VA_ARGS__, _MAP9, _MAP8, _MAP7, _MAP6, _MAP5, _MAP4, _MAP3, \
        _MAP2, _MAP1, _MAP0)(MACRO, __VA_ARGS__)

// Polarized cell
MAKE_PT(Po_cell, theta, phi);


// Generalize += and *= to +, -=, -, *, /= and /
template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator+(const Pt& a, const Pt& b)
{
    auto sum = a;
    sum += b;
    return sum;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator-=(Pt& a, const Pt& b)
{
    a += -1 * b;
    return a;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator-(const Pt& a, const Pt& b)
{
    auto diff = a;
    diff -= b;
    return diff;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator-(const Pt& a)
{
    return -1 * a;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator*(const Pt& a, const float b)
{
    auto prod = a;
    prod *= b;
    return prod;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator*(const float b, const Pt& a)
{
    auto prod = a;
    prod *= b;
    return prod;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator/=(Pt& a, const float b)
{
    a *= 1. / b;
    return a;
}

template<typename Pt>
__device__ __host__ typename std::enable_if<Is_vector<Pt>::value, Pt>::type
operator/(const Pt& a, const float b)
{
    auto quot = a;
    quot /= b;
    return quot;
}
