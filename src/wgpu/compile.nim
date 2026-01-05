#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Compilation system for linking to wgpu headers  |
#_________________________________________________|
# std dependencies
import std/os
import std/strformat
import std/compilesettings


#_________________________________________________
# Helpers
#_____________________________
# TODO: Switch to execShellCmd when 2.0 devel becomes stable
# TODO: Capture errors and abort on failure
proc sh (cmd :string; dir :string= "") :void=
  ## Executes the given shell command and writes the output to console.
  ## Same as the nimscript version, but usable at compile time in static blocks.
  ## Runs the command from `dir` when specified.
  var command :string
  when defined(windows):
    if dir != "":  command = &"cd /d {dir} && {cmd}"
    else:          command = cmd
    echo gorgeEx(&"cmd /c \"{$command}\"").output
  else:
    if dir != "":  command = &"cd {dir}; " & cmd
    else:          command = cmd
    echo gorgeEx(&"sh -c \"{$command}\"").output
#_____________________________
proc cp *(src, trg :string) :void=
  ## Copies `src` to `trg`, using the shell's `cp` command.
  ## Usable at compile time in static blocks.
  echo &": Copying {src}\n  to {trg}"
  sh &"cp {src} {trg}"
#_____________________________
const thisDir   = currentSourcePath().parentDir()
const Cdir      = thisDir/"C"
const wgpuDir   = Cdir/"wgpu-native"
const headerDir = wgpuDir/"ffi"
const cacheDir  = compilesettings.querySetting(nimcacheDir)
const trgDir    = cacheDir/"wgpu"
const rlsDir    * = trgDir/"release"
const dbgDir    * = trgDir/"debug"


#_________________________________________________
# Build wgpu
#_____________________________
# Note: Cannot be a nimble task
#   wgpu should be built with either debug or release, just like Nim code.
#   Nimble doesn't understand auto-defines, which makes it impossible to designate a nimble task for it.
#   Usually you would compile C code with {.compile.} pragmas and nim,
#   but that's not possible for Rust
#   So this system calls for the wgpu-native buildsystem instead.
#_____________________________
static:
  echo ": Compiling wgpu-native..."
  when defined(debug):  sh &"cargo build --target-dir {trgDir}", wgpuDir
  else:                 sh &"cargo build --target-dir {trgDir} --release", wgpuDir
  # Fix the static linking mess of clang+mac
  when defined(macosx):
    const file = "libwgpu_native.a"
    if fileExists( rlsDir/file ):  cp rlsDir/file, rlsDir/"libwgpu_native_static.a"
    if fileExists( dbgDir/file ):  cp dbgDir/file, dbgDir/"libwgpu_native_static.a"


#_________________________________________________
# Pass cflag -I to the compiler to include the header folders
#_____________________________
{.passC: &"-I{headerDir}".}


#_________________________________________________
# Pass ldflag to link to the folder where the libs are output
#_____________________________
when defined(windows) and defined(vcc):
  # MSVC: use /link /LIBPATH: to pass library path to linker (not compiler)
  # The /link prefix ensures it goes to the linker, not the compiler
  when defined(debug):  {.passL: &"/link /LIBPATH:\"{dbgDir}\"".}
  else:                 {.passL: &"/link /LIBPATH:\"{rlsDir}\"".}
else:
  # Unix-style -L flag for GCC/Clang/MinGW/Zig
  when defined(debug):  {.passL: &"-L{dbgDir}".}
  else:                 {.passL: &"-L{rlsDir}".}

#_________________________________________________
# Link to stdc++ for zigcc
#_____________________________
when defined(zig):  {.passL: "-lstdc++".}

#_________________________________________________
# Link to the static library
#_____________________________
# Linux+Mac
when defined(unix):       # Both Linux and Mac
  when not (defined(clang) or defined(gcc)): {.error: "Compilers currently supported are gcc and clang".}
  when defined(macosx):
    {.passL: "-framework Metal -framework Cocoa -framework CoreVideo -framework IOKit -framework QuartzCore".}
    {.passL: "-lwgpu_native_static".}  # Use the renamed file with mac
  elif defined(clang) or defined(zig):
    {.passL: "-lwgpu_native".}         # ZigCC/clang don't understand the `:`
  else:
    {.passL: "-l:libwgpu_native.a".}   # Use `:` with gcc.linux
#_____________________________
# Windows
elif defined(windows):
  when not (defined(gcc) or defined(zig) or defined(vcc)):
    {.warning: "Mingw/ZigCC/MSVC are the only compilers currently supported on Windows. clang will most likely break".}
  {.link: "user32.lib".}
  {.link: "userenv.lib".}
  {.link: "ws2_32.lib".}
  {.link: "dwmapi.lib".}
  {.link: "dbghelp.lib".}
  {.link: "d3dcompiler.lib".}
  {.link: "d3d12.lib".}
  {.link: "d3d11.lib".}
  {.link: "dxgi.lib".}
  {.link: "bcrypt.lib".}
  {.link: "advapi32.lib".}
  when defined(vcc):
    {.link: "ntdll.lib".}
    {.link: "opengl32.lib".}
    {.link: "ole32.lib".}
    {.link: "propsys.lib".}
    {.link: "runtimeobject.lib".}
    {.link: "oleaut32.lib".}
    {.link: "wgpu_native.lib".}
  else:
    {.passL: "-l:wgpu_native.lib".}
#_____________________________
# Other
else:  {.error: "Supported platforms are currently Windows and Unix".}
