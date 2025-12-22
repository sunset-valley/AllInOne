import MetalKit
import SwiftUI

// --- SwiftUI View ---
struct ParticleView: View {
  @State private var touchLocation: CGPoint = .zero
  @State private var isTouching: Bool = false

  // Debug Parameters
  @State private var radius: Float = 0.05
  @State private var strength: Float = 0.50
  @State private var rise: Float = 0.5
  @State private var decay: Float = 10.0

  var body: some View {
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      // Metal View
      MetalViewRepresentable(
        touchLocation: $touchLocation,
        isTouching: $isTouching,
        radius: $radius,
        strength: $strength,
        rise: $rise,
        decay: $decay
      )
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            touchLocation = value.location
            isTouching = true
          }
          .onEnded { _ in
            isTouching = false
          }
      )

      // Debug Controls Overlay
      VStack {
        Spacer()
        debugControls
      }
    }
  }

  private var debugControls: some View {
    VStack(spacing: 16) {
      DebugSlider(label: "Radius", value: $radius, range: 0.01...0.1)
      DebugSlider(label: "Strength", value: $strength, range: 0.1...1.0)
      DebugSlider(label: "Rise", value: $rise, range: 0.1...1.0, decimals: 1)
      DebugSlider(label: "Decay", value: $decay, range: 5.0...15.0, decimals: 1)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .padding(.bottom, 40)
  }
}

// --- Debug Slider Component ---
private struct DebugSlider: View {
  let label: String
  @Binding var value: Float
  let range: ClosedRange<Float>
  let decimals: Int

  init(label: String, value: Binding<Float>, range: ClosedRange<Float>, decimals: Int = 2) {
    self.label = label
    self._value = value
    self.range = range
    self.decimals = decimals
  }

  var body: some View {
    HStack(spacing: 16) {
      Text(label)
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: 75, alignment: .leading)

      Slider(value: $value, in: range)
        .tint(.orange)

      Text(String(format: "%.\(decimals)f", value))
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.7))
        .frame(width: 50, alignment: .trailing)
    }
  }
}

// --- UIViewRepresentable 包装器 ---
struct MetalViewRepresentable: UIViewRepresentable {
  @Binding var touchLocation: CGPoint
  @Binding var isTouching: Bool
  @Binding var radius: Float
  @Binding var strength: Float
  @Binding var rise: Float
  @Binding var decay: Float

  func makeCoordinator() -> Renderer {
    Renderer(parent: self)
  }

  func makeUIView(context: Context) -> MTKView {
    let mtkView = MTKView()
    mtkView.delegate = context.coordinator
    mtkView.device = context.coordinator.device
    mtkView.framebufferOnly = true
    mtkView.colorPixelFormat = .bgra8Unorm
    mtkView.preferredFramesPerSecond = 120
    mtkView.backgroundColor = .clear
    return mtkView
  }

  func updateUIView(_ uiView: MTKView, context: Context) {
    context.coordinator.updateInteraction(
      location: touchLocation,
      isTouching: isTouching,
      radius: radius,
      strength: strength,
      rise: rise,
      decay: decay
    )
  }
}

// --- Renderer (核心引擎) ---
class Renderer: NSObject, MTKViewDelegate {
  var parent: MetalViewRepresentable
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!

  // Pipelines
  var computePipelineState: MTLComputePipelineState!
  var renderPipelineState: MTLRenderPipelineState!

  // Buffers
  var particleBuffer: MTLBuffer!
  let particleCount = 200_000  // 200k particles for better visual quality

  // Interaction Data
  var currentTouch: CGPoint = .zero
  var previousTouch: CGPoint = .zero  // For drag velocity tracking
  var isTouching: Bool = false
  var viewSize: CGSize = .zero

  // Debug Parameters
  var radius: Float = 0.05
  var strength: Float = 0.50
  var rise: Float = 0.1
  var decay: Float = 10.0

  // Time tracking for idle animation
  var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

  init(parent: MetalViewRepresentable) {
    self.parent = parent
    self.device = MTLCreateSystemDefaultDevice()
    self.commandQueue = device.makeCommandQueue()
    super.init()

    setupPipelines()
  }

  func setupPipelines() {
    let library = device.makeDefaultLibrary()!

    // 1. Compute Pipeline
    let kernelFunction = library.makeFunction(name: "updateParticles")!
    computePipelineState = try! device.makeComputePipelineState(function: kernelFunction)

    // 2. Render Pipeline
    let vertexFunc = library.makeFunction(name: "particleVertex")!
    let fragmentFunc = library.makeFunction(name: "particleFragment")!

    let renderDesc = MTLRenderPipelineDescriptor()
    renderDesc.vertexFunction = vertexFunc
    renderDesc.fragmentFunction = fragmentFunc
    renderDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

    // 启用 Alpha Blending 让粒子融合
    renderDesc.colorAttachments[0].isBlendingEnabled = true
    renderDesc.colorAttachments[0].rgbBlendOperation = .add
    renderDesc.colorAttachments[0].alphaBlendOperation = .add
    renderDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    renderDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    renderDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
    renderDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

    renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderDesc)
  }

  func setupParticles(viewSize: CGSize) {
    var particles = [Particle]()

    // Center of the cloud
    let centerX = Float(viewSize.width) / 2
    let centerY = Float(viewSize.height) / 2 - 30

    // Cloud parameters
    let baseRadius: Float = min(Float(viewSize.width), Float(viewSize.height)) * 0.32

    for _ in 0..<particleCount {
      // 使用简单的球形分布 + 随机扰动创建云团
      let theta = Float.random(in: 0...(2 * .pi))
      let phi = Float.random(in: 0...(.pi))

      // 非均匀径向分布（中心密集）
      let u = Float.random(in: 0...1)
      let r = baseRadius * pow(u, 0.4)  // 0.4 < 0.5 让分布更均匀些

      // 球形坐标转笛卡尔
      var x = centerX + r * sin(phi) * cos(theta)
      var y = centerY + r * cos(phi)
      var z = r * sin(phi) * sin(theta) * 0.5  // Z 方向压扁

      // 添加随机扰动创建不规则边缘
      let noiseAmount = baseRadius * 0.12
      x += Float.random(in: -noiseAmount...noiseAmount)
      y += Float.random(in: -noiseAmount...noiseAmount)
      z += Float.random(in: -noiseAmount * 0.5...noiseAmount * 0.5)

      let pos = SIMD3<Float>(x, y, z)

      // 每个粒子独立的噪声偏移用于 idle 动画
      let noiseOffset = SIMD2<Float>(
        Float.random(in: 0...100),
        Float.random(in: 0...100)
      )

      let p = Particle(
        position: pos,
        velocity: .zero,
        homePosition: pos,
        noiseOffset: noiseOffset
      )
      particles.append(p)
    }

    let size = particles.count * MemoryLayout<Particle>.stride
    particleBuffer = device.makeBuffer(bytes: particles, length: size, options: .storageModeShared)
  }

  func updateInteraction(
    location: CGPoint,
    isTouching: Bool,
    radius: Float,
    strength: Float,
    rise: Float,
    decay: Float
  ) {
    self.previousTouch = self.currentTouch  // Save previous position
    self.currentTouch = location
    self.isTouching = isTouching
    self.radius = radius
    self.strength = strength
    self.rise = rise
    self.decay = decay
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    self.viewSize = size
    // Re-setup particles when view size changes
    setupParticles(
      viewSize: CGSize(
        width: size.width / view.contentScaleFactor,
        height: size.height / view.contentScaleFactor
      ))
  }

  func draw(in view: MTKView) {
    guard particleBuffer != nil,
      let drawable = view.currentDrawable,
      let commandBuffer = commandQueue.makeCommandBuffer()
    else { return }

    let scaleFactor = view.contentScaleFactor
    let pointSize = CGSize(
      width: viewSize.width / scaleFactor,
      height: viewSize.height / scaleFactor
    )

    // --- Compute Pass ---
    if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
      computeEncoder.setComputePipelineState(computePipelineState)

      // Map UI values to physics values
      let mappedRadius = radius * 300
      let mappedStrength = strength * 10
      let mappedRise = rise * 0.01
      let mappedDecay = 1.0 - (decay * 0.02)

      // Calculate elapsed time for idle animation
      let currentTime = Float(CFAbsoluteTimeGetCurrent() - startTime)

      var uniforms = Uniforms(
        touchPosition: SIMD2<Float>(Float(currentTouch.x), Float(currentTouch.y)),
        previousTouchPosition: SIMD2<Float>(Float(previousTouch.x), Float(previousTouch.y)),
        viewSize: SIMD2<Float>(Float(pointSize.width), Float(pointSize.height)),
        time: currentTime,
        isTouching: isTouching,
        strength: mappedStrength,
        radius: mappedRadius,
        rise: mappedRise,
        decay: mappedDecay
      )

      computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
      computeEncoder.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

      let threadsPerGroup = MTLSizeMake(64, 1, 1)
      let numGroups = MTLSizeMake((particleCount + 63) / 64, 1, 1)

      computeEncoder.dispatchThreadgroups(numGroups, threadsPerThreadgroup: threadsPerGroup)
      computeEncoder.endEncoding()
    }

    // --- Render Pass ---
    let renderPassDescriptor = view.currentRenderPassDescriptor
    renderPassDescriptor?.colorAttachments[0].loadAction = .clear
    renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

    if let renderDesc = renderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc)
    {
      renderEncoder.setRenderPipelineState(renderPipelineState)
      renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)

      var uniforms = Uniforms(
        touchPosition: .zero,
        previousTouchPosition: .zero,
        viewSize: SIMD2<Float>(Float(pointSize.width), Float(pointSize.height)),
        time: 0,
        isTouching: false,
        strength: 0,
        radius: 0,
        rise: 0,
        decay: 0
      )
      renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

      renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
      renderEncoder.endEncoding()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
