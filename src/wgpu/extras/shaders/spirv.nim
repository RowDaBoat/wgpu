#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps wgpu
from ../../api as wgpu import nil
from ../types as extras import nil
from ../strings import toStringView

proc toDescriptor *(code, label :string) :extras.ShaderModuleDescriptor=
  var descriptor         = new wgpu.ShaderSourceSPIRV
  descriptor.chain.next  = nil
  descriptor.chain.sType = wgpu.SType_ShaderSourceSPIRV
  descriptor.code        = cast[ptr uint32](code[0].addr)
  descriptor.codeSize    = (code.len div 4).uint32
  GC_ref(descriptor)
  result = extras.ShaderModuleDescriptor(
    nextInChain : cast[ptr wgpu.ChainedStruct](descriptor), # descriptor is a ref, so we cast that pointer into a ChainedStruct
    label       : label.toStringView(),
    ) #:: ShaderModuleDescriptor( ... )

