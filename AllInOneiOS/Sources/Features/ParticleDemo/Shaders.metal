#include <metal_stdlib>
using namespace metal;

struct Particle {
    float3 position;
    float3 velocity;
    float3 homePosition;
    float2 noiseOffset;
    float4 color;  // 粒子颜色 RGBA (从图片采样)
};

struct Uniforms {
    float2 touchPosition;
    float2 previousTouchPosition;
    float2 viewSize;
    float time;
    bool isTouching;
    float strength;
    float radius;
    float rise;
    float decay;
    float _padding;
};

// --- Simplex Noise Functions ---
// 简化版 2D/3D 噪声，用于有机运动

float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(dot(hash2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                   dot(hash2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                   dot(hash2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
}

// --- 计算着色器 (物理模拟) ---
kernel void updateParticles(device Particle *particles [[buffer(0)]],
                            constant Uniforms &uniforms [[buffer(1)]],
                            uint id [[thread_position_in_grid]])
{
    Particle p = particles[id];
    
    // 1. Idle 运动：使用噪声产生有机飘动
    float2 noiseInput = p.noiseOffset + float2(uniforms.time * 0.3, uniforms.time * 0.25);
    float noiseX = noise2D(noiseInput) * 0.8;
    float noiseY = noise2D(noiseInput + float2(100.0, 0.0)) * 0.8;
    float noiseZ = noise2D(noiseInput + float2(0.0, 100.0)) * 0.4;
    
    float3 idleForce = float3(noiseX, noiseY, noiseZ);
    
    // 2. 弹簧力 (Spring Force)
    float3 toHome = p.homePosition - p.position;
    float3 springForce = toHome * uniforms.rise;
    
    // 3. 排斥力 (交互) - 3D 球形排斥
    float3 repulsionForce = float3(0, 0, 0);
    if (uniforms.isTouching) {
        // 3D 距离计算（触摸点假设在 Z=0 平面）
        float3 touchPos3D = float3(uniforms.touchPosition, 0.0);
        float3 toTouch3D = p.position - touchPos3D;
        float dist3D = length(toTouch3D);
        
        // 2D 距离用于判断影响范围
        float dist2D = length(p.position.xy - uniforms.touchPosition);
        
        if (dist2D < uniforms.radius && dist3D > 0.001) {
            // 基于 2D 距离计算衰减因子
            float factor = 1.0 - (dist2D / uniforms.radius);
            factor = factor * factor;  // 平方衰减，中心更强
            
            // 3D 排斥方向
            float3 repulsionDir = normalize(toTouch3D);
            
            // 确保有足够的 Z 分量推开粒子
            if (abs(repulsionDir.z) < 0.3) {
                repulsionDir.z = (p.position.z >= 0 ? 1.0 : -1.0) * 0.5;
                repulsionDir = normalize(repulsionDir);
            }
            
            repulsionForce = repulsionDir * uniforms.strength * factor * 4.0;
            
            // 加入拖拽方向的力
            float2 dragVelocity = uniforms.touchPosition - uniforms.previousTouchPosition;
            float dragSpeed = length(dragVelocity);
            if (dragSpeed > 0.5) {
                repulsionForce.xy += dragVelocity * factor * 1.5;
            }
        }
    }
    
    // 4. 合并力并更新速度
    p.velocity += springForce + repulsionForce + idleForce * 0.1;
    
    // 5. 阻尼
    p.velocity *= uniforms.decay;
    
    // 6. 速度限制
    float speed = length(p.velocity);
    if (speed > 50.0) {
        p.velocity = normalize(p.velocity) * 50.0;
    }
    
    // 7. 更新位置
    p.position += p.velocity;
    
    particles[id] = p;
}

// --- 渲染着色器 ---

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

vertex VertexOut particleVertex(const device Particle *particles [[buffer(0)]],
                                constant Uniforms &uniforms [[buffer(1)]],
                                uint vertexID [[vertex_id]])
{
    Particle p = particles[vertexID];
    VertexOut out;
    
    // 3D 透视效果：Z 影响位置偏移（模拟深度）
    float depthFactor = 1.0 + p.position.z * 0.002;  // Z 轻微影响缩放
    float2 projectedPos = p.position.xy;
    
    // 转换到 NDC
    float2 ndcSpace = (projectedPos / uniforms.viewSize) * 2.0 - 1.0;
    out.position = float4(ndcSpace.x, -ndcSpace.y, 0, 1);
    
    // 3D 深度影响点大小：近大远小
    float baseSize = 2.0;
    float zNormalized = clamp((p.position.z + 50.0) / 100.0, 0.0, 1.0);
    out.pointSize = clamp(baseSize * (0.8 + zNormalized * 0.4), 1.0, 4.0);
    
    // 直接使用粒子颜色（从图片采样）
    float3 color = p.color.rgb;
    
    // 深度影响亮度
    float depthBrightness = 0.9 + zNormalized * 0.1;
    color *= depthBrightness;
    
    // 速度影响亮度
    float speed = length(p.velocity);
    float speedBrightness = 1.0 + min(speed * 0.01, 0.15);
    color *= speedBrightness;
    
    // 使用粒子的 alpha
    float alpha = p.color.a;
    
    out.color = float4(color, alpha);
    
    return out;
}

fragment float4 particleFragment(VertexOut in [[stage_in]]) {
    return in.color;
}
