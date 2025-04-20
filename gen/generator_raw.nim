#:_______________________________________________________
#  wgpu  |  Copyright (C) Ivan Mar (sOkam!)  |  LGPLv3  |
#:_______________________________________________________
# @deps std
from std/os import parentDir, `/`
# @deps external
import futhark
# @deps generator
import ./base

#_____________________________
# Find the headers, and generate the wrapper
importc:
  outputPath currentSourcePath.parentDir/"result_raw.nim"
  path base.wgpuDir
  path base.webgpuDir
  "wgpu.h"
  "webgpu.h"

