#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Instanced Cube Example
# Draws multiple textured cubes, using only one set of geometry.
#________________________________________________________________|
# std dependencies
import std/os
import std/strformat
import std/strutils
import std/sequtils
# External dependencies
from   pkg/nglfw as glfw import nil
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#__________________
var cam :Camera
#________________________________________________
# inputs.nim
#__________________
var i :Inputs  # Inputs state
# glfw Input Callbacks control the Inputs State
#__________________
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  let hold = action == glfw.Press or action == glfw.Repeat
  let rls  = action == glfw.Release
  if key == glfw.KeyEscape and action == glfw.Press:
    glfw.setWindowShouldClose(win, true)
  # Input manager: Update state
  case key
  of glfw.KeyW:
    if hold: i.fw = true elif rls: i.fw = false
  of glfw.KeyS:
    if hold: i.bw = true elif rls: i.bw = false
  of glfw.KeyA:
    if hold: i.lf = true elif rls: i.lf = false
  of glfw.KeyD:
    if hold: i.rt = true elif rls: i.rt = false
  of glfw.KeySpace:
    if action == glfw.Press: echo &"pos:{cam.pos}  trg:{cam.dir}"
  else: discard

#__________________
proc mousePos *(window :glfw.Window; xpos, ypos :float64) :void {.cdecl.}=
  ## GLFW Mouse Position Input Callback
  let chg = dvec2(xpos-i.cursor.pos.x, ypos-i.cursor.pos.y)  # Current - previous
  if chg < dvec2(10,10): i.cursor.chg += chg
  i.cursor.pos = dvec2(xpos, ypos)  # Store current x,y

#________________________________________________
# window.nim
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
  discard glfw.setCursorPosCallback(win.ct, mousePos)
  glfw.setInputMode(win.ct, glfw.Cursor, glfw.CursorDisabled)

#________________________________________________
# camera.nim
#__________________
const spd = 0.125'f
proc update (cam :var Camera) :void=
  # WASD movement
  if i.fw:  cam.move(cam.dir   * -spd)
  if i.bw:  cam.move(cam.dir   *  spd)
  if i.lf:  cam.move(cam.right * -spd)
  if i.rt:  cam.move(cam.right *  spd)
  # Mouse control
  cam.rotate(i.cursor.chg)
  i.cursor.chg = dvec2(0,0) # Reset after each frame

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

# NEW:
#__________________
# 1. Instances: Helpers
proc genInstances *[X,Y :static int](displ :DVec3) :array[X*Y, Mat4]=
  ## Generates the sequence of instance World transformations.
  var id :int= 0
  for col in 0..<X:
    for row in 0..<Y:
      # Find the world position of this instance
      let pos = dvec3(row.float64, 0.0, col.float64) - displ
      # Find the rotation of this instance
      var rot :DQuat
      if pos == dvec3(0,0,0):  rot = dvec3(0,1,1).fromAxisAngle(0)  # Avoid scaling to zero the instance at (0,0,0)
      else:                    rot = pos.normalize.fromAxisAngle(45)
      # Store the world matrix of the instance
      result[id] = mat4( pos.translate * rot.mat4() )
      id.inc
#__________________
# 2. Instances: Config
const instancePerRow = 10
const count          = ivec2(instancePerRow, instancePerRow)
const spacing        = 1.2
const displacement   = dvec3(count.x.float64*spacing, 0.0, count.y.float64*spacing)

#__________________
# 3. Cube Shader. The uniform W variable is now an array<mat4, 100>
const shaderCode = """
struct Uniforms {
  W     :array<mat4x4<f32>, $1>,  // NEW: The instance count is the array size of the u.W variable (aka 100, since we use a count of 10x10)
  V     :mat4x4<f32>,
  P     :mat4x4<f32>,
  time  :f32,
  color :vec4<f32>,
}
@group(0) @binding(0) var<uniform> u :Uniforms;

struct VertIn {
  @builtin(vertex_index)   id  :u32,
  @builtin(instance_index) iid :u32,  // NEW: Access to the instance.id
  @location(0) pos   :vec3<f32>,
  @location(1) color :vec4<f32>,
  @location(2) uv    :vec2<f32>,
  @location(3) norm  :vec3<f32>,
}
struct VertOut {
  @builtin(position) pos   :vec4<f32>,
  @location(0)       color :vec4<f32>,
  @location(1)       uv    :vec2<f32>,
  @location(2)       norm  :vec3<f32>,
}
@vertex fn vert(in :VertIn) ->VertOut {
  // Define the output of the vertex shader
  var out   :VertOut;
  out.pos   = u.P * u.V * u.W[in.iid] * vec4<f32>(in.pos, 1.0);  // NEW: We now access the W matrix by its instance.id
  out.color = in.color;  // Forward the color attribute to the fragment shader
  out.uv    = in.uv;     // Forward the texture coordinates to the fragment shader
  out.norm  = in.norm;   // Forward the vertex normal to the fragment shader
  return out;
}

@group(0) @binding(1) var texPixels  :texture_2d<f32>;
@group(0) @binding(2) var texSampler :sampler;

@fragment fn frag(in :VertOut) ->@location(0) vec4<f32> {
  return in.color * textureSample(texPixels, texSampler, in.uv);
}
""" % [$(count.x*count.y)]  # Replace $1 with our total instance count, for the instance count array

# Cube mesh with Deinterleaved vertex attributes
var cube = Mesh(
  pos: @[#  x    y    z
    vec3( -1, -1,  0 ),  # v0
    vec3(  1, -1,  0 ),  # v1
    vec3(  1, -1,  1 ),  # v2
    vec3( -1, -1,  1 ),  # v3
    vec3( -1,  1,  0 ),  # v4
    vec3(  1,  1,  0 ),  # v5
    vec3(  1,  1,  1 ),  # v6
    vec3( -1,  1,  1 ),  # v7
    ], # << pos
  color: @[#r   g    b    a
    vec4( 1, 0, 0, 1 ),  # v0
    vec4( 0, 1, 0, 1 ),  # v1
    vec4( 1, 0, 1, 1 ),  # v2
    vec4( 1, 1, 0, 1 ),  # v3
    vec4( 1, 0, 1, 1 ),  # v4
    vec4( 1, 1, 0, 1 ),  # v5
    vec4( 1, 1, 1, 1 ),  # v6
    vec4( 1, 1, 1, 1 ),  # v7
    ], # << color
  uv: @[#  u    v
    # NOTE: Incorrect (just placeholders)
    vec2( 1, 0 ),  # v0
    vec2( 0, 1 ),  # v1
    vec2( 1, 1 ),  # v2
    vec2( 0, 0 ),  # v3
    vec2( 1, 0 ),  # v4
    vec2( 0, 1 ),  # v5
    vec2( 1, 1 ),  # v6
    vec2( 0, 0 ),  # v7
    ], # << uv
  norm: @[
    # NOTE: Incorrect (just placeholders)
    vec3( 1, 0, 0 ),  # v0
    vec3( 0, 1, 0 ),  # v1
    vec3( 1, 0, 1 ),  # v2
    vec3( 1, 1, 0 ),  # v3
    vec3( 1, 0, 1 ),  # v4
    vec3( 1, 1, 0 ),  # v5
    vec3( 1, 1, 1 ),  # v6
    vec3( 1, 1, 1 ),  # v7
    ], # << norm
  inds: @[
    uvec3(0, 1, 2), uvec3(0, 2, 3),  # Bottom face
    uvec3(4, 5, 6), uvec3(4, 6, 7),  # Top    face
    uvec3(3, 2, 6), uvec3(3, 6, 7),  # Front  face
    uvec3(1, 0, 4), uvec3(1, 4, 5),  # Back   face
    uvec3(3, 0, 7), uvec3(0, 7, 4),  # Left   face
    uvec3(2, 1, 6), uvec3(1, 6, 5),  # Right  face
    ] # << inds
  ) # << Mesh()
let vertc = cube.vertCount.int
doAssert vertc == cube.color.len and 
         vertc == cube.uv.len and 
         vertc == cube.norm.len,
         "All attributes must contain the same amount of vertex"

# Create the texture data
const width  :uint32=  512
const height :uint32=  512
var   pixels :Pixels=  genTexture(width, height)


#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu Tut",
  w:960, h:540,
  )
type Uniforms = object          # Our uniform value is a struct
  W      {.align(16).}:array[count.x*count.y, Mat4]  # Local-to-World matrix
  V      {.align(16).}:Mat4     # World-to-View matrix
  P      {.align(16).}:Mat4     # View-to-Projection matrix
  time   {.align(16).}:float32  # Time in seconds
  color  {.align(16).}:Vec4     # Uniform color
var u :Uniforms
static: assert Uniforms.sizeof mod Vec4.sizeof == 0, "Uniforms size must be aligned to the size of a vec4<f32>"
# 4. Generate the instances World matrices
u.W = genInstances[count.x, count.y](displacement)


#________________________________________________
# Entry Point
#__________________
proc run=
  #__________________
  # Init Window
  echo "Hello Instanced cube"
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

  # Set the limits that we require for this example
  var requiredLimits = RequiredLimits(
    nextInChain           : nil,
    limits                : Limits.new(  # With custom `new` proc because some required defaults are not 0
      maxVertexAttributes = 4,
      maxVertexBuffers    = 5,
      # Change limits for the one uniform value we upload.
      maxBindGroups                   = 1,
      maxUniformBuffersPerShaderStage = 1,
      maxUniformBufferBindingSize     = uint64( sizeof(Uniforms) ),  # max uniform buffer binding size is the size of our object
      ), # << limits
    ) # << requiredLimits

  # Create the device descriptor, with our custom limits
  var deviceDesc = DeviceDescriptor(
    nextInChain            : nil,
    label                  : "Hello Device",
    requiredFeaturesCount  : 0,
    requiredFeatures       : nil,
    requiredLimits         : requiredLimits.addr,
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

  # Read the vertex attributes and buffers limits of the system
  echo ":: Supported limits:   (after setting RequiredLimits)"
  var supportedLimits :SupportedLimits
  discard adapter.get(supportedLimits.addr)
  echo ": adapter.maxVertexAttributes: ",supportedLimits.limits.maxVertexAttributes
  discard device.get(supportedLimits.addr)
  echo ": device.maxVertexAttributes:  ",supportedLimits.limits.maxVertexAttributes
  # When setting the required limits to 0 (unlimited), my system says:
  # > adapter.maxVertexAttributes: 32
  # > device.maxVertexAttributes:  16

  # Get the queue, so we can add commands to it
  var queue = device.getQueue()

  # Create the shader and swapchain
  var shaderDesc      = shaderCode.wgslToDescriptor(label = "cubeShader")
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

  # Create and upload all the cube buffers. Before we just uploaded the position.
  var cubeLayout :seq[VertexBufferLayout]
  var cubeAttr   :seq[VertexAttribute]
  var cubeBuffer = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "cube Vertex buffer".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.vertex, BufferUsage.index},
    size              : cube.size,
    mappedAtCreation  : false,
    )) # << device.createBuffer()
  # Write the indices to the cube buffer
  var offset :uint64= 0
  queue.write(cubeBuffer, offset, cube.inds[0].addr, cube.inds.size)
  offset += cube.inds.size

  # Positions
  cubeLayout.add VertexBufferLayout(
    arrayStride       : cube.pos[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
      attributes      : vaddr VertexAttribute(
      format          : VertexFormat.float32x3,
      offset          : 0,
      shaderLocation  : Attr.pos,
      ) # << posAttr
    ) # << posLayout
  # Write cube.position at cubeBuffer offset 0
  queue.write(cubeBuffer, offset, cube.pos[0].addr, cube.pos.size)
  offset += cube.pos.size

  # Colors
  cubeLayout.add VertexBufferLayout(
    arrayStride       : cube.color[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x4,
      offset          : 0,
      shaderLocation  : Attr.color,
      ) # << colorAttr
    ) # << colorLayout
  # Write cube.color at cubeBuffer offset = cube.pos.size
  queue.write(cubeBuffer, offset, cube.color[0].addr, cube.color.size)
  offset += cube.color.size

  # Texture coordinates
  cubeLayout.add VertexBufferLayout(
    arrayStride       : cube.uv[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x2,
      offset          : 0,
      shaderLocation  : Attr.uv,
      ) # << uvAttr
    ) # << uvLayout
  # Write cube.uv at cubeBuffer offset = cube.color.size
  queue.write(cubeBuffer, offset, cube.uv[0].addr, cube.uv.size)
  offset += cube.uv.size

  # Normals
  cubeLayout.add VertexBufferLayout(
    arrayStride       : cube.norm[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x3,
      offset          : 0,
      shaderLocation  : Attr.norm,
      ) # << normAttr
    ) # << normLayout
  # Write cube.norm at cubeBuffer offset = cube.uv.size
  queue.write(cubeBuffer, offset, cube.norm[0].addr, cube.norm.size)
  offset += cube.norm.size

  # Create the Uniform Buffer that will hold the variable, and upload the initial data
  # Specify the size for our Uniforms object
  var uniformBuffer = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Uniform buffer".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.uniform},  # Mark the buffer as a Uniform Buffer
    size              : uint64( sizeof(Uniforms) ), # The buffer will contain the Uniforms struct
    mappedAtCreation  : false,
    )) # << device.createBuffer()
  u.time  = glfw.getTime().float32
  # Define the uniform color, and upload the object data instead of a single float.
  u.color = vec4(0,1,0,1)

  # Create the camera
  cam = Camera.new(
    origin = dvec3(-3,-4,-6),
    target = dvec3(1,-1,1),
    up     = dvec3(0,1,0),
    fov    = 45.0,  # 90 degree vertical fov
    near   = 0.1,
    far    = 100.0,
    )
  # Generate the VP matrices
  u.V = cam.view().mat4()                            # Get the view matrix from the camera
  u.P = cam.proj(config.width/config.height).mat4()  # Get the proj matrix from the camera, based on the current screen size

  # Upload the Uniforms data
  queue.write(uniformBuffer, 0, u.addr, sizeof(Uniforms).csize_t)

  # Create the BindGroupLayoutEntries for both the Uniforms object and the texture
  # NOTE: Fully verbose, but such verbosity is not needed.
  #     : Modified variables are commented, and the rest would be correctly given by Nim's zero initialization if omitted.
  var bindGroupLayoutEntries :seq[BindGroupLayoutEntry]
  # Create the BindGroup Layout
  # Specify the bindGroup as accesible by the vertex and fragment stages
  # Mark the minimum binding size as the size of our Uniforms object
  bindGroupLayoutEntries.add BindGroupLayoutEntry(
    nextInChain        : nil,
    binding            : 0,                           # Shader @binding(0) index
    visibility         : { ShaderStage.vertex, ShaderStage.fragment }, # Used in both vertex and fragment stages
    buffer             : BufferBindingLayout(
      nextInChain      : nil,
      typ              : BufferBindingType.uniform,   # Mark the buffer for usage as a uniform
      hasDynamicOffset : false,
      minBindingSize   : uint64( sizeof(Uniforms) ),  # Minimum size for uploaded values is now the size of the object
      ), # << buffer
    # Not Used. Could be Zero-Initalizated instead of explicit.
    sampler            : SamplerBindingLayout(
      nextInChain      : nil,
      typ              : SamplerBindingType.undefined,
      ), # << sampler
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

  # Assign the BindGroupLayoutEntries to the Layout, including the Sampler entry
  var bindGroupLayout = device.create(vaddr BindGroupLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello Uniform BindGroupLayout".cstring,
    entryCount           : bindGroupLayoutEntries.len.uint32,
    entries              : bindGroupLayoutEntries[0].addr,
    )) # << device.createBindGroupLayout()

  # Create the PipelineLayout, with our bindGroupLayout as input
  var layout = device.create(vaddr PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello PipelineLayout".cstring,
    bindGroupLayoutCount : 1,
    bindGroupLayouts     : bindGroupLayout.addr,
    )) # << device.createPipelineLayout()

  # Define the depth texture format
  var depthTextureFormat = TextureFormat.Depth24Plus
  # Configure the pipeline with the buffer inputs
  let pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain              : nil,
    label                    : "Render pipeline".cstring,
    layout                   : layout,
    vertex                   : VertexState(
      module                 : shader,
      entryPoint             : "vert".cstring,
      constantCount          : 0,
      constants              : nil,
      bufferCount            : cubeLayout.len.uint32,
      buffers                : cubeLayout[0].addr,
      ), # << vertex
    primitive                : PrimitiveState(
      nextInChain            : nil,
      topology               : PrimitiveTopology.triangleList,
      stripIndexFormat       : IndexFormat.undefined,
      frontFace              : FrontFace.ccw,
      cullMode               : CullMode.none,
      ), # << primitive
    # Setup the Z-Buffer options
    depthStencil             : vaddr DepthStencilState(
      nextInChain            : nil,
      format                 : depthTextureFormat,    # Assign the depth format to the pipeline
      depthWriteEnabled      : true,                  # If fragment passes the test, its depth is stored as the new value
      depthCompare           : CompareFunction.less,  # Blend fragment if its depth is less than the current value of the z-buffer
      # Not Used. Could be Zero-Initalizated instead of explicit.
      stencilFront           : StencilFaceState(
        compare              : CompareFunction.always,
        failOp               : StencilOperation.keep,
        depthFailOp          : StencilOperation.keep,
        passOp               : StencilOperation.keep,
        ), # << stencilFront
      stencilBack            : StencilFaceState(
        compare              : CompareFunction.always,
        failOp               : StencilOperation.keep,
        depthFailOp          : StencilOperation.keep,
        passOp               : StencilOperation.keep,
        ), # << stencilBack
      stencilReadMask        : 0,  # Stencil disabled
      stencilWriteMask       : 0,  # Stencil disabled
      depthBias              : 0,
      depthBiasSlopeScale    : 0.cfloat,
      depthBiasClamp         : 0.cfloat,
      ), # << depthStencil
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

  # Create the BindGroup, with both our texture and uniform objects.
  # The size of the gpu buffer is the size of our Uniforms object
  var bindGroupEntries :seq[BindGroupEntry]
  # Create the Uniforms entry, and add it to the list of entries
  bindGroupEntries.add BindGroupEntry(
    nextInChain : nil,
    binding     : 0,                          # Shader @binding(0) index
    buffer      : uniformBuffer,              # Buffer that contains the data for this binding
    offset      : 0,                          # Offset within the buffer (useful for storing multiple blocks in the same buffer)
    size        : uint64( sizeof(Uniforms) ), # Size of the buffer is now the size of the object
    sampler     : nil,
    textureView : nil,
    ) # << Uniforms entry

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
    # Update the camera at the beginning of the frame   (input polling moved to the start of the frame)
    window.update()  # ... camera needs updated glfw.pollEvents(), inside the input callbacks. Should be separate in a real app.
    cam.update()     # Update the camera position and view

    # Update time and write it to the uniform buffer value
    u.time = glfw.getTime().float32
    queue.write(uniformBuffer, Uniforms.offsetOf(time).uint64, u.time.addr, sizeof(float32).csize_t)

    # Continue the update loop
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

    # Generate the current frame VP matrices  (after the window size has been updated, for the projection)
    u.V = cam.view().mat4()                            # Get the view matrix from the camera
    u.P = cam.proj(config.width/config.height).mat4()  # Get the proj matrix from the camera, based on the current screen size
    # Upload the new values
    queue.write(uniformBuffer, Uniforms.offsetOf(V).uint64, u.V[0,0].addr, sizeof(Mat4).csize_t)
    queue.write(uniformBuffer, Uniforms.offsetOf(P).uint64, u.P[0,0].addr, sizeof(Mat4).csize_t)

    # Setup the command buffer
    var encoder = device.create(vaddr CommandEncoderDescriptor(
      nextInChain  : nil,
      label        : "Hello Command Encoder".cstring,
      ))
    # Create the depth texture
    var depthTexture = device.create(vaddr TextureDescriptor(
      nextInChain     : nil,
      label           : "Hello Depth Texture".cstring,
      usage           : { TextureUsage.renderAttachment },
      dimension       : TextureDimension.dim2D,
      size            : Extent3D(width:config.width, height:config.height, depthOrArrayLayers:1),
      format          : depthTextureFormat,
      mipLevelCount   : 1,
      sampleCount     : 1,
      viewFormatCount : 1,
      viewFormats     : depthTextureFormat.addr,
      )) # << device.createTexture()

    # Create the depth texture view
    var depthTextureView = depthTexture.create(vaddr TextureViewDescriptor(
      nextInChain     : nil,
      label           : "Hello DepthView".cstring,
      format          : depthTextureFormat,
      dimension       : TextureViewDimension.dim2D,
      baseMipLevel    : 0,
      mipLevelCount   : 1,
      baseArrayLayer  : 0,
      arrayLayerCount : 1,
      aspect          : TextureAspect.depthOnly,
      )) # << depthTexture.createView()

    # Create the render pass, including our depth texture
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
      # Include our depth attachment
      depthStencilAttachment  : vaddr RenderPassDepthStencilAttachment(
        view                  : depthTextureView,  # Attach the depth view
        depthLoadOp           : LoadOp.clear,      # Similar to the color attachment
        depthStoreOp          : StoreOp.store,     # Similar to the color attachment
        depthClearValue       : 1.float32,         # Initial value of the depth buffer (far)
        depthReadOnly         : false,             # Optional: true means disable depth write
        # Stencil disabled
        stencilLoadOp         : LoadOp.clear,
        stencilStoreOp        : StoreOp.store,
        stencilClearValue     : 0,
        stencilReadOnly       : true,
        ), # << depthStencilAttachment
      occlusionQuerySet       : nil,
      timestampWriteCount     : 0,
      timestampWrites         : nil,
      )) # << renderPass

    # Draw into the texture with the given settings
    renderPass.set(pipeline)
    # Set the vertex buffer in the RenderPass
    # NOTE : The rendering code shouldn't care about buffer order. The position buffer could be at the end, or at the beginning
    #        this part of the code shouldn't rely on the order. It should just have a slice that it can bind
    offset = 0
    # Set the Index block of the buffer in the renderPass
    renderPass.setIndexBuffer(cubeBuffer, IndexFormat.Uint32, offset, cube.inds.size); offset += cube.inds.size
    # Set the vertex attributes buffer
    renderPass.setVertexBuffer(0, cubeBuffer, offset, cube.pos.size)   ; offset += cube.pos.size
    renderPass.setVertexBuffer(1, cubeBuffer, offset, cube.color.size) ; offset += cube.color.size
    renderPass.setVertexBuffer(2, cubeBuffer, offset, cube.uv.size)    ; offset += cube.uv.size
    renderPass.setVertexBuffer(3, cubeBuffer, offset, cube.norm.size)  ; offset += cube.norm.size

    # Set the binding group in the renderPass
    renderPass.set(0, bindGroup, 0, nil)  # Set the `bindGroup` at @group(0), with no dynamic offsets (0, nil)

    # NEW:
    # 5. Draw using the indexed version, and pass the instance count
    renderPass.draw(cube.indsCount, uint32( count.x*count.y ), 0,0,0)  # vertexCount, instanceCount, firstVertex, baseVertex, firstInstance

    # OLD: Finish drawing
    renderPass.End()
    nextTexture.release()
    depthTexture.release()
    depthTextureView.release()
    # Submit the Rendering Queue, and present it to the surface
    var cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
      nextInChain : nil,
      label       : "Hello Command Buffer".cstring,
      )) # << encoder.finish()
    queue.submit(1, cmdBuffer.addr)
    swapChain.present()  # like gl.swapBuffers()

  #__________________
  # Terminate
  window.term()

#__________________
when isMainModule: run()

