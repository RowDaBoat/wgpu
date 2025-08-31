#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps wgpu
from ../../../api as wgpu import nil
from ../../types as extras import nil
from ../../strings import toStringView


#_______________________________________
# @section Shader loading
#_____________________________
proc toDescriptor *(code, label :string) :extras.ShaderModuleDescriptor=
  ## @descr Reads the given wgsl shader code, and returns a ShaderModuleDescriptor for it.
  var descriptor         = new wgpu.ShaderSourceWGSL
  descriptor.chain.next  = nil
  descriptor.chain.sType = wgpu.SType_ShaderSourceWGSL
  descriptor.code        = code.toStringView()
  GC_ref(descriptor)
  result = extras.ShaderModuleDescriptor(
    nextInChain : cast[ptr wgpu.ChainedStruct](descriptor), # descriptor is a ref, so we cast that pointer into a ChainedStruct
    label       : label.toStringView(),
    ) #:: ShaderModuleDescriptor( ... )
#___________________
proc read *(file :string) :wgpu.ShaderModuleDescriptor=  file.readFile.toDescriptor(label = file)
  ## Reads the given `.wgsl` shader file, and returns a wgpu.ShaderModuleDescriptor for it.

