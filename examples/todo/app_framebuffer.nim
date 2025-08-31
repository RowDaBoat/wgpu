#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Simplest framebuffer possible          |
# Takes an array of bytes                |
# and draws it to a fullscreen triangle  |
#________________________________________|
# std dependencies
import std/strformat
import std/sequtils
# External dependencies
from pkg/nglfw as glfw import nil
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#________________________________________________
# types.nim
#__________________
type Window * = object
  ct     *:glfw.Window
  w,h    *:int32
  title  *:string

#________________________________________________
# window.nim
#__________________
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  if (key == glfw.KeyEscape and action == glfw.Press):
    glfw.setWindowShouldClose(win, true)
#__________________
proc close  (win :Window) :bool=  glfw.windowShouldClose(win.ct).bool
  ## Returns true when the GLFW window has been marked to be closed.
proc term   (win :Window) :void=  glfw.destroyWindow(win.ct); glfw.terminate()
  ## Terminates the GLFW window.
proc update (win :Window) :void=  glfw.pollEvents()
  ## Updates the window. Needs to be called each frame.
#__________________
proc init(win :var Window) :void=
  ## Initializes the window with GLFW.
  doAssert glfw.init().bool, "Failed to Initialize GLFW"
  glfw.windowHint(glfw.CLIENT_API, glfw.NO_API)
  win.ct = glfw.createWindow(win.w, win.h, win.title.cstring, nil, nil)
  doAssert win.ct != nil, "Failed to create GLFW window"
  discard glfw.setKeyCallback(win.ct, key)

#__________________
# WGPU callbacks
proc adapterRequestCB *(status :RequestAdapterStatus; adapter :Adapter; message :cstring; userdata :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
  echo &"wgpu: ADAPTER requested with status: {$status}"
proc deviceRequestCB  *(status :RequestDeviceStatus; device :Device; message :cstring; userdata :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
  echo &"wgpu: DEVICE requested with status: {$status}"
  if status != RequestDeviceStatus.success: echo &"    : {$message}"
proc errorCB *(typ :ErrorType; message :cstring; userdata :pointer) :void {.cdecl.}=
  raise newException(IOError, &"wgpu->UnhandledError: ({$typ}): {$message}")
proc deviceLostCB *(reason :DeviceLostReason; message :cstring; userdata :pointer) :void {.cdecl.}=
  raise newException(IOError, &"wgpu->DeviceLost: ({$reason}): {$message}")
proc logCB *(level :LogLevel; message :cstring; userdata :pointer) :void {.cdecl.}=
  echo &"[wgpu: {$level}] {$message}"

# Triangle shader
const shaderCode = """
struct VertIn  { @builtin(vertex_index) id :u32 }
struct VertOut { @builtin(position) pos :vec4f, @location(0) uv :vec2f };
@vertex fn vert(in :VertIn) ->VertOut {
  let uv = vec2f(f32((in.id << 1u) & 2u), f32(in.id & 2u));
  return VertOut(// (x,y)  z    w
    vec4f(uv * 2.0 - 1.0, 0.0, 1.0), // Position
    uv,                              // UV
    );
}
@group(0) @binding(1) var texPixels  :texture_2d<f32>;
@group(0) @binding(2) var texSampler :sampler;
@fragment fn frag(in :VertOut) ->@location(0) vec4<f32> { return textureSample(texPixels, texSampler, in.uv); }
"""

#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "Framebuffer App",
  w:960, h:540,
  )
#_____________________________
# Framebuffer data
#__________________
type Color8 = object
  r,g,b,a :uint8
type Pixels = seq[Color8]
#__________________
const width  :uint32=  512
const height :uint32=  512
var   pixels :Pixels=  newSeqWith[Color8](int(width*height), Color8(r:255, g:255, b:255, a:255))


#________________________________________________
# Entry Point
#__________________
proc run=
  #__________________
  # Init Window
  echo &":: Initializing {window.title}"
  window.init()

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set LogLevel.warn
  #__________________
  # Init wgpu
  var instance = wgpu.create(vaddr InstanceDescriptor(nextInChain: nil))
  var surface  = instance.getSurface(window.ct)
  var adapter :wgpu.Adapter; instance.request(vaddr RequestAdapterOptions(
    nextInChain           : nil,
    compatibleSurface     : surface,
    powerPreference       : PowerPreference.highPerformance,
    backendType           : BackendType.undefined,
    forceFallbackAdapter  : false,
    ), # << RequestAdapterOptions( ... )
    adapterRequestCB, adapter.addr)
  doAssert adapter != nil, "wgpu.Adapter could not be requested."

  # Create the device descriptor
  var deviceDesc = DeviceDescriptor(
    nextInChain            : nil,
    label                  : "Framebuffer Device".cstring,
    requiredFeaturesCount  : 0,
    requiredFeatures       : nil,
    requiredLimits         : nil,
    defaultQueue           : QueueDescriptor(label: "Framebuffer Queue".cstring),
    deviceLostCallback     : deviceLostCB,
    deviceLostUserdata     : nil,
    ) # << DeviceDescriptor( ... )
  var device :wgpu.Device; adapter.request(deviceDesc.addr, deviceRequestCB, device.addr)
  doAssert device != nil, "wgpu.Device could not be requested."
  device.set(errorCB, nil)
  # Get the queue, so we can add commands to it
  var queue = device.getQueue()

  # Create the shader and swapchain
  var shaderDesc      = shaderCode.wgslToDescriptor(label = "FramebufferShader")
  let shader          = device.create(shaderDesc.addr)
  let swapchainFormat = surface.getPreferredFormat(adapter)
  var config = SwapChainDescriptor(
    nextInChain       : cast[ptr ChainedStruct](vaddr SwapChainDescriptorExtras(
      chain           : ChainedStruct(
        next          : nil,
        sType         : SType.swapChainDescriptorExtras
        ), # << chain
      alphaMode       : CompositeAlphaMode.auto,
      viewFormatCount : 0,
      viewFormats     : nil,
      )), # << nextInChain
    label             : nil,
    usage             : {TextureUsage.renderAttachment},
    format            : swapchainFormat,
    width             : 0,
    height            : 0,
    presentMode       : PresentMode.fifo,
    ) # << config (aka SwapChain Descriptor)
  glfw.getWindowSize(window.ct, config.width.iaddr, config.height.iaddr)
  echo &":: Initial window size: {config.width} x {config.height}"
  var swapChain = device.create(surface, config.addr)

  # Create the BindGroupLayoutEntries for both the Uniforms object and the texture
  # NOTE: Fully verbose, but such verbosity is not needed.
  #     : Modified variables are commented, and the rest would be correctly given by Nim's zero initialization if omitted.
  var bindGroupLayoutEntries :seq[BindGroupLayoutEntry]

  # Create the texture entry
  bindGroupLayoutEntries.add BindGroupLayoutEntry(
    nextInChain        : nil,
    binding            : 1,                        # Shader @binding(1) index
    visibility         : { ShaderStage.fragment }, # Used in the fragment stage
    # Not Used. Could be Zero-Initalizated instead of explicit.
    buffer             : BufferBindingLayout(
      nextInChain      : nil,
      typ              : BufferBindingType.undefined,
      hasDynamicOffset : false,
      minBindingSize   : 0,
      ), # << buffer
    # Define the Texture properties
    sampler            : SamplerBindingLayout(
      nextInChain      : nil,
      typ              : SamplerBindingType.nonFiltering,  # Set filter to none
      ), # << sampler
    texture            : TextureBindingLayout(
      nextInChain      : nil,
      sampleType       : TextureSampleType.Float,          # Set the color type to float
      viewDimension    : TextureViewDimension.dim2D,       # Make it a 2D texture
      multisampled     : false,
      ), # << texture
    # Not Used. Could be Zero-Initalizated instead of explicit.
    storageTexture     : StorageTextureBindingLayout(
      nextInChain      : nil,
      access           : StorageTextureAccess.undefined,
      format           : TextureFormat.undefined,
      viewDimension    : TextureViewDimension.undefined,
      ), # << storageTexture
    ) # << Uniforms entry

  # Create the Sampler BindGroup entry
  bindGroupLayoutEntries.add BindGroupLayoutEntry(
    nextInChain        : nil,
    binding            : 2,                        # Shader @binding(2) index
    visibility         : { ShaderStage.fragment }, # Used in the fragment stage
    # Not Used. Could be Zero-Initalizated instead of explicit.
    buffer             : BufferBindingLayout(
      nextInChain      : nil,
      typ              : BufferBindingType.undefined,
      hasDynamicOffset : false,
      minBindingSize   : 0,
      ), # << buffer
    # Define the Texture properties
    sampler            : SamplerBindingLayout(
      nextInChain      : nil,
      typ              : SamplerBindingType.filtering,  # Set filtering
      ), # << sampler
    # Not Used. Could be Zero-Initalizated instead of explicit.
    texture            : TextureBindingLayout(
      nextInChain      : nil,
      sampleType       : TextureSampleType.undefined,
      viewDimension    : TextureViewDimension.undefined,
      multisampled     : false,
      ), # << texture
    storageTexture     : StorageTextureBindingLayout(
      nextInChain      : nil,
      access           : StorageTextureAccess.undefined,
      format           : TextureFormat.undefined,
      viewDimension    : TextureViewDimension.undefined,
      ), # << storageTexture
    ) # << Uniforms entry

  # Assign the BindGroupLayoutEntries to the Layout, including the new Sampler entry
  var bindGroupLayout = device.create(vaddr BindGroupLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello Uniform BindGroupLayout".cstring,
    entryCount           : bindGroupLayoutEntries.len.uint32,
    entries              : bindGroupLayoutEntries[0].addr,
    )) # << device.createBindGroupLayout()

  # Configure the pipeline with our inputs
  var pipelineLayout = device.create(vaddr PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello PipelineLayout".cstring,
    bindGroupLayoutCount : 1,
    bindGroupLayouts     : bindGroupLayout.addr,
    )) # << device.createPipelineLayout()
  let pipeline = device.create(vaddr RenderPipelineDescriptor(
    label                    : "Render pipeline".cstring,
    layout                   : pipelineLayout,
    vertex                   : VertexState(
      module                 : shader,
      entryPoint             : "vert".cstring,
      constantCount          : 0,
      constants              : nil,
      bufferCount            : 0,
      buffers                : nil,
      ), # << vertex
    primitive                : PrimitiveState(
      nextInChain            : nil,
      topology               : PrimitiveTopology.triangleList,
      stripIndexFormat       : IndexFormat.undefined,
      frontFace              : FrontFace.ccw,
      cullMode               : CullMode.none,
      ), # << primitive
    depthStencil             : nil,
    multisample              : MultisampleState(
      nextInChain            : nil,
      count                  : 1,
      mask                   : uint32.high,
      alphaToCoverageEnabled : false,
      ), # << multisample
    fragment                 : vaddr FragmentState(
      nextInChain            : nil,
      module                 : shader,
      entryPoint             : "frag".cstring,
      constantCount          : 0,
      constants              : nil,
      targetCount            : 1,
      targets                : vaddr ColorTargetState(
        nextInChain          : nil,
        format               : swapchainFormat,
        blend                : vaddr BlendState(
          alpha              : BlendComponent(
            operation        : BlendOperation.Add,
            srcFactor        : BlendFactor.one,
            dstFactor        : BlendFactor.zero,
            ), # << alpha
          color              : BlendComponent(
            operation        : BlendOperation.Add,
            srcFactor        : BlendFactor.one,
            dstFactor        : BlendFactor.zero,
            ), # << color
          ), # << blend
        writeMask            : ColorWriteMask.all,
        ), # << targets
      ), # << fragment
    )) # << pipeline

  # Create the BindGroup for our texture
  var bindGroupEntries :seq[BindGroupEntry]

  # Create the Texture
  var texSize   = Extent3D(width:width, height:height, depthOrArrayLayers:1)
  var texFormat = TextureFormat.RGBA8Unorm
  var tex       = device.create(vaddr TextureDescriptor(
    nextInChain     : nil,
    label           : "Hello Tex".cstring,
    usage           : { TextureUsage.copyDst, TextureUsage.textureBinding },
    dimension       : TextureDimension.dim2D,
    size            : texSize,
    format          : texFormat,
    mipLevelCount   : 1,
    sampleCount     : 1,
    viewFormatCount : 0,
    viewFormats     : nil,
    )) # << device.createTexture()

  # Create the Texture Copy arguments
  var destination = ImageCopyTexture(
    nextInChain : nil,
    texture     : tex,
    mipLevel    : 0,
    origin      : Origin3D(x:0, y:0, z:0),
    aspect      : TextureAspect.all,
    )
  # Create the Texture Layout
  var source = TextureDataLayout(
    nextInChain  : nil,
    offset       : 0,
    bytesPerRow  : sizeof(Color8).uint32 * width,
    rowsPerImage : height,
    )
  # Upload the texture to the GPU
  queue.write(destination.addr, pixels[0].addr, pixels.size, source.addr, texSize.addr)

  # Create the View into the Texture
  var texView = tex.create(vaddr TextureViewDescriptor(
    nextInChain     : nil,
    label           : "Hello TexView".cstring,
    format          : texFormat,
    dimension       : TextureViewDimension.dim2D,
    baseMipLevel    : 0,
    mipLevelCount   : 1,
    baseArrayLayer  : 0,
    arrayLayerCount : 1,
    aspect          : TextureAspect.all,
    )) # << texture.createTextureView()

  # Create the Texture entry, and add it to the list of entries
  bindGroupEntries.add BindGroupEntry(
    nextInChain : nil,
    binding     : 1,   # Shader @binding(1) index
    buffer      : nil,
    offset      : 0,
    size        : 0,
    sampler     : nil,
    textureView : texView,
    ) # << Texture entry

  # Create the sampler
  var sampler = device.create(vaddr SamplerDescriptor(
    nextInChain   : nil,
    label         : "Hello Sampler".cstring,
    addressModeU  : AddressMode.repeat,
    addressModeV  : AddressMode.repeat,
    addressModeW  : AddressMode.repeat,
    magFilter     : FilterMode.linear,
    minFilter     : FilterMode.linear,
    mipmapFilter  : MipmapFilterMode.linear,
    lodMinClamp   : 0.0.cfloat,
    lodMaxClamp   : 32.0.cfloat,
    compare       : CompareFunction.undefined,
    maxAnisotropy : 1.uint16,
    ))
  # Create the sampler BindGroupEntry
  bindGroupEntries.add BindGroupEntry(
    nextInChain : nil,
    binding     : 2,   # Shader @binding(2) index
    buffer      : nil,
    offset      : 0,
    size        : 0,
    sampler     : sampler, # Add the sampler to the entry
    textureView : nil,
    ) # << Sampler entry

  # Create the BindGroup
  var bindGroup = device.create(vaddr BindGroupDescriptor(
    nextInChain   : nil,
    label         : "Hello BindGroup".cstring,
    layout        : bindGroupLayout,
    entryCount    : bindGroupEntries.len.uint32,  # We send multiple bindgroup entries
    entries       : bindGroupEntries[0].addr,     # Pass the address of the first, wgpu does the rest
    )) # << device.createBindGroup()


  #__________________
  # Update loop
  while not window.close():
    var nextTexture :TextureView= nil
    for attempt in 0..<2:  # Attempt to create the swapchain twice
      var prevWidth  = config.width
      var prevHeight = config.height
      glfw.getWindowSize(window.ct, config.width.iaddr, config.height.iaddr)
      if prevWidth != config.width or prevHeight != config.height:  # Window size changed, recreate the swapchain
        swapChain = device.create(surface, config.addr)
      nextTexture = swapChain.getCurrentTextureView()
      if attempt == 0 and nextTexture == nil:
        echo "WRN: swapChain.getCurrentTextureView() failed; attempting to create a new swap chain..."
        config.width  = 0
        config.height = 0
        continue  # Skip to the next step
      break       # Exit attempts. We are either at the second attempt, or the texture already works
    doAssert nextTexture != nil, "ERR:: Cannot acquire next swap chain texture"
    var encoder = device.create(vaddr CommandEncoderDescriptor(
      nextInChain : nil,
      label       : "Framebuffer Command Encoder".cstring,
      )) # << device.createEncoder( ... )
    var renderPass = encoder.begin(vaddr RenderPassDescriptor(
      nextInChain            : nil,
      label                  : nil,
      colorAttachmentCount   : 1,
      colorAttachments       : vaddr RenderPassColorAttachment(
        view                 : nextTexture,
        resolveTarget        : nil,
        loadOp               : LoadOp.clear,
        storeOp              : StoreOp.store,
        clearValue           : Color(r:0.1, g:0.1, b:0.1, a:1.0),  # WGPU Color, but similar to chroma/color
        ), # << colorAttachments
      depthStencilAttachment : nil,
      occlusionQuerySet      : nil,
      timestampWriteCount    : 0,
      timestampWrites        : nil,
      )) # << renderPass
    # Draw the Fullscreen Triangle into the texture with the given settings
    renderPass.set(pipeline)
    renderPass.set(0, bindGroup, 0, nil)  # Set the `bindGroup` at @group(0), with no dynamic offsets (0, nil)
    renderPass.draw(3,1,0,0)              # Draw using the non-indexed version ->( vertexCount, instanceCount, firstVertex, firstInstance )

    renderPass.End()
    nextTexture.release()
    # Submit the Rendering Queue, and present it to the surface
    var cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
      nextInChain : nil,
      label       : "Hello Command Buffer".cstring,
      )) # << encoder.finish()
    queue.submit(1, cmdBuffer.addr)
    swapChain.present()  # like gl.swapBuffers()
    # Input update from glfw
    window.update()

  #__________________
  # Terminate
  tex.release()
  window.term()
#__________________
when isMainModule: run()

