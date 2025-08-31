#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Simplest Buffer-based Triangle possible  |
# Uses only one buffer for the position.   |
#__________________________________________|
# std dependencies
import std/strformat
import std/os
# External dependencies
from   pkg/nglfw as glfw import nil
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#________________________________________________
# types.nim
#__________________
type Vec3 = object
  x,y,z :float32
proc vec3  (x,y,z :SomeNumber)   :Vec3=   Vec3(x:x.float32, y:y.float32, z:z.float32)

type Window * = object
  ct     *:glfw.Window
  w,h    *:int32
  title  *:string

#________________________________________________
# mesh.nim
#__________________
template size *[T](v :seq[T]) :uint64=  uint64( v.len * sizeof(v[0]) )
  ## Returns the size in bytes of the given seq

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
proc adapterRequestCB *(status :RequestAdapterStatus; adapter :Adapter; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
  echo &"wgpu: ADAPTER requested with status: {$status}"
proc deviceRequestCB  *(status :RequestDeviceStatus; device :Device; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
  echo &"wgpu: DEVICE requested with status: {$status}"
  if status != RequestDeviceStatus.success: echo &"    : {$message}"
proc errorCB *(typ :ErrorType; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"wgpu: UNCAPTURED ERROR: ({$typ}): {$message}"
proc deviceLostCB *(reason :DeviceLostReason; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"wgpu: DEVICE LOST: ({$reason}): {$message}"
proc logCB *(level :LogLevel; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"[{$level}] {$message}"

# Triangle shader
const shaderCode = """
struct VertIn {
  @builtin(vertex_index) id :u32,
  @location(0) pos :vec3<f32>,
}
@vertex fn vert(in :VertIn) ->@builtin(position) vec4<f32> {
  return vec4<f32>(in.pos, 1.0);
}

@fragment fn frag() ->@location(0) vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
"""

var triangle :seq[Vec3]= @[
  #       x    y    z
  vec3( -0.5, -0.5, 0.0 ),  # v0
  vec3(  0.5, -0.5, 0.0 ),  # v1
  vec3(  0.0,  0.5, 0.0 ),  # v2
  ]

#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu Tut",
  w:960, h:540,
  )

#________________________________________________
# Entry Point
#__________________
proc run=
  #__________________
  # Init Window
  echo "Hello Buffered Triangle"
  window.init()

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set LogLevel.warn
  #__________________
  # Init wgpu
  var instanceDesc = InstanceDescriptor(nextInChain: nil)
  var instance     = wgpu.create(instanceDesc.addr)
  var surface      = instance.getSurface(window.ct)
  var adapterOpts  = RequestAdapterOptions(
    nextInChain           : nil,
    compatibleSurface     : surface,
    powerPreference       : PowerPreference.highPerformance,
    backendType           : BackendType.undefined,
    forceFallbackAdapter  : false,
    )
  var adapter :wgpu.Adapter;  instance.request(adapterOpts.addr, adapterRequestCB, adapter.addr)
  doAssert adapter != nil, "wgpu.Adapter could not be requested."
  #__________________________________
  # NEW:
  # 1. Set the limits that we require for this example
  var requiredLimits = RequiredLimits(
    nextInChain           : nil,
    limits                : Limits.new(  # With custom `new` proc because some required defaults are not 0
      maxVertexAttributes = 1,
      maxVertexBuffers    = 1,
      ), # << limits
    ) # << requiredLimits

  # 2. Create the device descriptor, with our custom limits
  var deviceDesc = DeviceDescriptor(
    nextInChain            : nil,
    label                  : "Hello Device",
    requiredFeaturesCount  : 0,
    requiredFeatures       : nil,
    requiredLimits         : requiredLimits.addr,  # <-- Added for this example, the rest is the same
    defaultQueue           : QueueDescriptor(
      nextInChain          : nil,
      label                : "Hello Default Queue"
      ), # << defaultQueue
    deviceLostCallback     : deviceLostCB,
    deviceLostUserdata     : nil,
    ) # << deviceDesc
  var device :wgpu.Device; adapter.request(deviceDesc.addr, deviceRequestCB, device.addr)
  doAssert device != nil, "wgpu.Device could not be requested."
  device.set(errorCB, nil)

  # 3. Read the vertex attributes and buffers limits of the system
  echo ":: Supported limits:   (after setting RequiredLimits)"
  var supportedLimits :SupportedLimits
  discard adapter.get(supportedLimits.addr)
  echo ": adapter.maxVertexAttributes: ",supportedLimits.limits.maxVertexAttributes
  discard device.get(supportedLimits.addr)
  echo ": device.maxVertexAttributes:  ",supportedLimits.limits.maxVertexAttributes
  # When setting the required limits to 0 (unlimited), my system says:
  # > adapter.maxVertexAttributes: 32
  # > device.maxVertexAttributes:  16

  # OLD: Get the queue, so we can add commands to it
  var queue = device.getQueue()

  # OLD: Create the shader and swapchain. Nothing changed
  var shaderDesc      = shaderCode.wgslToDescriptor(label = "TriangleShader")
  let shader          = device.create(shaderDesc.addr)
  let swapchainFormat = surface.getPreferredFormat(adapter)
  var config = SwapChainDescriptor(
    nextInChain        : cast[ptr ChainedStruct](vaddr SwapChainDescriptorExtras(
      chain            : ChainedStruct(
        next           : nil,
        sType          : SType.swapChainDescriptorExtras,
        ), # << chain
      alphaMode        : CompositeAlphaMode.auto,
      viewFormatCount  : 0,
      viewFormats      : nil,
      )), # << nextInChain
    label              : nil,
    usage              : {TextureUsage.renderAttachment},
    format             : swapchainFormat,
    width              : 0,
    height             : 0,
    presentMode        : PresentMode.fifo,
    ) # << config (aka SwapChain Descriptor)
  glfw.getWindowSize(window.ct, config.width.iaddr, config.height.iaddr)
  echo &":: Initial window size: {config.width} x {config.height}"
  var swapChain = device.create(surface, config.addr)

  # NEW:
  # 4. Create and upload the vertex attribute buffers
  var triangleBuffer = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Triangle Vertex buffer".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.vertex},
    size              : triangle.size,
    mappedAtCreation  : false,
    )) # << device.createBuffer()

  # 4.1. Positions buffer layout
  var triangleLayout = VertexBufferLayout(
    arrayStride       : sizeof(triangle[0]).uint32,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
      attributes      : vaddr VertexAttribute(
      format          : VertexFormat.float32x3,
      offset          : 0,
      shaderLocation  : 0,
      ) # << posAttr
    ) # << posLayout
  # Write triangle.position at triangleBuffer offset 0
  queue.write(triangleBuffer, 0, triangle[0].addr, triangle.size.csize_t)

  # 5. Configure the pipeline
  #    Only the buffer inputs have changed.
  let pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : "Render pipeline".cstring,
    layout                    : nil,
    vertex                    : VertexState(
      module                  : shader,
      entryPoint              : "vert".cstring,
      constantCount           : 0,
      constants               : nil,
      bufferCount             : 1,                   # <--- This changed
      buffers                 : triangleLayout.addr, # <--- This changed
      ), # << vertex
    primitive                 : PrimitiveState(
      nextInChain             : nil,
      topology                : PrimitiveTopology.triangleList,
      stripIndexFormat        : IndexFormat.undefined,
      frontFace               : FrontFace.ccw,
      cullMode                : CullMode.none,
      ), # << primitive
    depthStencil              : nil,
    multisample               : MultisampleState(
      nextInChain             : nil,
      count                   : 1,
      mask                    : uint32.high,
      alphaToCoverageEnabled  : false,
      ), # << multisample
    fragment                  : vaddr FragmentState(
      nextInChain             : nil,
      module                  : shader,
      entryPoint              : "frag".cstring,
      constantCount           : 0,
      constants               : nil,
      targetCount             : 1,
      targets                 : vaddr ColorTargetState(
        nextInChain           : nil,
        format                : swapchainFormat,
        blend                 : vaddr BlendState(
          alpha               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.one,
            dstFactor         : BlendFactor.zero,
            ), # << alpha
          color               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.one,
            dstFactor         : BlendFactor.zero,
            ), # << color
          ), # << blend
        writeMask             : ColorWriteMask.all,
        ), # << targets
      ), # << fragment
    )) # << pipeline

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
      nextInChain  : nil,
      label        : "Command Encoder",
      ))
    var renderPass = encoder.begin(vaddr RenderPassDescriptor(
      nextInChain             : nil,
      label                   : nil,
      colorAttachmentCount    : 1,
      colorAttachments        : vaddr RenderPassColorAttachment(
        view                  : nextTexture,
        resolveTarget         : nil,
        loadOp                : LoadOp.clear,
        storeOp               : StoreOp.store,
        clearValue            : Color(r:0.1, g:0.1, b:0.1, a:1.0),  # WGPU Color, but similar to chroma/color
        ), # << colorAttachments
      depthStencilAttachment  : nil,
      occlusionQuerySet       : nil,
      timestampWriteCount     : 0,
      timestampWrites         : nil,
      )) # << renderPass
    # Draw into the texture with the given settings
    renderPass.set(pipeline)

    # NEW:
    # 6. Set the vertex buffer in the RenderPass
    renderPass.setVertexBuffer(0, triangleBuffer, 0, triangle.size)
    renderPass.draw(triangle.len.uint32, 1,0,0)  # vertexCount, instanceCount, firstVertex, firstInstance

    # OLD: Continue as before
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
  window.term()

#__________________
when isMainModule: run()

