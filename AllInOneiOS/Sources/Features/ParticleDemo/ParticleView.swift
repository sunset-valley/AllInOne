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
      .padding(.bottom, 160)
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
  var actualParticleCount = 0  // Dynamic count based on image sampling

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
    guard let image = UIImage(named: "nebula"),
      let cgImage = image.cgImage
    else {
      print("Failed to load nebula image")
      return
    }

    // Get pixel data from image
    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8

    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

    guard
      let context = CGContext(
        data: &pixelData,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      print("Failed to create CGContext")
      return
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    var particles = [Particle]()

    // Scale factor to fit view (maintain aspect ratio)
    let imageAspect = Float(width) / Float(height)
    let viewAspect = Float(viewSize.width) / Float(viewSize.height)

    let scale: Float
    let offsetX: Float
    let offsetY: Float

    if imageAspect > viewAspect {
      // Image is wider than view - fit to width
      scale = Float(viewSize.width) / Float(width) * 0.9
      offsetX = Float(viewSize.width) * 0.05
      offsetY = (Float(viewSize.height) - Float(height) * scale) / 2
    } else {
      // Image is taller than view - fit to height
      scale = Float(viewSize.height) / Float(height) * 0.9
      offsetX = (Float(viewSize.width) - Float(width) * scale) / 2
      offsetY = Float(viewSize.height) * 0.05
    }

    // Sampling stride - sample every N pixels to control density
    // Adjust based on image size to maintain reasonable particle count
    let targetParticles = 200_000
    let totalPixels = width * height
    let sampleStep = max(1, Int(sqrt(Double(totalPixels) / Double(targetParticles))))

    for y in Swift.stride(from: 0, to: height, by: sampleStep) {
      for x in Swift.stride(from: 0, to: width, by: sampleStep) {
        let offset = (y * width + x) * bytesPerPixel

        let r = Float(pixelData[offset]) / 255.0
        let g = Float(pixelData[offset + 1]) / 255.0
        let b = Float(pixelData[offset + 2]) / 255.0
        let a = Float(pixelData[offset + 3]) / 255.0

        // Calculate brightness to filter out dark pixels
        let brightness = (r + g + b) / 3.0

        // Only create particles for visible, bright enough pixels
        if a > 0.1 && brightness > 0.05 {
          // Add jitter for organic look
          let jitter = SIMD2<Float>(
            Float.random(in: -0.5...0.5),
            Float.random(in: -0.5...0.5)
          )

          let pos = SIMD3<Float>(
            offsetX + Float(x) * scale + jitter.x,
            offsetY + Float(y) * scale + jitter.y,
            Float.random(in: -15...15)  // Z depth jitter for 3D effect
          )

          // Noise offset for idle animation
          let noiseOffset = SIMD2<Float>(
            Float.random(in: 0...100),
            Float.random(in: 0...100)
          )

          // Use sampled color with adjusted alpha for blending
          let color = SIMD4<Float>(r, g, b, min(a, 0.6))

          let p = Particle(
            position: pos,
            velocity: .zero,
            homePosition: pos,
            noiseOffset: noiseOffset,
            color: color
          )
          particles.append(p)
        }
      }
    }

    // Update particle count for rendering
    actualParticleCount = particles.count
    print("Generated \(actualParticleCount) particles from image")

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
      let numGroups = MTLSizeMake((actualParticleCount + 63) / 64, 1, 1)

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

      renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: actualParticleCount)
      renderEncoder.endEncoding()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
