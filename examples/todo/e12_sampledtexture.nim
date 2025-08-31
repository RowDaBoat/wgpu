#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Sampled Texture example                         |
# Our byte array can be sampled from the shader.  |
#_________________________________________________|
# std dependencies
import std/os
import std/strformat
import std/sequtils
# External dependencies
from   pkg/nglfw as glfw import nil
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#________________________________________________
# types.nim
#__________________
type Vec2 = object
  x,y :float32
type Vec3 = object
  x,y,z :float32
type Vec4 = object
  x,y,z,w :float32
type UVec3 = object
  x,y,z :uint32
proc vec2  (x,y :SomeNumber)     :Vec2=   Vec2(x:x.float32, y:y.float32)
proc vec3  (x,y,z :SomeNumber)   :Vec3=   Vec3(x:x.float32, y:y.float32, z:z.float32)
proc vec4  (x,y,z,w :SomeNumber) :Vec4=   Vec4(x:x.float32, y:y.float32, z:z.float32, w:w.float32)
proc uvec3 (x,y,z :SomeNumber)   :UVec3=  UVec3(x:x.uint32, y:y.uint32, z:z.uint32)

type Window * = object
  ct     *:glfw.Window
  w,h    *:int32
  title  *:string

type Mesh * = object
  pos    *:seq[Vec3]
  color  *:seq[Vec4]
  uv     *:seq[Vec2]
  norm   *:seq[Vec3]
  inds   *:seq[UVec3]

type Color8 = object
  r,g,b,a :uint8
type Pixels = seq[Color8]

#________________________________________________
# mesh.nim
#__________________
type Attr *{.pure.}= enum pos, color, uv, norm
  ## Attribute location ids for the shader
converter toInt *(attr :Attr) :uint32=  uint32( attr.ord )
  ## Automatically convert to int when required, without needing to add `.ord` everywhere.
converter toCsize *(n :SomeUnsignedInt) :csize_t=  n.csize_t
  ## Automatically convert unsigned integers to csize_t when required, without needing to specify with `.csize_t`.
func vertCount *(m :Mesh) :uint32=  uint32( m.pos.len )
  ## Returns the mesh vertex count, based on the number of vertex positions.
func indsCount *(m :Mesh) :uint32=  uint32( m.inds.len * 3)
  ## Returns the mesh index count, based on the indices data. Assumes meshes are triangulated (aka 3 vertex per entry).
func size *[T](n :T)      :uint64=  uint64( sizeof(n) )
  ## Returns the size in bytes of the given type. Alias for sizeof()
func size *[T](v :seq[T]) :uint64=  uint64( v.len * sizeof(v[0]) )
  ## Returns the size in bytes of the given seq
func size *(m :Mesh) :uint64=
  ## Returns the size in bytes of the given mesh
  for attr in m.fields:
    if attr.len > 0:  result += attr.size   # Do not add empty seq


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
struct Uniforms {
  time  :f32,
  color :vec4<f32>,
}
@group(0) @binding(0) var<uniform> u :Uniforms;

struct VertIn {
  @builtin(vertex_index) id :u32,
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
  // Add the uniform variable to the position of this vertex
  let offset = 0.3 * vec3<f32>(cos(u.time), sin(u.time), 0.0);  // Calculate the (x,y) offset
  let pos    = in.pos + offset;                                 // Move the vertex position using the offset
  // Define the output of the vertex shader
  var out   :VertOut;
  out.pos   = vec4<f32>(pos, 1.0);
  out.color = in.color;  // Forward the color attribute to the fragment shader
  out.uv    = in.uv;     // Forward the texture coordinates to the fragment shader
  out.norm  = in.norm;   // Forward the vertex normal to the fragment shader
  return out;
}

@group(0) @binding(1) var tex :texture_2d<f32>;
// NEW: We now have access to the sampler at @binding(2) in the fragment stage
@group(0) @binding(2) var texSampler :sampler;

@fragment fn frag(in :VertOut) ->@location(0) vec4<f32> {
  // return vec4<f32>(u.color.r, u.color.g, u.color.b, in.color.a);
  // return textureLoad(tex, vec2<i32>(in.pos.xy), 0);
  return textureSample(tex, texSampler, in.uv);  // NEW: We now sample the texture directly
}
"""

# This example uses a deinterleaved vertex attribute buffer.
# A simpler to understand version can be achieved by using an ArrayOfStructs format, which would interleave the data for each vertex
# eg:   const triangle =  @[  Vertex( pos:vec3(0,0,0), color:vec4(1,1,1,1) ),  Vertex(...),  etc ...  ]
var triangle = Mesh(
  pos: @[#  x    y    z
    vec3( -0.5, -0.5, 0.0 ),  # v0
    vec3(  0.5, -0.5, 0.0 ),  # v1
    vec3(  0.0,  0.5, 0.0 ),  # v2
    ], # << pos
  color: @[#r   g    b    a
    vec4( 1.0, 0.0, 0.0, 1.0 ),  # v0
    vec4( 0.0, 1.0, 0.0, 1.0 ),  # v1
    vec4( 0.0, 0.0, 1.0, 1.0 ),  # v2
    ], # << color
  uv: @[#  u    v
    vec2( 1.0, 0.0 ),  # v0
    vec2( 0.0, 0.0 ),  # v1
    vec2( 0.0, 1.0 ),  # v2
    ], # << uv
  norm: @[
    vec3( 1.0, 0.0, 0.0 ),  # v0
    vec3( 0.0, 1.0, 0.0 ),  # v1
    vec3( 0.0, 0.0, 1.0 ),  # v2
    ], # norm
  inds: @[uvec3(0,1,2)]
  ) # << Mesh()
let vertc = triangle.vertCount.int
doAssert vertc == triangle.color.len and 
         vertc == triangle.uv.len and 
         vertc == triangle.norm.len,
         "All attributes must contain the same amount of vertex"
# NEW:
# Create the texture data
const width  :uint32=  512
const height :uint32=  512
var   pixels :Pixels=  newSeqWith[Color8](int(width*height), Color8(r:255, g:255, b:255, a:255))

#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu Tut",
  w:960, h:540,
  )
type Uniforms = object         # Our uniform value is now a struct
  time  {.align(16).}:float32  # Mark as align(16) in this variable is not needed, since its 0. Just for clarity
  color {.align(16).}:Vec4     # Mark as align(16), so that the time field gets padded.
var u :Uniforms
static: assert Uniforms.sizeof mod Vec4.sizeof == 0, "Uniforms size must be aligned to the size of a vec4<f32>"

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

  # Create and upload all the triangle buffers. Before we just uploaded the position.
  var triangleLayout :seq[VertexBufferLayout]
  var triangleAttr   :seq[VertexAttribute]
  var triangleBuffer = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Triangle Vertex buffer".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.vertex, BufferUsage.index},
    size              : triangle.size,
    mappedAtCreation  : false,
    )) # << device.createBuffer()
  # Write the indices to the triangle buffer
  var offset :uint64= 0
  queue.write(triangleBuffer, offset, triangle.inds[0].addr, triangle.inds.size)
  offset += triangle.inds.size

  # Positions
  triangleLayout.add VertexBufferLayout(
    arrayStride       : triangle.pos[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
      attributes      : vaddr VertexAttribute(
      format          : VertexFormat.float32x3,
      offset          : 0,
      shaderLocation  : Attr.pos,
      ) # << posAttr
    ) # << posLayout
  # Write triangle.position at triangleBuffer offset 0
  queue.write(triangleBuffer, offset, triangle.pos[0].addr, triangle.pos.size)
  offset += triangle.pos.size

  # Colors
  triangleLayout.add VertexBufferLayout(
    arrayStride       : triangle.color[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x4,
      offset          : 0,
      shaderLocation  : Attr.color,
      ) # << colorAttr
    ) # << colorLayout
  # Write triangle.color at triangleBuffer offset = triangle.pos.size
  queue.write(triangleBuffer, offset, triangle.color[0].addr, triangle.color.size)
  offset += triangle.color.size

  # Texture coordinates
  triangleLayout.add VertexBufferLayout(
    arrayStride       : triangle.uv[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x2,
      offset          : 0,
      shaderLocation  : Attr.uv,
      ) # << uvAttr
    ) # << uvLayout
  # Write triangle.uv at triangleBuffer offset = triangle.color.size
  queue.write(triangleBuffer, offset, triangle.uv[0].addr, triangle.uv.size)
  offset += triangle.uv.size

  # Normals
  triangleLayout.add VertexBufferLayout(
    arrayStride       : triangle.norm[0].size,
    stepMode          : VertexStepMode.vertex,
    attributeCount    : 1,
    attributes        : vaddr VertexAttribute(
      format          : VertexFormat.float32x3,
      offset          : 0,
      shaderLocation  : Attr.norm,
      ) # << normAttr
    ) # << normLayout
  # Write triangle.norm at triangleBuffer offset = triangle.uv.size
  queue.write(triangleBuffer, offset, triangle.norm[0].addr, triangle.norm.size)
  offset += triangle.norm.size

  # Create the Uniform Buffer that will hold the variable, and upload the initial data
  # Specify the size for our Uniforms object
  var uniformBuffer = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Uniform buffer".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.uniform},  # Mark the buffer as a Uniform Buffer
    size              : uint64( sizeof(Uniforms) ), # NEW: The buffer will contain the Uniforms struct
    mappedAtCreation  : false,
    )) # << device.createBuffer()
  u.time  = glfw.getTime().float32
  # Define the uniform color, and upload the object data instead of a single float.
  u.color = vec4(0,1,0,1)
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
    visibility         : { ShaderStage.vertex, ShaderStage.fragment }, # NEW: Used in both vertex and fragment stages
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
    binding            : 1,                        # NEW: Shader @binding(1) index
    visibility         : { ShaderStage.fragment }, # NEW: Used in the fragment stage
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
      typ              : SamplerBindingType.nonFiltering,  # NEW: Set filter to none
      ), # << sampler
    texture            : TextureBindingLayout(
      nextInChain      : nil,
      sampleType       : TextureSampleType.Float,          # NEW: Set the color type to float
      viewDimension    : TextureViewDimension.dim2D,       # NEW: Make it a 2D texture
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

  # NEW:
  # 1. Create the Sampler BindGroup entry
  bindGroupLayoutEntries.add BindGroupLayoutEntry(
    nextInChain        : nil,
    binding            : 2,                        # NEW: Shader @binding(2) index
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
      typ              : SamplerBindingType.filtering,  # NEW: Set filtering
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

  # 2. Assign the BindGroupLayoutEntries to the Layout, including the new Sampler entry
  var bindGroupLayout = device.create(vaddr BindGroupLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello Uniform BindGroupLayout".cstring,
    entryCount           : bindGroupLayoutEntries.len.uint32,
    entries              : bindGroupLayoutEntries[0].addr,
    )) # << device.createBindGroupLayout()

  # OLD: Create the PipelineLayout, with our bindGroupLayout as input
  var layout = device.create(vaddr PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : "Hello PipelineLayout".cstring,
    bindGroupLayoutCount : 1,
    bindGroupLayouts     : bindGroupLayout.addr,
    )) # << device.createPipelineLayout()

  # Configure the pipeline with the buffer inputs
  let pipeline = device.create(vaddr RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : "Render pipeline".cstring,
    layout                    : layout,
    vertex                    : VertexState(
      module                  : shader,
      entryPoint              : "vert".cstring,
      constantCount           : 0,
      constants               : nil,
      bufferCount             : triangleLayout.len.uint32,
      buffers                 : triangleLayout[0].addr,
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

  # Create the BindGroup, with both our texture and uniform objects.
  var bindGroupEntries :seq[BindGroupEntry]
  # Create the Uniforms entry, and add it to the list of entries
  # The size of the gpu buffer is the size of our Uniforms object
  bindGroupEntries.add BindGroupEntry(
    nextInChain : nil,
    binding     : 0,                          # Shader @binding(0) index
    buffer      : uniformBuffer,              # Buffer that contains the data for this binding
    offset      : 0,                          # Offset within the buffer (useful for storing multiple blocks in the same buffer)
    size        : uint64( sizeof(Uniforms) ), # NEW: Size of the buffer is now the size of the object
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

  # 3. Create the sampler
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
  # 4. Create the sampler BindGroupEntry
  bindGroupEntries.add BindGroupEntry(
    nextInChain : nil,
    binding     : 2,   # Shader @binding(2) index
    buffer      : nil,
    offset      : 0,
    size        : 0,
    sampler     : sampler, # Add the sampler to the entry
    textureView : nil,
    ) # << Sampler entry

  # OLD: Create the BindGroup
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
    var encoder = device.create(vaddr CommandEncoderDescriptor(
      nextInChain  : nil,
      label        : "Command Encoder",
      )) # << device.createEncoder( ... )
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
    # Set the vertex buffer in the RenderPass
    # NOTE : The rendering code shouldn't care about buffer order. The position buffer could be at the end, or at the beginning
    #        this part of the code shouldn't rely on the order. It should just have a slice that it can bind
    offset = 0
    # Set the Index block of the buffer in the renderPass
    renderPass.setIndexBuffer(triangleBuffer, IndexFormat.Uint32, offset, triangle.inds.size); offset += triangle.inds.size
    # Set the vertex attributes buffer
    renderPass.setVertexBuffer(0, triangleBuffer, offset, triangle.pos.size)   ; offset += triangle.pos.size
    renderPass.setVertexBuffer(1, triangleBuffer, offset, triangle.color.size) ; offset += triangle.color.size
    renderPass.setVertexBuffer(2, triangleBuffer, offset, triangle.uv.size)    ; offset += triangle.uv.size
    renderPass.setVertexBuffer(3, triangleBuffer, offset, triangle.norm.size)  ; offset += triangle.norm.size

    # Set the binding group in the renderPass
    renderPass.set(0, bindGroup, 0, nil)  # Set the `bindGroup` at @group(0), with no dynamic offsets (0, nil)

    # Draw using the indexed version
    renderPass.draw(triangle.indsCount, 1,0,0,0)  # vertexCount, instanceCount, firstVertex, baseVertex, firstInstance
    # Finish drawing
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

