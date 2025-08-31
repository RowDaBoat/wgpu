#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
when not defined(nimscript):  import system/nimscript  # Silence nimsuggest errors
import std/[ os, strformat, strutils, sequtils, algorithm ]
# Package
packageName   = "wgpu"
version       = "24.0.3.8"  # First three numbers in sync with wgpu-native
author        = "heysokam, RowDaBoat"
description   = "Native WebGPU for Nim | wgpu-native"
license       = "MIT"
# Project Setup
srcDir        = "src"
binDir        = "bin"
# Build requirements
requires "nim >= 2.0.0"


#_______________________________________
# @section Task Helpers
#_____________________________
let examplesDir = "examples"
proc nimcr (args :varargs[string, `$`]) :void=
  selfExec &"c -r -d:wgpu --verbosity:2 --hints:off --path:{srcDir} --outDir:{binDir} " & args.join(" ")
#___________________
template example (name :untyped; descr,file :static string)=
  ## @descr Generates a task to build+run the given example
  let sname = astToStr(name)  # string name
  taskRequires sname, "https://github.com/heysokam/nglfw#head"
  taskRequires sname, "https://github.com/treeform/vmath#head"
  task name, descr:
    nimcr examplesDir/file

#_______________________________________
# @section Examples
#_____________________________
example wip,       "Example WIP: Builds the current wip example.",  "wip"
example hello,     "Example 00:  hellowgpu.",                       "e00_hellowgpu"
example clear,     "Example 01:  helloclear.",                      "e01_helloclear"
example triangle,  "Example 02:  hellotriangle.",                   "e02_hellotriangle"
# example buffer,    "Example 03:  hellobuffer.",                     "e03_hellobuffer"
# example compute,   "Example 04:  hellocompute.",                    "e04_hellocompute"
# example triangle2, "Example 05:  simple buffered triangle.",        "e05_trianglebuffered1"
# example triangle3, "Example 06:  multi-buffered triangle.",         "e06_trianglebuffered2"
# example triangle4, "Example 07:  indexed multi-buffered triangle.", "e07_trianglebuffered3"
# example uniform,   "Example 08:  single uniform.",                  "e08_hellouniform"
# example struct,    "Example 09:  uniform struct.",                  "e09_uniformstruct"
# # example dynamic,   "Example 10:  uniform struct.",                  "e10_dynamicuniform"
# example texture,   "Example 11:  simple byte texture.",             "e11_hellotexture"
# example texture2,  "Example 12:  sampled byte texture.",            "e12_sampledtexture"
# example depth,     "Example 13:  simple depth buffer attachment.",  "e13_hellodepth"
# example camera,    "Example 14:  simple 3D camera controller.",     "e14_hellocamera"
# example uvs,       "Example 15:  cube textured using its UVs.",     "e15_cubetextured"
# example instance,  "Example 16:  cube instanced 100 times.",        "e16_cubeinstanced"
# example multimesh, "Example 17:  multi-mesh. cubes + pyramid.",     "e17_multimesh"

#_______________________________________
# @section Internal Management
#_____________________________
# Git
task git, "Internal:  Updates the wgpu-native submodule.":
  withDir "src/wgpu/C/wgpu-native": exec "git pull --recurse-submodules origin trunk"
#_____________________________
# Unit Tests
taskRequires "tests", "https://github.com/heysokam/minitest#head"
task tests, "Runs all tests":
  for file in "./tests".walkDirRec.toSeq.reversed:
    if not file.fileExists(): continue
    if not file.splitFile.name.startsWith("t"): continue
    nimcr "--outDir:\"./bin/.tests/\"", file

