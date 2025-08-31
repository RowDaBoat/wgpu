#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps wgpu
import ../api as wgpu


#___________________
func toStringView *(val :string) :StringView=  StringView(data: val.cstring, length: val.len.csize_t)
  ## @descr Converts the given Nim.string into a wgpu.StringView
#___________________
func `$` *(val :StringView) :string=
  ## @descr Converts the given wgpu.StringView into a Nim.string
  if val.data == nil: return ""
  if val.length == 0: return ""
  val.data.toOpenArray(0, val.length.int-1).substr()
#___________________
func `$` *(feature :FeatureName) :string=
  ## @descr
  ##  Returns the string representation of the given FeatureName
  ##  Converts the value to WGPUNativeFeature before conversion where needed
  let isWgpuNative = feature.ord > 0x00030000
  if  isWgpuNative : result = $NativeFeature(feature)
  else             : result = system.`$`(feature)

