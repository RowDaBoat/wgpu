#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps std
import std/sequtils
# @deps wgpu
from ../api as wgpu import nil
# @deps wgpu.extras
from ./types as extras import nil
from ./strings import `$`

#_______________________________________
# @section Information
#_____________________________
proc features *(adapter :wgpu.Adapter) :seq[wgpu.FeatureName]=
  ## @descr Returns the features supported by the adapter as a seq[FeatureName]
  var data = wgpu.SupportedFeatures()
  wgpu.get(adapter, data.addr)
  result = newSeqWith(data.featureCount.int, wgpu.FeatureName 0)
  for id in 0..<data.featureCount:
    result[id] = cast[ptr UncheckedArray[wgpu.FeatureName]](data.features)[id]
  wgpu.freeMembers(data)
#___________________
proc info *(adapter :wgpu.Adapter) :extras.AdapterInfo=
  ## @descr Returns the information about the adapter as an extras.AdapterInfo object
  var data :wgpu.AdapterInfo
  let status = wgpu.get(adapter, data.addr)
  if status != wgpu.Success: raise newException(extras.AdapterError, "Failed to get the Adapter's information: " & $status)
  result.vendor       = $data.vendor
  result.architecture = $data.architecture
  result.device       = $data.device
  result.description  = $data.description
  result.backendType  = data.backendType
  result.adapterType  = data.adapterType
  result.vendorID     = data.vendorID
  result.deviceID     = data.deviceID
  wgpu.freeMembers(data)

