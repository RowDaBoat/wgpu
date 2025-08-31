#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps std
from std/os import parentDir, `/`

const rootDir   * = currentSourcePath().parentDir()/".."
const srcDir    * = base.rootDir/"src"
const wgpuDir   * = base.srcDir/"wgpu"/"C"/"wgpu-native"/"ffi"
const webgpuDir * = base.wgpuDir/"webgpu-headers"

