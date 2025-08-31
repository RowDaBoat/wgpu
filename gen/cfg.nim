#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
const stripPrefix * = [
  "WGPU",
  ] #:: stripPrefix = [ ... ]
const stripStart  * = [
  # Enum Values Prefixes
  "AdapterType_",
  "AddressMode_",
  "BackendType_",
  "BlendFactor_",
  "BlendOperation_",
  "BufferBindingType_",
  "BufferMapState_",
  "CallbackMode_",
  "CompareFunction_",
  "CompilationInfoRequestStatus_",
  "CompilationMessageType_",
  "CompositeAlphaMode_",
  "CreatePipelineAsyncStatus_",
  "CullMode_",
  "DeviceLostReason_",
  "ErrorFilter_",
  "ErrorType_",
  "FeatureLevel_",
  "FeatureName_",
  "FilterMode_",
  "FrontFace_",
  "IndexFormat_",
  "LoadOp_",
  "MapAsyncStatus_",
  "MipmapFilterMode_",
  "OptionalBool_",
  "PopErrorScopeStatus_",
  "PowerPreference_",
  "PresentMode_",
  "PrimitiveTopology_",
  "QueryType_",
  "QueueWorkDoneStatus_",
  "RequestAdapterStatus_",
  "RequestDeviceStatus_",
  "SamplerBindingType_",
  "Status_",
  "StencilOperation_",
  "StencilOperation_",
  "StorageTextureAccess_",
  "StoreOp_",
  "SurfaceGetCurrentTextureStatus_",
  "TextureAspect_",
  "TextureFormat_",
  "TextureSampleType_",
  "TextureViewDimension_",
  "VertexFormat_",
  # "VertexStepMode_",  # FIX: Creates a duplicate of Instance because enums are not marked .pure. in futhark. Uncomment when solved
  "WGSLLanguageFeatureName_",
  "WaitStatus_",
  # FIX: Creates a duplicate of RenderPassMaxDrawCount because enums are not marked .pure. in futhark. Uncomment when solved
  # "SType_",
  # "NativeSType_",
  "NativeFeature_",
  "LogLevel_",
  "Dx12Compiler_",
  "Gles3MinorVersion_",
  "PipelineStatisticName_",
  "NativeQueryType_",
  "NativeTextureFormat_",
  # FIX: Creates a duplicate of All because enums are not marked .pure. in futhark. Uncomment when solved
  # "InstanceBackend_",
  # "WGPUInstanceBackend_",

  ] #:: stripStart = [ ... ]
const replaceStart * = [
  ("1D", "D1D"),
  ("2D", "D2D"),
  ("3D", "D3D"),
  ] #:: replaceStart = [ ... ]
const replaceEnd * = [
  ("",""),
  ] #:: replaceEnd = [ ... ]
const stripEnd * = [
  "",
  ]
const addT *:seq[string]= @[]

const replaceList * = [
  # General
  ("wgpuGetVersion",                                     "getVersion"                    ),
  ("wgpuFree",                                           "free"                          ),
  # Logging
  ("wgpuSetLogCallback",                                 "set"                           ),
  ("wgpuSetLogLevel",                                    "set"                           ),

  # Instance
  ("wgpuCreateInstance",                                 "create"                        ),
  ("wgpuInstanceCreateSurface",                          "create"                        ),
  ("wgpuInstanceRequestAdapter",                         "request"                       ),
  ("wgpuInstanceEnumerateAdapters",                      "enumerate"                     ),
  ("wgpuInstanceProcessEvents",                          "processEvents"                 ),
  ("wgpuGetInstanceCapabilities",                        "get"                           ),
  ("wgpuInstanceWaitAny",                                "wait"                          ),
  ("wgpuGenerateReport",                                 "generate"                      ),
  # Instance: WGSL Features
  ("wgpuInstanceGetWGSLLanguageFeatures",                "get"                           ),
  ("wgpuInstanceHasWGSLLanguageFeature",                 "has"                           ),
  ("wgpuSupportedWGSLLanguageFeaturesFreeMembers",       "freeMembers"                   ),

  # Adapter
  ("wgpuAdapterRequestDevice",                           "request"                       ),
  ("wgpuAdapterGetLimits",                               "get"                           ),
  ("wgpuAdapterGetInfo",                                 "get"                           ),
  ("wgpuAdapterInfoFreeMembers",                         "freeMembers"                   ),
  # Adapter Features
  ("wgpuAdapterGetFeatures",                             "get"                           ),
  ("wgpuAdapterHasFeature",                              "has"                           ),
  ("wgpuSupportedFeaturesFreeMembers",                   "freeMembers"                   ),

  # Device
  ("wgpuDeviceSetUncapturedErrorCallback",               "set"                           ),
  ("wgpuDeviceCreateShaderModule",                       "create"                        ),
  ("wgpuDeviceCreateRenderPipeline",                     "create"                        ),
  ("wgpuDeviceCreateComputePipeline",                    "create"                        ),
  ("wgpuDeviceCreateSwapChain",                          "create"                        ),
  ("wgpuDeviceCreateCommandEncoder",                     "create"                        ),
  ("wgpuDeviceCreateBuffer",                             "create"                        ),
  ("wgpuDeviceCreateBindGroup",                          "create"                        ),
  ("wgpuDeviceCreatePipelineLayout",                     "create"                        ),
  ("wgpuDeviceCreateBindGroupLayout",                    "create"                        ),
  ("wgpuDeviceCreateTexture",                            "create"                        ),
  ("wgpuDeviceCreateSampler",                            "create"                        ),
  ("wgpuDeviceCreateQuerySet",                           "create"                        ),
  ("wgpuDeviceCreateRenderBundleEncoder",                "create"                        ),
  ("wgpuDeviceGetQueue",                                 "getQueue"                      ),
  ("wgpuDeviceGetLimits",                                "get"                           ),
  ("wgpuDeviceDestroy",                                  "destroy"                       ),
  ("wgpuDeviceEnumerateFeatures",                        "enumerate"                     ),
  ("wgpuDeviceHasFeature",                               "has"                           ),
  ("wgpuDevicePopErrorScope",                            "popErrorScope"                 ),
  ("wgpuDevicePushErrorScope",                           "pushErrorScope"                ),
  ("wgpuGetProcAddress",                                 "getProcAddress"                ),
  ("wgpuDeviceSetLabel",                                 "setLabel"                      ),
  ("wgpuDeviceCreateComputePipelineAsync",               "createComputePipelineAsync"    ),
  ("wgpuDeviceCreateRenderPipelineAsync",                "createRenderPipelineAsync"     ),
  ("wgpuDeviceGetAdapterInfo",                           "getAdapterInfo"                ),
  ("wgpuDeviceGetFeatures",                              "get"                           ),
  ("wgpuDevicePoll",                                     "poll"                          ), ## Returns true if the queue is empty, or false if there are more queue submissions still in flight.
  ("wgpuDeviceGetLostFuture",                            "getLostFuture"                 ),

  # Surface
  ("wgpuSurfaceConfigure",                               "configure"                     ),
  ("wgpuSurfaceUnconfigure",                             "unconfigure"                   ),
  ("wgpuSurfaceGetCurrentTexture",                       "getCurrentTexture"             ),
  ("wgpuSurfacePresent",                                 "present"                       ),
  ("wgpuSurfaceSetLabel",                                "setLabel"                      ),
  ("wgpuSurfaceGetCapabilities",                         "get"                           ),
  ("wgpuSurfaceCapabilitiesFreeMembers",                 "freeMembers"                   ),
  ("wgpuSurfaceGetSupportedFormats",                     "getSupportedFormats"           ),
  ("wgpuSurfaceGetSupportedPresentModes",                "getSupportedPresentModes"      ),

  # RenderPass Encoder
  ("wgpuRenderPassEncoderSetVertexBuffer",               "setVertexBuffer"               ),
  ("wgpuRenderPassEncoderSetIndexBuffer",                "setIndexBuffer"                ),
  ("wgpuRenderPassEncoderSetPipeline",                   "set"                           ),
  ("wgpuRenderPassEncoderSetBindGroup",                  "set"                           ),
  ("wgpuRenderPassEncoderSetBlendConstant",              "setBlendConstant"              ),
  ("wgpuRenderPassEncoderSetScissorRect",                "setScissorRect"                ),
  ("wgpuRenderPassEncoderSetStencilReference",           "setStencilReference"           ),
  ("wgpuRenderPassEncoderSetViewport",                   "setViewport"                   ),
  ("wgpuRenderPassEncoderDraw",                          "draw"                          ),
  ("wgpuRenderPassEncoderDrawIndexed",                   "draw"                          ),
  ("wgpuRenderPassEncoderDrawIndirect",                  "drawIndirect"                  ),
  ("wgpuRenderPassEncoderDrawIndexedIndirect",           "drawIndexedIndirect"           ),
  ("wgpuRenderPassEncoderEnd",                           "End"                           ),
  ("wgpuRenderPassEncoderExecuteBundles",                "execute"                       ),
  ("wgpuRenderPassEncoderBeginPipelineStatisticsQuery",  "beginPipelineStatisticsQuery"  ),
  ("wgpuRenderPassEncoderEndPipelineStatisticsQuery",    "endPipelineStatisticsQuery"    ),
  ("wgpuRenderPassEncoderInsertDebugMarker",             "insertDebugMarker"             ),
  ("wgpuRenderPassEncoderPopDebugGroup",                 "popDebugGroup"                 ),
  ("wgpuRenderPassEncoderPushDebugGroup",                "pushDebugGroup"                ),
  ("wgpuRenderPassEncoderBeginOcclusionQuery",           "beginOcclusionQuery"           ),
  ("wgpuRenderPassEncoderEndOcclusionQuery",             "endOcclusionQuery"             ),
  ("wgpuRenderPassEncoderSetLabel",                      "setLabel"                      ),
  ("wgpuRenderPassEncoderSetPushConstants",              "setPushConstants"              ),
  ("wgpuRenderPassEncoderMultiDrawIndirect",             "multiDrawIndirect"             ),
  ("wgpuRenderPassEncoderMultiDrawIndirectCount",        "multiDrawIndirectCount"        ),
  ("wgpuRenderPassEncoderMultiDrawIndexedIndirect",      "multiDrawIndexedIndirect"      ),
  ("wgpuRenderPassEncoderMultiDrawIndexedIndirectCount", "multiDrawIndexedIndirectCount" ),
  ("wgpuRenderPassEncoderWriteTimestamp",                "writeTimestamp"                ),

  # Command Encoder
  ("wgpuCommandEncoderBeginRenderPass",                  "begin"                         ),
  ("wgpuCommandEncoderBeginComputePass",                 "begin"                         ),
  ("wgpuCommandEncoderFinish",                           "finish"                        ),
  ("wgpuCommandEncoderCopyBufferToBuffer",               "copy"                          ), ## Copy Buffer to Buffer
  ("wgpuCommandEncoderCopyBufferToTexture",              "copy"                          ), ## Copy Buffer to Texture
  ("wgpuCommandEncoderCopyTextureToBuffer",              "copy"                          ), ## Copy Texture to Buffer
  ("wgpuCommandEncoderCopyTextureToTexture",             "copy"                          ), ## Copy Texture to Texture
  ("wgpuCommandEncoderClearBuffer",                      "clear"                         ), ## Clear Buffer
  ("wgpuCommandEncoderInsertDebugMarker",                "insertDebugMarker"             ),
  ("wgpuCommandEncoderPopDebugGroup",                    "popDebugGroup"                 ),
  ("wgpuCommandEncoderPushDebugGroup",                   "pushDebugGroup"                ),
  ("wgpuCommandEncoderResolveQuerySet",                  "resolve"                       ),
  ("wgpuCommandEncoderWriteTimestamp",                   "writeTimestamp"                ),

  # Queue
  ("wgpuQueueSubmit",                                    "submit"                        ),
  ("wgpuQueueWriteBuffer",                               "write"                         ),
  ("wgpuQueueWriteTexture",                              "write"                         ),
  ("wgpuQueueOnSubmittedWorkDone",                       "onSubmittedWorkDone"           ),
  ("wgpuQueueSetLabel",                                  "setLabel"                      ),
  ("wgpuQueueRelease",                                   "release"                       ),
  ("wgpuQueueSubmitForIndex",                            "submitForIndex"                ),

  # Buffer
  ("wgpuBufferMapAsync",                                 "mapAsync"                      ),
  ("wgpuBufferGetMappedRange",                           "getMappedRange"                ),
  ("wgpuBufferGetConstMappedRange",                      "getConstMappedRange"           ),
  ("wgpuBufferGetSize",                                  "getSize"                       ),
  ("wgpuBufferGetUsage",                                 "getUsage"                      ),
  ("wgpuBufferUnmap",                                    "unmap"                         ),
  ("wgpuBufferDestroy",                                  "destroy"                       ),
  ("wgpuBufferSetLabel",                                 "setLabel"                      ),
  ("wgpuBufferGetMapState",                              "getMapState"                   ),

  # Pipeline
  ("wgpuPipelineLayoutSetLabel",                         "setLabel"                      ),

  # Render Pipeline
  ("wgpuRenderPipelineGetBindGroupLayout",               "getBindGroupLayout"            ),
  ("wgpuRenderPipelineSetLabel",                         "setLabel"                      ),

  # Compute Pipeline
  ("wgpuComputePipelineGetBindGroupLayout",              "getBindGroupLayout"            ),
  ("wgpuComputePassEncoderSetLabel",                     "setLabel"                      ),
  ("wgpuComputePipelineSetLabel",                        "setLabel"                      ),

  # ComputePass Encoder
  ("wgpuComputePassEncoderSetPipeline",                  "set"                           ),
  ("wgpuComputePassEncoderSetBindGroup",                 "set"                           ),
  ("wgpuComputePassEncoderEnd",                          "End"                           ),
  ("wgpuComputePassEncoderDispatchWorkgroups",           "dispatchWorkgroups"            ),
  ("wgpuComputePassEncoderDispatchWorkgroupsIndirect",   "dispatchWorkgroupsIndirect"    ),
  ("wgpuComputePassEncoderBeginPipelineStatisticsQuery", "beginPipelineStatisticsQuery"  ),
  ("wgpuComputePassEncoderEndPipelineStatisticsQuery",   "endPipelineStatisticsQuery"    ),
  ("wgpuComputePassEncoderInsertDebugMarker",            "insertDebugMarker"             ),
  ("wgpuComputePassEncoderPopDebugGroup",                "popDebugGroup"                 ),
  ("wgpuComputePassEncoderPushDebugGroup",               "pushDebugGroup"                ),
  ("wgpuComputePassEncoderSetPushConstants",             "setPushConstants"              ),
  ("wgpuComputePassEncoderWriteTimestamp",               "writeTimestamp"                ),

  # Texture
  ("wgpuTextureCreateView",                              "create"                        ),
  ("wgpuTextureDestroy",                                 "destroy"                       ),
  ("wgpuTextureGetDepthOrArrayLayers",                   "getDepthOrArrayLayers"         ),
  ("wgpuTextureGetDimension",                            "getDimension"                  ),
  ("wgpuTextureGetFormat",                               "getFormat"                     ),
  ("wgpuTextureGetHeight",                               "getHeight"                     ),
  ("wgpuTextureGetMipLevelCount",                        "getMipLevelCount"              ),
  ("wgpuTextureGetSampleCount",                          "getSampleCount"                ),
  ("wgpuTextureGetUsage",                                "getUsage"                      ),
  ("wgpuTextureGetWidth",                                "getWidth"                      ),
  ("wgpuTextureSetLabel",                                "setLabel"                      ),
  ("wgpuTextureViewSetLabel",                            "setLabel"                      ),

  # Sampler
  ("wgpuSamplerSetLabel",                                "setLabel"                      ),

  # RenderBundle
  ("wgpuRenderBundleEncoderDraw",                        "draw"                          ),
  ("wgpuRenderBundleEncoderDrawIndexed",                 "draw"                          ),
  ("wgpuRenderBundleEncoderDrawIndirect",                "drawIndirect"                  ),
  ("wgpuRenderBundleEncoderDrawIndexedIndirect",         "drawIndexedIndirect"           ),
  ("wgpuRenderBundleEncoderSetBindGroup",                "set"                           ),
  ("wgpuRenderBundleEncoderSetPipeline",                 "set"                           ),
  ("wgpuRenderBundleEncoderSetVertexBuffer",             "setVertexBuffer"               ),
  ("wgpuRenderBundleEncoderSetIndexBuffer",              "setIndexBuffer"                ),
  ("wgpuRenderBundleEncoderFinish",                      "finish"                        ),
  ("wgpuRenderBundleEncoderInsertDebugMarker",           "insertDebugMarker"             ),
  ("wgpuRenderBundleEncoderPopDebugGroup",               "popDebugGroup"                 ),
  ("wgpuRenderBundleEncoderPushDebugGroup",              "pushDebugGroup"                ),
  ("wgpuRenderBundleSetLabel",                           "setLabel"                      ),
  ("wgpuRenderBundleEncoderSetLabel",                    "setLabel"                      ),
  ("wgpuRenderBundleEncoderSetPushConstants",            "setPushConstants"              ),

  # QuerySet
  ("wgpuQuerySetDestroy",                                "destroy"                       ),
  ("wgpuQuerySetGetCount",                               "getCount"                      ),
  ("wgpuQuerySetGetType",                                "getType"                       ),
  ("wgpuQuerySetSetLabel",                               "setLabel"                      ),

  # BindGroup
  ("wgpuBindGroupSetLabel",                              "setLabel"                      ),
  ("wgpuBindGroupLayoutSetLabel",                        "layoutSetLabel"                ),

  # CommandBuffer
  ("wgpuCommandBufferSetLabel",                          "setLabel"                      ),
  ("wgpuCommandEncoderSetLabel",                         "setLabel"                      ),

  # ShaderModule
  ("wgpuShaderModuleGetCompilationInfo",                 "getCompilationInfo"            ),
  ("wgpuShaderModuleSetLabel",                           "setLabel"                      ),

  # Resources: Reference Counting
  ("wgpuDeviceAddRef",                                   "addRef"                        ),
  ("wgpuInstanceAddRef",                                 "addRef"                        ),
  ("wgpuAdapterAddRef",                                  "addRef"                        ),
  ("wgpuBindGroupAddRef",                                "addRef"                        ),
  ("wgpuBindGroupLayoutAddRef",                          "addRef"                        ),
  ("wgpuBufferAddRef",                                   "addRef"                        ),
  ("wgpuCommandBufferAddRef",                            "addRef"                        ),
  ("wgpuCommandEncoderAddRef",                           "addRef"                        ),
  ("wgpuRenderPassEncoderAddRef",                        "addRef"                        ),
  ("wgpuComputePassEncoderAddRef",                       "addRef"                        ),
  ("wgpuRenderBundleEncoderAddRef",                      "addRef"                        ),
  ("wgpuComputePipelineAddRef",                          "addRef"                        ),
  ("wgpuPipelineLayoutAddRef",                           "addRef"                        ),
  ("wgpuQueueAddRef",                                    "addRef"                        ),
  ("wgpuQuerySetAddRef",                                 "addRef"                        ),
  ("wgpuRenderBundleAddRef",                             "addRef"                        ),
  ("wgpuRenderPipelineAddRef",                           "addRef"                        ),
  ("wgpuSamplerAddRef",                                  "addRef"                        ),
  ("wgpuShaderModuleAddRef",                             "addRef"                        ),
  ("wgpuSurfaceAddRef",                                  "addRef"                        ),
  ("wgpuSwapChainAddRef",                                "addRef"                        ),
  ("wgpuTextureAddRef",                                  "addRef"                        ),
  ("wgpuTextureViewAddRef",                              "addRef"                        ),
  ("wgpuDeviceRelease",                                  "release"                       ),
  ("wgpuInstanceRelease",                                "release"                       ),
  ("wgpuAdapterRelease",                                 "release"                       ),
  ("wgpuBindGroupRelease",                               "release"                       ),
  ("wgpuBindGroupLayoutRelease",                         "release"                       ),
  ("wgpuBufferRelease",                                  "release"                       ),
  ("wgpuCommandBufferRelease",                           "release"                       ),
  ("wgpuCommandEncoderRelease",                          "release"                       ),
  ("wgpuRenderPassEncoderRelease",                       "release"                       ),
  ("wgpuComputePassEncoderRelease",                      "release"                       ),
  ("wgpuRenderBundleEncoderRelease",                     "release"                       ),
  ("wgpuComputePipelineRelease",                         "release"                       ),
  ("wgpuPipelineLayoutRelease",                          "release"                       ),
  ("wgpuQuerySetRelease",                                "release"                       ),
  ("wgpuRenderBundleRelease",                            "release"                       ),
  ("wgpuRenderPipelineRelease",                          "release"                       ),
  ("wgpuSamplerRelease",                                 "release"                       ),
  ("wgpuShaderModuleRelease",                            "release"                       ),
  ("wgpuSurfaceRelease",                                 "release"                       ),
  ("wgpuSwapChainRelease",                               "release"                       ),
  ("wgpuTextureRelease",                                 "release"                       ),
  ("wgpuTextureViewRelease",                             "release"                       ),
  ] #:: replaceEnd = [ ... ]

