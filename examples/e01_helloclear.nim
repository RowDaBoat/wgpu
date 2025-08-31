#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Most minimal swapchain setup possible.          |
# No shaders. Just clears the screen to a color.  |
#_________________________________________________|
# std dependencies
import std/strformat
import std/os
# External dependencies
from pkg/nglfw as glfw import nil
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#________________________________________________
# window.nim
#__________________
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  if (key == glfw.KeyEscape and action == glfw.Press):
    glfw.setWindowShouldClose(win, true)

#_______________________________________
# @section WGPU callbacks
#_____________________________
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


#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu Tut",
  w:960, h:540,
  )

# WGPU state
var instance :wgpu.Instance= nil

#________________________________________________
# Entry Point
#__________________
proc run=
  #__________________
  # Init Window
  echo "Hello wgpu"
  window.init(key)

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set Warn
  #__________________
  # Init wgpu
  # 1. Create the Instance
  instance = wgpu.create(vaddr wgpu.InstanceDescriptor(nextInChain: nil))
  doAssert instance != nil, "Could not initialize wgpu"

  # 2 Create the Surface
  var surface = instance.getSurface(window.ct)

  # 3. Create the Adapter
  var adapter :wgpu.Adapter; discard instance.request(
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

  # 4. Report the Adapter Features + Capabilities supported
  echo ":: Adapter Features supported by this system: "
  for it in adapter.features():
    echo $it.ord&":  ",$it
  echo ":: Capabilities of the Surface supported by this system: "
  let (textureFormats, presentModes, alphaModes) = surface.capabilities(adapter)
  echo ":  Texture Formats:"
  for formt in textureFormats: echo ":  - ",$formt
  echo ":  Present Modes:"
  for prsnt in presentModes:   echo ":  - ",$prsnt
  echo ":  Alpha Modes:"
  for alpha in presentModes:   echo ":  - ",$alpha

  # 5. Create the Device
  var device :wgpu.Device; discard adapter.request(
    descriptor = vaddr DeviceDescriptor(
      nextInChain            : nil,
      label                  : "Hello Device".toStringView(),
      requiredFeatureCount   : 0,
      requiredFeatures       : nil,
      requiredLimits         : nil,
      defaultQueue           : QueueDescriptor(
        nextInChain          : nil,
        label                : "Hello Default Queue".toStringView()
        ), #:: defaultQueue
      deviceLostCallbackInfo : DeviceLostCallbackInfo(
        nextInChain          : nil,
        callback             : deviceLostCB,
        userdata1            : device.addr,
        userdata2            : nil,
        ), #:: deviceLostCallback
      uncapturedErrorCallbackInfo : UncapturedErrorCallbackInfo(
        nextInChain          : nil,
        callback             : errorCB,
        userdata1            : device.addr,
        userdata2            : nil,
        ), #:: uncapturedErrorCallback
      ), #:: DeviceDescriptor( ... )
    callbackInfo = RequestDeviceCallbackInfo(
      nextInChain          : nil,
      mode                 : AllowSpontaneous,
      callback             : deviceRequestCB,
      userdata1            : device.addr,
      userdata2            : nil,
      ) #:: RequestDeviceCallbackInfo
    ) #:: adapter.request( ... )

  # 6. Get the device queue
  var queue = device.getQueue()


  # 7. Configure the Surface  (replaces SwapChain creation entirely)
  # 7.1 Get the SurfaceCapabilities
  let caps = surface.capabilities(adapter)  # wgpuSurfaceGetCapabilities

  # 7.2. Create the Surface Configuration (previously SwapChain Descriptor)
  var config = SurfaceConfiguration(
    nextInChain     : nil,
    device          : device,
    format          : caps.textureFormats[0],
    usage           : TextureUsage 0x0000000000000010, # TextureUsage_RenderAttachment,  # TODO: Futhark does not give these variable a value
    width           : 0,
    height          : 0,
    viewFormatCount : 0,
    viewFormats     : nil,
    alphaMode       : caps.alphaModes[0],
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

    # 5. Get the swapChain TextureView.
    var surfaceTexture :SurfaceTexture
    surface.getCurrentTexture(surfaceTexture.addr)
    # Attempt to get the SurfaceTexture. It's a fallible operation by spec, so need to check for errors.
    case surfaceTexture.status
    of SuccessOptimal, SuccessSuboptimal:
      # All good, could handle suboptimal this frame
      discard
    of Timeout, Outdated, Lost:
      # 5.1 Re-configure the surface
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

    # 6. Create the Command Encoder
    var encoderDesc = CommandEncoderDescriptor(
      nextInChain  : nil,
      label        : "Command Encoder".toStringView(),
      )
    var encoder = device.create(encoderDesc.addr)
    # 7. Create the RenderPass
    var renderPassDesc = RenderPassDescriptor(
      nextInChain             : nil,
      label                   : "Hello Render Pass".toStringView(),
      colorAttachmentCount    : 1,
      colorAttachments        : vaddr RenderPassColorAttachment(
        view                  : nextTexture,
        resolveTarget         : nil,
        loadOp                : Clear,
        storeOp               : Store,
        clearValue            : Color(r:1.0, g:0.0, b:0.0, a:1.0),  # WGPU Color, but similar to chroma/color
        ), #:: colorAttachments
      depthStencilAttachment  : nil,
      occlusionQuerySet       : nil,
      timestampWrites         : nil,
      ) #:: renderPassDesc
    var renderPass = encoder.begin(renderPassDesc.addr)
    # 8. Draw into the texture with the given settings, and finalize the pass.
    renderPass.End()
    # 9. Submit the Rendering Queue
    var cmdBufferDesc = CommandBufferDescriptor(
      nextInChain : nil,
      label       : "Hello Command Buffer".toStringView(),
      ) #:: cmdBufferDesc
    var cmdBuffer = encoder.finish(cmdBufferDesc.addr)
    queue.submit(1, cmdBuffer.addr)
    # 10. Present the next surface texture on the screen.
    discard surface.present()  # like gl.swapBuffers()
    # 11. Release the resources
    renderPass.release()
    encoder.release()
    nextTexture.release()
    cmdBuffer.release()
    surfaceTexture.texture.release()

  #__________________
  # Terminate
  queue.release()
  device.release()
  adapter.release()
  surface.release()
  instance.release()
  window.term()
#__________________
when isMainModule: run()

