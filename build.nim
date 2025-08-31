#:________________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Contributors  |  MIT  :
#:________________________________________________________
# @IMPORTANT
#  This file is COMPLETELY UNNECESSARY to use the bindings with your application.
#_________________________________________________________________________________
# @fileoverview
#  confy Buildsystem for generating an updated version of the bindings with Futhark.
#_______________________________________________________________________________________|
# @deps std
from std/strformat import `&`
from std/strutils import replace
from std/os import absolutePath
# @deps ndk
import confy

info "Generating the wgpu-native bindings ..."

#_______________________________________
# @section Configure the Generator Buildsystem
#_____________________________
let genDir      = cfg.dirs.root/"gen"
let genFile_api = genDir/"result.nim"
let genFile_raw = genDir/"result_raw.nim"
let srcDir      = cfg.dirs.src
let trgFile_api = build.srcDir/"wgpu"/"api.nim"
let trgFile_raw = build.srcDir/"wgpu"/"raw.nim"

#_______________________________________
# @section Install Opir if it doesn't exist
#_____________________________
let opir = getEnv("HOME")/".local"/"bin"/"opir"
if not fileExists(opir):
  info &"Opir does not exist at {opir.parentDir()}"
  info "Installing Futhark and Opir ..."
  withDir cfg.dirs.lib/"futhark": sh &"{cfg.nimble.bin} install"
  ln getEnv("HOME")/".nimble"/"bin"/"opir", opir
  info "Done installing Futhark and Opir."

#_______________________________________
# @section Update the Headers to the latest wgpu-trunk commit
#_____________________________
info "Updating the wgpu-native submodule ..."
withDir cfg.dirs.src/"wgpu"/"C"/"wgpu-native": sh "git pull --recurse-submodules origin trunk"


#_______________________________________
# @section Build the generator
#_____________________________
info "Generating the wgpu-native bindings with Futhark ..."
const deps_futhark = Dependencies.new(
  Dependency.new( "futhark",      "https://github.com/PMunch/futhark"      ),
  Dependency.new( "libclang-nim", "https://github.com/PMunch/libclang-nim" ),
  Dependency.new( "termstyle",    "https://github.com/PMunch/termstyle"    ),
  Dependency.new( "macroutils",   "https://github.com/PMunch/macroutils"   ),
  Dependency.new( "nimbleutils",  "https://github.com/PMunch/nimbleutils"  ),
  ) #:: deps_futhark
cfg.dirs.src = genDir
var gen = Program.new(
  entry = "generator.nim",
  deps  = deps_futhark,
  args  = @["--maxLoopIterationsVM:1_000_000_000", "-d:futharkRebuild", "-d:nodeclguards"],
  cfg   = cfg,
  ) #:: Program.new( ... )
confy.build gen
#___________________
info "Generating the raw wgpu-native bindings with Futhark ..."
gen.entry = "generator_raw.nim"
confy.build gen
info "Done creating the bindings."

#_______________________________________
# @section Move the generated output
#_____________________________
cfg.dirs.src = build.srcDir
info &"Outputting the resulting bindings into:  {trgFile_api} and {trgFile_raw}"
let localPath = os.absolutePath(".")
writeFile( genFile_api, readFile(genFile_api).replace(localPath, ".") )
writeFile( genFile_raw, readFile(genFile_raw).replace(localPath, ".") )
cp genFile_api, trgFile_api
cp genFile_raw, trgFile_raw
info "Done generating the wgpu-native bindings."

