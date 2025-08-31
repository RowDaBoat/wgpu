#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps wgpu
from ../api as wgpu import nil


#_______________________________________
# @section Default Limits
#_____________________________
# NOTE: Should be default values, but automated wrapping does not allow it
proc new *(_:typedesc[wgpu.Limits];
    maxTextureDimension1D                      =  uint32.high;
    maxTextureDimension2D                      =  uint32.high;
    maxTextureDimension3D                      =  uint32.high;
    maxTextureArrayLayers                      =  uint32.high;
    maxBindGroups                              =  uint32.high;
    maxBindingsPerBindGroup                    =  uint32.high;
    maxDynamicUniformBuffersPerPipelineLayout  =  uint32.high;
    maxDynamicStorageBuffersPerPipelineLayout  =  uint32.high;
    maxSampledTexturesPerShaderStage           =  uint32.high;
    maxSamplersPerShaderStage                  =  uint32.high;
    maxStorageBuffersPerShaderStage            =  uint32.high;
    maxStorageTexturesPerShaderStage           =  uint32.high;
    maxUniformBuffersPerShaderStage            =  uint32.high;
    maxUniformBufferBindingSize                =  uint64.high;
    maxStorageBufferBindingSize                =  uint64.high;
    minUniformBufferOffsetAlignment            =  uint32.high;
    minStorageBufferOffsetAlignment            =  uint32.high;
    maxVertexBuffers                           =  uint32.high;
    maxBufferSize                              =  uint64.high;
    maxVertexAttributes                        =  uint32.high;
    maxVertexBufferArrayStride                 =  uint32.high;
    maxInterStageShaderVariables               =  uint32.high;
    maxColorAttachments                        =  uint32.high;
    maxColorAttachmentBytesPerSample           =  uint32.high;
    maxComputeWorkgroupStorageSize             =  uint32.high;
    maxComputeInvocationsPerWorkgroup          =  uint32.high;
    maxComputeWorkgroupSizeX                   =  uint32.high;
    maxComputeWorkgroupSizeY                   =  uint32.high;
    maxComputeWorkgroupSizeZ                   =  uint32.high;
    maxComputeWorkgroupsPerDimension           =  uint32.high;
  ) :wgpu.Limits=
  # Init the default values
  result = wgpu.Limits.default()
  # Update only those that have been specified
  if maxTextureDimension1D                     != uint32.high:  result.maxTextureDimension1D                     = maxTextureDimension1D
  if maxTextureDimension2D                     != uint32.high:  result.maxTextureDimension2D                     = maxTextureDimension2D
  if maxTextureDimension3D                     != uint32.high:  result.maxTextureDimension3D                     = maxTextureDimension3D
  if maxTextureArrayLayers                     != uint32.high:  result.maxTextureArrayLayers                     = maxTextureArrayLayers
  if maxBindGroups                             != uint32.high:  result.maxBindGroups                             = maxBindGroups
  if maxBindingsPerBindGroup                   != uint32.high:  result.maxBindingsPerBindGroup                   = maxBindingsPerBindGroup
  if maxDynamicUniformBuffersPerPipelineLayout != uint32.high:  result.maxDynamicUniformBuffersPerPipelineLayout = maxDynamicUniformBuffersPerPipelineLayout
  if maxDynamicStorageBuffersPerPipelineLayout != uint32.high:  result.maxDynamicStorageBuffersPerPipelineLayout = maxDynamicStorageBuffersPerPipelineLayout
  if maxSampledTexturesPerShaderStage          != uint32.high:  result.maxSampledTexturesPerShaderStage          = maxSampledTexturesPerShaderStage
  if maxSamplersPerShaderStage                 != uint32.high:  result.maxSamplersPerShaderStage                 = maxSamplersPerShaderStage
  if maxStorageBuffersPerShaderStage           != uint32.high:  result.maxStorageBuffersPerShaderStage           = maxStorageBuffersPerShaderStage
  if maxStorageTexturesPerShaderStage          != uint32.high:  result.maxStorageTexturesPerShaderStage          = maxStorageTexturesPerShaderStage
  if maxUniformBuffersPerShaderStage           != uint32.high:  result.maxUniformBuffersPerShaderStage           = maxUniformBuffersPerShaderStage
  if maxUniformBufferBindingSize               != uint64.high:  result.maxUniformBufferBindingSize               = maxUniformBufferBindingSize
  if maxStorageBufferBindingSize               != uint64.high:  result.maxStorageBufferBindingSize               = maxStorageBufferBindingSize
  if minUniformBufferOffsetAlignment           != uint32.high:  result.minUniformBufferOffsetAlignment           = minUniformBufferOffsetAlignment
  if minStorageBufferOffsetAlignment           != uint32.high:  result.minStorageBufferOffsetAlignment           = minStorageBufferOffsetAlignment
  if maxVertexBuffers                          != uint32.high:  result.maxVertexBuffers                          = maxVertexBuffers
  if maxBufferSize                             != uint64.high:  result.maxBufferSize                             = maxBufferSize
  if maxVertexAttributes                       != uint32.high:  result.maxVertexAttributes                       = maxVertexAttributes
  if maxVertexBufferArrayStride                != uint32.high:  result.maxVertexBufferArrayStride                = maxVertexBufferArrayStride
  if maxInterStageShaderVariables              != uint32.high:  result.maxInterStageShaderVariables              = maxInterStageShaderVariables
  if maxColorAttachments                       != uint32.high:  result.maxColorAttachments                       = maxColorAttachments
  if maxColorAttachmentBytesPerSample          != uint32.high:  result.maxColorAttachmentBytesPerSample          = maxColorAttachmentBytesPerSample
  if maxComputeWorkgroupStorageSize            != uint32.high:  result.maxComputeWorkgroupStorageSize            = maxComputeWorkgroupStorageSize
  if maxComputeInvocationsPerWorkgroup         != uint32.high:  result.maxComputeInvocationsPerWorkgroup         = maxComputeInvocationsPerWorkgroup
  if maxComputeWorkgroupSizeX                  != uint32.high:  result.maxComputeWorkgroupSizeX                  = maxComputeWorkgroupSizeX
  if maxComputeWorkgroupSizeY                  != uint32.high:  result.maxComputeWorkgroupSizeY                  = maxComputeWorkgroupSizeY
  if maxComputeWorkgroupSizeZ                  != uint32.high:  result.maxComputeWorkgroupSizeZ                  = maxComputeWorkgroupSizeZ
  if maxComputeWorkgroupsPerDimension          != uint32.high:  result.maxComputeWorkgroupsPerDimension          = maxComputeWorkgroupsPerDimension


#_______________________________________
# @section Missing Functionality
#_____________________________
# Should be part of the bindings, but they don't exist in wgpu-native
#___________________
# Default Limits
proc default *(_ :typedesc[wgpu.Limits]) :wgpu.Limits=
  # https://docs.rs/wgpu-types/0.16.0/src/wgpuTypes/lib.rs.html#912
  result.maxTextureDimension1D                     = 8192
  result.maxTextureDimension2D                     = 8192
  result.maxTextureDimension3D                     = 2048
  result.maxTextureArrayLayers                     = 256
  result.maxBindGroups                             = 4
  result.maxBindingsPerBindGroup                   = 640
  result.maxDynamicUniformBuffersPerPipelineLayout = 8
  result.maxDynamicStorageBuffersPerPipelineLayout = 4
  result.maxSampledTexturesPerShaderStage          = 16
  result.maxSamplersPerShaderStage                 = 16
  result.maxStorageBuffersPerShaderStage           = 8
  result.maxStorageTexturesPerShaderStage          = 4
  result.maxUniformBuffersPerShaderStage           = 12
  result.maxUniformBufferBindingSize               = 64 shl 10
  result.maxStorageBufferBindingSize               = 128 shl 20
  result.maxVertexBuffers                          = 8
  result.maxBufferSize                             = 1 shl 28
  result.maxVertexAttributes                       = 16
  result.maxVertexBufferArrayStride                = 2048
  result.minUniformBufferOffsetAlignment           = 256
  result.minStorageBufferOffsetAlignment           = 256
  result.maxComputeWorkgroupStorageSize            = 16384
  result.maxComputeInvocationsPerWorkgroup         = 256
  result.maxComputeWorkgroupSizeX                  = 256
  result.maxComputeWorkgroupSizeY                  = 256
  result.maxComputeWorkgroupSizeZ                  = 64
  result.maxComputeWorkgroupsPerDimension          = 65535
  # result.maxPushConstantSize                       = 0
#___________________
proc downlevel_defaults *(_ :typedesc[wgpu.Limits]) :wgpu.Limits=
  ## Default limits guaranteed to be compatible with GLES-3.1, and D3D11
  result.maxTextureDimension1D                     = 2048
  result.maxTextureDimension2D                     = 2048
  result.maxTextureDimension3D                     = 256
  result.maxTextureArrayLayers                     = 256
  result.maxBindGroups                             = 4
  result.maxBindingsPerBindGroup                   = 640
  result.maxDynamicUniformBuffersPerPipelineLayout = 8
  result.maxDynamicStorageBuffersPerPipelineLayout = 4
  result.maxSampledTexturesPerShaderStage          = 16
  result.maxSamplersPerShaderStage                 = 16
  result.maxStorageBuffersPerShaderStage           = 4
  result.maxStorageTexturesPerShaderStage          = 4
  result.maxUniformBuffersPerShaderStage           = 12
  result.maxUniformBufferBindingSize               = 16 shl 10
  result.maxStorageBufferBindingSize               = 128 shl 20
  result.maxVertexBuffers                          = 8
  result.maxBufferSize                             = 16
  result.maxVertexAttributes                       = 2048
  result.maxVertexBufferArrayStride                = 0
  result.minUniformBufferOffsetAlignment           = 256
  result.minStorageBufferOffsetAlignment           = 256
  result.maxComputeWorkgroupStorageSize            = 16352
  result.maxComputeInvocationsPerWorkgroup         = 256
  result.maxComputeWorkgroupSizeX                  = 256
  result.maxComputeWorkgroupSizeY                  = 256
  result.maxComputeWorkgroupSizeZ                  = 64
  result.maxComputeWorkgroupsPerDimension          = 65535
  # result.maxPushConstantSize                       = 1 shl 28
#___________________
proc downlevel_webgl2_defaults *(_ :typedesc[wgpu.Limits]) :wgpu.Limits=
  ## Default limits guaranteed to be compatible with GLES-3.0, and D3D11, and WebGL2
  result = wgpu.Limits.downlevelDefaults()  # Most of the values should be the same as the downlevel defaults
  result.maxUniformBuffersPerShaderStage           = 11
  result.maxStorageBuffersPerShaderStage           = 0
  result.maxStorageTexturesPerShaderStage          = 0
  result.maxDynamicStorageBuffersPerPipelineLayout = 0
  result.maxStorageBufferBindingSize               = 0
  result.maxVertexBufferArrayStride                = 255
  result.maxComputeWorkgroupStorageSize            = 0
  result.maxComputeInvocationsPerWorkgroup         = 0
  result.maxComputeWorkgroupSize_x                 = 0
  result.maxComputeWorkgroupSize_y                 = 0
  result.maxComputeWorkgroupSize_z                 = 0
  result.maxComputeWorkgroupsPerDimension          = 0

