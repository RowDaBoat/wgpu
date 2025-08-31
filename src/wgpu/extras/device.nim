#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps std
import std/sequtils
# @deps wgpu
from ../api as wgpu import nil
# @deps wgpu.extras
from ./types as extras import nil


#_______________________________________
# @section Information
#_____________________________
proc features *(device :wgpu.Device) :seq[wgpu.FeatureName]=
  ## @descr Returns the features supported by the device as a wgpu.SupportedFeatures object
  var data = wgpu.SupportedFeatures()
  wgpu.get(device, features= data.addr)
  result = newSeqWith(data.featureCount.int, wgpu.FeatureName 0)
  for id in 0..<data.featureCount:
    result[id] = cast[ptr UncheckedArray[wgpu.FeatureName]](data.features)[id]
  wgpu.freeMembers(data)
#___________________
proc limits *(device :wgpu.Device) :wgpu.Limits=
  ## @descr Returns the limits supported by the device as a wgpu.Limits object
  let status = wgpu.get(device, limits= result.addr)
  if status != wgpu.Success: raise newException(extras.DeviceError, "Failed to get the limits of the device: " & $status)

