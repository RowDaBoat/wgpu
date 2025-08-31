#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps wgpu
from ../api as wgpu import nil


#_______________________________________
# @section Missing Data
#_____________________________
# FIX: WGPU uses consts for flag sets, but Futhark has a bug that does not generate them
# https://github.com/PMunch/futhark/issues/144
#_____________________________
# Buffer Flags
type BufferUsage *{.pure, size:sizeof(cuint).}= enum MapRead, MapWrite, CopySrc, CopyDst, Index, Vertex, Uniform, Storage, Indirect, QueryResolve
type BufferUsageFlags * = set[types.BufferUsage]
template None *(_:typedesc[types.BufferUsage] | typedesc[wgpu.BufferUsage]) :BufferUsageFlags= {}
converter toWGPU *(val :BufferUsageFlags) :wgpu.BufferUsage= cast[wgpu.BufferUsage](val)
converter toWGPU *(val :types.BufferUsage) :wgpu.BufferUsage= cast[wgpu.BufferUsage]({val})
converter toExtras *(val :types.BufferUsage) :BufferUsageFlags= {val}
converter toBufferUsage *(val :wgpu.BufferUsage) :BufferUsageFlags= cast[BufferUsageFlags](val)
#___________________
# Color Flags
type ColorWrite *{.pure, size:sizeof(cuint).}= enum Red, Green, Blue, Alpha
type ColorWriteFlags * = set[types.ColorWrite]
template None *(_:typedesc[types.ColorWrite] | typedesc[wgpu.ColorWriteMask]) :ColorWriteFlags= {}
template All  *(_:typedesc[types.ColorWrite] | typedesc[wgpu.ColorWriteMask]) :ColorWriteFlags= {Red, Green, Blue, Alpha}
converter toWGPU *(val :ColorWriteFlags) :wgpu.ColorWriteMask= cast[wgpu.ColorWriteMask](val)
converter toWGPU *(val :types.ColorWrite) :wgpu.ColorWriteMask= cast[wgpu.ColorWriteMask]({val})
converter toExtras *(val :types.ColorWrite) :ColorWriteFlags= {val}
converter toColorWrite *(val :wgpu.ColorWriteMask) :ColorWriteFlags= cast[ColorWriteFlags](val)
#___________________
# MapMode Flags
type MapMode *{.pure, size:sizeof(cuint).}= enum Read, Write
type MapModeFlags * = set[types.MapMode]
template None *(_:typedesc[types.MapMode] | typedesc[wgpu.MapMode]) :MapModeFlags= {}
converter toWGPU *(val :MapModeFlags) :wgpu.MapMode= cast[wgpu.MapMode](val)
converter toWGPU *(val :types.MapMode) :wgpu.MapMode= cast[wgpu.MapMode]({val})
converter toExtras *(val :types.MapMode) :MapModeFlags= {val}
converter toMapMode *(val :wgpu.MapMode) :MapModeFlags= cast[MapModeFlags](val)
#___________________
# Shader Stage Flags
type ShaderStage *{.pure, size:sizeof(cuint).}= enum Vertex, Fragment, Compute
type ShaderStageFlags * = set[types.ShaderStage]
template None *(_:typedesc[types.ShaderStage] | typedesc[wgpu.ShaderStage]) :ShaderStageFlags= {}
converter toWGPU *(val :ShaderStageFlags) :wgpu.ShaderStage= cast[wgpu.ShaderStage](val)
converter toWGPU *(val :types.ShaderStage) :wgpu.ShaderStage= cast[wgpu.ShaderStage]({val})
converter toExtras *(val :types.ShaderStage) :ShaderStageFlags= {val}
converter toShaderStage *(val :wgpu.ShaderStage) :ShaderStageFlags= cast[ShaderStageFlags](val)
#___________________
# Texture Flags
type TextureUsage *{.pure, size:sizeof(cuint).}= enum CopySrc, CopyDst, TextureBinding, StorageBinding, RenderAttachment
type TextureUsageFlags * = set[types.TextureUsage]
template None *(_:typedesc[types.TextureUsage] | typedesc[wgpu.TextureUsage]) :TextureUsageFlags= {}
converter toWGPU *(val :TextureUsageFlags) :wgpu.TextureUsage= cast[wgpu.TextureUsage](val)
converter toWGPU *(val :types.TextureUsage) :wgpu.TextureUsage= cast[wgpu.TextureUsage]({val})
converter toExtras *(val :types.TextureUsage) :TextureUsageFlags= {val}
converter toTextureUsage *(val :wgpu.TextureUsage) :TextureUsageFlags= cast[TextureUsageFlags](val)


#_______________________________________
# @section Shader Modules
#_____________________________
type ShaderModuleDescriptor * = object of wgpu.ShaderModuleDescriptor
  ## @descr Alias for wgpu.ShaderModuleDescriptor for calling unref inside its `=destroy` hook
proc `=destroy`*(desc :types.ShaderModuleDescriptor) :void=
  GC_unref(cast[ref wgpu.ShaderSourceWGSL](desc.nextInChain))


#_______________________________________
# @section Adapter
#_____________________________
type AdapterError * = object of CatchableError
#___________________
type AdapterInfo * = object
  ## @descr Information about an adapter
  vendor       *:string
  architecture *:string
  device       *:string
  description  *:string
  backendType  *:wgpu.BackendType
  adapterType  *:wgpu.AdapterType
  vendorID     *:uint32
  deviceID     *:uint32


#_______________________________________
# @section Surface
#_____________________________
type SurfaceError * = object of CatchableError
#___________________
type SurfaceCapabilities * = object
  ## @descr Information about the capabilities of a surface
  usages        *:TextureUsageFlags
  formats       *:seq[wgpu.TextureFormat]
  presentModes  *:seq[wgpu.PresentMode]
  alphaModes    *:seq[wgpu.CompositeAlphaMode]


#_______________________________________
# @section Device
#_____________________________
type DeviceError * = object of CatchableError

