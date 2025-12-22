import simd

// 保证内存对齐，C++ 和 Swift 必须一致
struct Particle {
  var position: SIMD3<Float>  // 3D position (x, y, z)
  var velocity: SIMD3<Float>  // 3D velocity
  var homePosition: SIMD3<Float>  // 原始归位点
  var noiseOffset: SIMD2<Float>  // 每个粒子的噪声偏移（用于 idle 动画）
}

struct Uniforms {
  var touchPosition: SIMD2<Float>
  var previousTouchPosition: SIMD2<Float>
  var viewSize: SIMD2<Float>
  var time: Float  // 时间（用于 idle 动画）
  var isTouching: Bool
  var strength: Float
  var radius: Float
  var rise: Float
  var decay: Float
  var _padding: Float = 0
}
