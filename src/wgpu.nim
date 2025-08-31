#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Automatic Buildsystem
{.define:wgpu.}
include ./wgpu/compile
# API
import ./wgpu/api ; export api
# wgpu-nim extras
when not defined(NoGLFW):
  import ./wgpu/extras ; export extras
