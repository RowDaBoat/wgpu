#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Hello Triangle from wgpu-native/examples          |
# No buffers. Vertices are harcoded in the shader.  |
#___________________________________________________|
# @deps std
import std/strformat
import std/os
# @deps wgpu
import wgpu
# @deps external
from pkg/nglfw as glfw import nil
# @deps Example Extensions
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
proc adapterRequestCB *(status :RequestAdapterStatus; adapter :Adapter; message :StringView; userdata :pointer; userdata2 :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
#__________________
proc deviceRequestCB *(status :RequestDeviceStatus; device :Device; message :StringView; userdata :pointer; userdata2 :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
#__________________
proc errorCB *(device :ptr Device; typ :ErrorType; message :StringView; userdata :pointer; userdata2 :pointer) :void {.cdecl.}=
  echo &"UNCAPTURED ERROR: ({$typ}): {$message}"
#__________________
proc deviceLostCB *(device :ptr Device; reason :DeviceLostReason;  message :StringView; userdata :pointer; userdata2 :pointer) :void {.cdecl.}=
  echo &"DEVICE LOST: ({$reason}): {$message}"
#__________________
proc logCB *(level :LogLevel; message :StringView; userdata :pointer) :void {.cdecl.}=
  echo &"[{$level}] {$message.data}"


#_______________________________________
# @section Triangle Shaders
#_____________________________
const shaderCode = """
@vertex
fn vs_main(
    @builtin(vertex_index) aID :u32
  ) ->@builtin(position) vec4<f32> {
  let x = f32(i32(aID) - 1);
  let y = f32(i32(aID & 1u) * 2 - 1);
  return vec4<f32>(x, y, 0.0, 1.0);
}

@fragment
fn fs_main() ->@location(0) vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
"""

#________________________________________________
# @section state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu Tut",
  w:960, h:540,
  )


#________________________________________________
# @section Entry Point
#__________________
proc run=
  #__________________
  # Init Window
  echo "Hello wgpu"
  window.init()

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set LogLevel.Warn
  #__________________
  # Init wgpu
  var instanceDesc = InstanceDescriptor(nextInChain: nil)
  var instance     = wgpu.create(instanceDesc.addr)
  var surface      = instance.getSurface(window.ct)
  var adapter      :wgpu.Adapter; discard instance.request(
    options                 = vaddr RequestAdapterOptions(
      nextInChain           : nil,
      featureLevel          : Core,
      powerPreference       : HighPerformance,
      forceFallbackAdapter  : false.uint32,
      backendType           : Undefined,
      compatibleSurface     : surface,
      ), #:: RequestAdapterOptions
    callbackInfo            = RequestAdapterCallbackInfo(
      nextInChain           : nil,
      mode                  : AllowSpontaneous,
      callback              : adapterRequestCB,
      userdata1             : adapter.addr,
      userdata2             : nil,
      ), #:: RequestAdapterCallbackInfo
    ) #:: instance.request
  echo ":: Adapter Information for this system: "
  let info = adapter.info()
  echo ":  Vendor       : ",info.vendor
  echo ":  Architecture : ",info.architecture
  echo ":  Device       : ",info.device
  echo ":  Description  : ",info.description
  echo ":  Backend      : ",$info.backendType
  echo ":  Adapter Type : ",$info.adapterType
  echo ":: Adapter Features supported by this system: "
  for it in adapter.features(): echo ":  ",$it
  echo ":: Surface Capabilities supported by this system: "
  let caps = surface.capabilities(adapter)
  echo ":  Texture Formats:"
  for formt in caps.formats:      echo ":  - ",$formt
  echo ":  Present Modes:"
  for prsnt in caps.presentModes: echo ":  - ",$prsnt
  echo ":  Alpha Modes:"
  for alpha in caps.alphaModes:   echo ":  - ",$alpha

  var device :wgpu.Device; discard adapter.request(
    descriptor                    = vaddr DeviceDescriptor(
      nextInChain                 : nil,
      label                       : "Hello Device".toStringView(),
      requiredFeatureCount        : 0,
      requiredFeatures            : nil,
      requiredLimits              : nil,
      defaultQueue                : QueueDescriptor(
        nextInChain               : nil,
        label                     : "Hello Default Queue".toStringView()
        ), #:: defaultQueue
      deviceLostCallbackInfo      : DeviceLostCallbackInfo(
        nextInChain               : nil,
        callback                  : deviceLostCB,
        userdata1                 : device.addr,
        userdata2                 : nil,
        ), #:: deviceLostCallback
      uncapturedErrorCallbackInfo : UncapturedErrorCallbackInfo(
        nextInChain               : nil,
        callback                  : errorCB,
        userdata1                 : device.addr,
        userdata2                 : nil,
        ), #:: uncapturedErrorCallbackInfo
      ), #:: DeviceDescriptor( ... )
    callbackInfo                  = RequestDeviceCallbackInfo(
      nextInChain                 : nil,
      mode                        : AllowSpontaneous,
      callback                    : deviceRequestCB,
      userdata1                   : device.addr,
      userdata2                   : nil,
      ) #:: callbackInfo
    ) #:: adapter.request( device )
  echo ":: Device Limits for this system: "
  let limits = device.limits()
  echo ":  ", $limits.repr
  echo ":: Device Features for this system: "
  for it in device.features(): echo ":  ",$it

  var shaderDesc    = wgsl.toDescriptor(shaderCode, label= "TriangleShader")
  let shader        = device.create(shaderDesc.addr)
  let surfaceFormat = caps.formats[0]
  let surfaceAlpha  = caps.alphaModes[0]
  let pipeline      = device.create(vaddr RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : "Render pipeline".toStringView(),
    layout                    : nil,
    vertex                    : VertexState(
      module                  : shader,
      entryPoint              : "vs_main".toStringView(),
      constantCount           : 0,
      constants               : nil,
      bufferCount             : 0,
      buffers                 : nil,
      ), #:: vertex
    primitive                 : PrimitiveState(
      nextInChain             : nil,
      topology                : PrimitiveTopology.TriangleList,
      stripIndexFormat        : IndexFormat.Undefined,
      frontFace               : FrontFace.CCW,
      cullMode                : CullMode.None,
      ), #:: primitive
    depthStencil              : nil,
    multisample               : MultisampleState(
      nextInChain             : nil,
      count                   : 1,
      mask                    : uint32.high,
      alphaToCoverageEnabled  : false.uint32,
      ), #:: multisample
    fragment                  : vaddr FragmentState(
      nextInChain             : nil,
      module                  : shader,
      entryPoint              : "fs_main".toStringView(),
      constantCount           : 0,
      constants               : nil,
      targetCount             : 1,
      targets                 : vaddr ColorTargetState(
        nextInChain           : nil,
        format                : surfaceFormat,
        blend                 : vaddr BlendState(
          alpha               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.One,
            dstFactor         : BlendFactor.Zero,
            ), #:: alpha
          color               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.One,
            dstFactor         : BlendFactor.Zero,
            ), #:: color
          ), #:: blend
        writeMask             : ColorWrite.All,
        ), #:: targets
      ), #:: fragment
    )) #:: pipeline

  # Surface Configuration (previously SwapChain Descriptor)
  var config = SurfaceConfiguration(
    nextInChain     : nil,
    device          : device,
    format          : surfaceFormat,
    usage           : wgpu.extras.TextureUsage.RenderAttachment,
    width           : 0,
    height          : 0,
    viewFormatCount : 0,
    viewFormats     : nil,
    alphaMode       : surfaceAlpha,
    presentMode     : Fifo,
    ) #:: SurfaceConfiguration
  # 7.3 Get the initial window size
  glfw.getWindowSize(window.ct, config.width.iaddr, config.height.iaddr)
  echo &":: Initial window size: {config.width} x {config.height}"
  surface.configure(config.addr)

  #__________________
  # Update loop
  while not window.close():
    # Input update from glfw
    window.update()

    # Get the Surface Texture
    var surfaceTexture :SurfaceTexture
    surface.getCurrentTexture(surfaceTexture.addr)
    case surfaceTexture.status
    of SuccessOptimal, SuccessSuboptimal: discard  # All good, could handle suboptimal this frame
    of Timeout, Outdated, Lost:
      # Re-configure the surface
      if surfaceTexture.texture != nil: surfaceTexture.texture.release()
      var prevWidth  = config.width
      var prevHeight = config.height
      glfw.getWindowSize(window.ct, config.width.iaddr, config.height.iaddr)
      if prevWidth != config.width or prevHeight != config.height:
        surface.configure(config.addr)
      # Skip this frame
      continue
    of OutOfMemory, DeviceLost, Error, Force32:
      echo $surfaceTexture.status, ": surface.getCurrentTexture() failed"
      system.quit(surfaceTexture.status.ord)
    doAssert surfaceTexture != SurfaceTexture(), "ERR:: Cannot acquire next swap chain texture"
    let nextTexture :TextureView= surfaceTexture.texture.create(nil)

    var encoder = device.create(vaddr CommandEncoderDescriptor(
      nextInChain  : nil,
      label        : "Hello Command Encoder".toStringView(),
      ))

    var renderPassDesc = RenderPassDescriptor(
      nextInChain             : nil,
      label                   : "Hello Render Pass".toStringView(),
      colorAttachmentCount    : 1,
      colorAttachments        : vaddr RenderPassColorAttachment(
        view                  : nextTexture,
        resolveTarget         : nil,
        loadOp                : Clear,
        storeOp               : Store,
        clearValue            : Color(r:0.1, g:0.1, b:0.1, a:1.0),  # WGPU Color, but similar to chroma/color
        ), #:: colorAttachments
      depthStencilAttachment  : nil,
      occlusionQuerySet       : nil,
      timestampWrites         : nil,
      ) #:: renderPassDesc
    var renderPass = encoder.begin(renderPassDesc.addr)
    # Draw into the texture with the given settings
    renderPass.set(pipeline)
    renderPass.draw(3,1,0,0)  # vertexCount, instanceCount, firstVertex, firstInstance
    renderPass.End()
    nextTexture.release()
    # Submit the Rendering Queue, and present it to the surface
    var queue     = device.getQueue()
    var cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(nextInChain: nil, label: "Hello Command Buffer".toStringView()))
    queue.submit(1, cmdBuffer.addr)
    let status = surface.present()  # like gl.swapBuffers()
    if status != Success: echo "ERR:: Surface.present() failed with: ", $status
    # Input update from glfw
    window.update()

  #__________________
  # Terminate
  window.term()
#__________________
when isMainModule: run()

