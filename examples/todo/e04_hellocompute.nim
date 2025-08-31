#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Compute example from wgpu-native/examples/compute  |
#____________________________________________________|
# std dependencies
import std/strformat
import std/os
# Module dependencies
import wgpu
# Example Extensions
import ./extras  # In a real app, these should be coming from external libraries


#__________________
# WGPU callbacks
proc adapterRequestCB *(status :RequestAdapterStatus; adapter :Adapter; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
proc deviceRequestCB  *(status :RequestDeviceStatus; device :Device; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
proc errorCB *(typ :ErrorType; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"UNCAPTURED ERROR: ({$typ}): {$message}"
proc deviceLostCB *(reason :DeviceLostReason; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"DEVICE LOST: ({$reason}): {$message}"
proc logCB *(level :LogLevel; message :CString; userdata :pointer) :void {.cdecl.}=
  echo &"[{$level}] {$message}"
proc bufferMappedCB (status :BufferMapAsyncStatus; userdata :pointer) :void {.cdecl.}=
  echo &"wgpu -> buffer mapped with status: {$status}"
#________________________________________________

# Compute shader code
const computeCode = """
@group(0) @binding(0)
var<storage, read_write> v_indices :array<u32>;  // this is used as both input and output for convenience

// The Collatz Conjecture states that for any integer n:
//   If n is even, n = n/2
//   If n is odd,  n = 3n+1
//   And repeat this process for each new n, you will always eventually reach 1.
// Though the conjecture has not been proven, no counterexample has ever been found.
// This function returns how many times this recurrence needs to be applied to reach 1.
fn collatz_iterations(n_base: u32) -> u32{
  var n :u32=  n_base;
  var i :u32=  0u;
  loop {
    if (n <= 1u) { break; }
    if (n % 2u == 0u) {
      n = n / 2u;
    } else {
      // Overflow? (i.e. 3*n + 1 > 0xffffffffu?)
      if (n >= 1431655765u) {  // 0x55555555u
        return 4294967295u;    // 0xffffffffu
      }
      n = 3u * n + 1u;
    }
    i = i + 1u;
  }
  return i;
}

@compute @workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id :vec3<u32>) {
  v_indices[global_id.x] = collatz_iterations(v_indices[global_id.x]);
}
"""

#________________________________________________
# Entry Point
#__________________
proc run=
  echo "Hello wgpu : Compute"
  #__________________
  # Intialize the CPU-side data buffer we will use in the compute shader
  let numbers     = @[1'u32, 2, 3, 4]
  let numbersSize = uint64( numbers.len * sizeof(numbers[0]) )

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set LogLevel.warn

  #__________________
  # Init wgpu
  var instance = wgpu.create(vaddr InstanceDescriptor(nextInChain: nil))
  var adapter :wgpu.Adapter; instance.request(nil, adapterRequestCB, adapter.addr)
  var device :wgpu.Device; adapter.request(nil, deviceRequestCB, device.addr)
  device.set(errorCB, nil)

  #__________________________________
  # 1. Create the compute shader
  let shader = device.create(vaddr wgslToDescriptor(
    code  = computeCode,
    label = "Hello Compute Shader",
    ))

  # 2. Create First buffer, used to upload to the GPU
  var bufferStaging = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "StagingBuffer".cstring,
    usage             : {BufferUsage.mapRead, BufferUsage.copyDst},
    size              : numbersSize,
    mappedAtCreation  : false,
    )) # << device.createBuffer()

  # 3. Create Second buffer, with a `mapRead` flag so that we can map it later.
  var bufferStorage = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "StorageBuffer".cstring,
    usage             : {BufferUsage.storage, BufferUsage.copyDst, BufferUsage.copySrc},
    size              : numbersSize,
    mappedAtCreation  : false,
    )) # << device.createBuffer()

  # 4. Create the compute pipeline
  var computePipeline = device.create(vaddr ComputePipelineDescriptor(
    nextInChain     : nil,
    label           : "Hello Compute Pipeline".cstring,
    layout          : nil,
    compute         : ProgrammableStageDescriptor(
      nextInChain   : nil,
      module        : shader,
      entryPoint    : "main".cstring,
      constantCount : 0,
      constants     : vaddr ConstantEntry(
        nextInChain : nil,
        key         : nil,
        value       : 0.0,
        ) # << constants
      ) # << compute
    )) # << device.createComputePipeline()

  # 5. Create the bindGroup
  let bindGroup = device.create(vaddr BindGroupDescriptor(
    nextInChain   : nil,
    label         : "Hello Bind Group".cstring,
    layout        : computePipeline.getBindGroupLayout(0),
    entryCount    : 1,
    entries       : vaddr BindGroupEntry(
      nextInChain : nil,
      binding     : 0,
      buffer      : bufferStorage,
      offset      : 0,
      size        : numbersSize,
      sampler     : nil,
      textureView : nil,
      ) # << entries
    )) # device.createBindGroup()

  # 6. Create the CommandEncoder, which is needed to do anything other than uploading data.
  var encoder = device.create(vaddr CommandEncoderDescriptor(
    nextInChain  : nil,
    label        : "Hello Command Encoder",
    )) # << device.createCommandEncoder()

  # 7. Create the ComputePass
  let computePass = encoder.begin(vaddr ComputePassDescriptor(
    nextInChain         : nil,
    label               : "Hello Compute Pass",
    timestampWriteCount : 0,
    timestampWrites     : nil,
    )) # << encoder.beginComputePass()

  # 8. Run the compute pass
  computePass.set(computePipeline)
  computePass.set(0, bindGroup, 0, nil)
  computePass.dispatchWorkgroups(numbers.len.uint32, 1, 1)
  computePass.End()
  encoder.copy(bufferStorage, 0, bufferStaging, 0, numbersSize)

  # 9. Get the queue, and set its WorkDone Callback
  var queue = device.getQueue()

  # 10. Finalize the encoding operation.
  var cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
    nextInChain : nil,
    label       : "Hello Command Buffer",
    )) # << encoder.finish()

  # 11. Copy the buffer from RAM to VRAM
  queue.write(bufferStorage, 0, numbers[0].unsafeAddr, numbersSize.csize_t)

  # 12. Submit the encoded CommandBuffer
  queue.submit(1, cmdBuffer.addr)

  # 13. Map our staging Buffer
  bufferStaging.mapAsync({MapMode.read}, 0, numbersSize.csize_t, bufferMappedCB, nil)

  # 14. Wait for the device to finish the async operations
  discard device.poll(true, nil)

  # 15. ComputePass is done, so read back the computed data
  let times = cast[ptr UncheckedArray[uint32]](bufferStaging.getMappedRange(0, numbersSize.csize_t))

  # 16. Do something with the given data.                  NOTE: stdout.write is just for formatting. This could be just `echo` instead
  stdout.write "wgpu -> Resulting times = [ "                  # write to console, but don't add `\n` so everything is in the same line
  for num in 0..<numbers.len: stdout.write(&"{$times[num]}, ") # write each of the numbers stored in buffer data[] to console
  stdout.write " ]\n"                                          # add a newline at the end

  # 17. Unmap the buffer when done using it
  bufferStaging.unmap()

  #__________________
  # Terminate the GPU memory
  bufferStorage.destroy()
  bufferStaging.destroy()

#__________________
when isMainModule: run()

