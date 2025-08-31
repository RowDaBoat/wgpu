#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Write a Buffer to GPU, and read its data back     |
# No window, no compute. Only does a read/write op  |
#___________________________________________________|
# std dependencies
import std/strformat
import std/os
# External dependencies
from pkg/nglfw as glfw import nil
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
#________________________________________________
# NEW : Queue Done Callback
when false:  # Disable compilation. Here for future reference. wgpuQueueOnSubmittedWorkDone is unimplemented by wgpu-native
  proc queueDoneCB (status :QueueWorkDoneStatus; userdata :pointer) :void {.cdecl.}=
    echo &"wgpu -> Queue Work: Finished with status: {$status}"
#_____________________________
proc buffer2MappedCB (status :BufferMapAsyncStatus; userdata :pointer) :void {.cdecl.}=
  ## Function called back when our Async Buffer Map happens
  echo &"wgpu -> buffer2 mapped with status: {$status}"
  if status != BufferMapAsyncStatus.success: return
  let buf  = cast[ptr wgpu.Buffer](userdata)[] # Get the Buffer (aka data[]) contained inside the userdata pointer, which we know its a ptr Buffer
  let data = cast[ptr UncheckedArray[uint8]](buf.getMappedRange(0,16))
  # Do something with the given data.            NOTE: stdout.write is just for formatting. This could be just `echo` instead
  stdout.write "wgpu -> Buffer2 Data = [ "           # write to console, but don't add `\n` so everything is in the same line
  for num in 0..<16: stdout.write(&"{$data[num]}, ") # write each of the numbers stored in buffer data[] to console
  stdout.write " ]\n"                                # add a newline at the end
#________________________________________________


#________________________________________________
# Entry Point
#__________________
proc run=
  echo "Hello wgpu"

  #__________________
  # Set wgpu.Logging
  wgpu.set(logCB, nil)
  wgpu.set LogLevel.warn
  #__________________
  # Init wgpu
  var instance = wgpu.create(wgpu.InstanceDescriptor(nextInChain: nil).vaddr)
  var adapter :wgpu.Adapter;  instance.request(vaddr RequestAdapterOptions(
      nextInChain           : nil,
      compatibleSurface     : nil,
      powerPreference       : PowerPreference.highPerformance,
      backendType           : BackendType.undefined,
      forceFallbackAdapter  : false,
      ), # << RequestAdapterOptions
    adapterRequestCB, adapter.addr,
    ) # << instance.requestAdapter()
  var device :wgpu.Device; adapter.request(vaddr DeviceDescriptor(
      nextInChain            : nil,
      label                  : "Hello Device",
      requiredFeaturesCount  : 0,
      requiredFeatures       : nil,
      requiredLimits         : nil,
      defaultQueue           : QueueDescriptor(
        nextInChain          : nil,
        label                : "Hello Default Queue"
        ), # << defaultQueue
      deviceLostCallback     : deviceLostCB,
      deviceLostUserdata     : nil,
      ), # << DeviceDescriptor
    deviceRequestCB, device.addr
    ) # << adapter.requestDevice()
  device.set(errorCB, nil)

  #________________________________________________
  # NEW : Define the Buffer Objects
  #__________________________________
  # 1. First buffer, used to upload to the GPU
  var buffer1 = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Input buffer: Written from the CPU to the GPU".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.copySrc},
    size              : 16,
    mappedAtCreation  : false,
    )) # << device.createBuffer()

  # 2. Second buffer, with a `mapRead` flag so that we can map it later.
  var buffer2 = device.create(vaddr BufferDescriptor(
    nextInChain       : nil,
    label             : "Output buffer: Read back from the GPU by the CPU".cstring,
    usage             : {BufferUsage.copyDst, BufferUsage.mapRead},
    size              : 16,
    mappedAtCreation  : false,
    )) # << device.createBuffer()

  # 3. Get the queue, and set its WorkDone Callback
  var queue = device.getQueue()
  when false:  # Disable compilation. Here for future reference. wgpuQueueOnSubmittedWorkDone is unimplemented by wgpu-native
    queue.onSubmittedWorkDone(queueDoneCB, nil)

  # 4. Create a CPU-side data buffer, of size 16 bytes, filled with numbers 0..15
  var numbers :seq[uint8]
  for num in 0..<16: numbers.add num.uint8

  # 5. Copy the buffer from RAM to VRAM
  queue.write(buffer1, 0, numbers[0].addr, 16)

  # 6. Create the CommandEncoder, which is needed to do anything other than uploading data.
  var encoder = device.create(vaddr CommandEncoderDescriptor(
    nextInChain  : nil,
    label        : "Hello Command Encoder",
    )) # << device.createCommandEncoder()

  # 7. Add a copy command to the encoder: Copy current state of buffer1 to buffer2
  encoder.copy(buffer1, 0, buffer2, 0, 16)

  # 8. Finalize the encoding operation.
  var cmdBuffer = encoder.finish(vaddr CommandBufferDescriptor(
    nextInChain : nil,
    label       : "Hello Command Buffer",
    )) # << encoder.finish()

  # 9. Submit the encoded CommandBuffer
  queue.submit(1, cmdBuffer.addr)

  # 10. Map our second buffer
  buffer2.mapAsync({MapMode.read}, 0, 16, buffer2MappedCB, buffer2.addr)

  # 11. Wait for the device to be done mapping, and read back the data
  discard device.poll(true, nil)

  # 12. Check that the data is correct
  echo "numbers = ",numbers
  let data = cast[ptr UncheckedArray[uint8]](buffer2.getMappedRange(0,16))
  for num in 0..<16: doAssert data[num] == numbers[num], "Data contained in buffer2 is invalid"

  # 13. Unmap the buffer when we are done
  buffer2.unmap()

  #__________________
  # Terminate the GPU memory
  buffer1.destroy()
  buffer2.destroy()

#__________________
when isMainModule: run()

