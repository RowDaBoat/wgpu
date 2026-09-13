#:__________________________________________________________
#  webgpunim  |  Copyright (C) WebGPU Nim Authors  |  MIT  :
#:__________________________________________________________
## @fileoverview Native Surface: Creation
#_________________________________________|
# @deps std
import std/sequtils
# @deps external
from pkg/nglfw as glfw import nil
# @deps wgpu
import ../api as wgpu
# @deps wgpu.extras
from ./types as extras import nil
import ./helpers


#_______________________________________
# @section Emscripten (HTML canvas) context creation
#_____________________________
when defined(emscripten):
  proc getSurfaceEmscripten *(instance :Instance; selector :cstring) :Surface=
    ## Creates a wgpu Surface bound to the HTML canvas matched by `selector` (e.g. "#vexel-canvas").
    result = instance.create(vaddr SurfaceDescriptor(
      label       : StringView(),
      nextInChain : cast[ptr ChainedStruct](vaddr EmscriptenSurfaceSourceCanvasHTMLSelector(
        chain     : ChainedStruct(
          next    : nil,
          sType   : SType.EmscriptenSurfaceSourceCanvasHTMLSelector,
          ), #:: chain
        selector  : StringView(data: selector, length: selector.len.csize_t),
        )), #:: nextInChain
      )) #:: instance.createSurface()


#_______________________________________
# @section X11 context creation
#_____________________________
elif defined(linux) and not defined(wayland):
  proc getSurfaceX11 *(instance :Instance; win :glfw.Window) :Surface=
    result = instance.create(vaddr SurfaceDescriptor(
      label       : StringView(),
      nextInChain : cast[ptr ChainedStruct](vaddr SurfaceSourceXlibWindow(
        chain     : ChainedStruct(
          next    : nil,
          sType   : SType.SurfaceSourceXlibWindow,
          ), #:: chain
        display   : glfw.getX11Display(),
        window    : glfw.getX11Window(win).uint32,
        )), #:: nextInChain
      )) #:: instance.createSurface()


#_______________________________________
# @section Wayland context creation
#_____________________________
elif defined(linux) and defined(wayland):
  proc getSurfaceWayland *(instance :Instance; win :glfw.Window) :Surface=
    result = instance.create(vaddr SurfaceDescriptor(
      label       : StringView(),
      nextInChain : cast[ptr ChainedStruct](vaddr SurfaceSourceWaylandSurface(
        chain     : ChainedStruct(
          next    : nil,
          sType   : SType.SurfaceSourceWaylandSurface,
          ), #:: chain
        display   : glfw.getWaylandDisplay(),
        surface   : glfw.getWaylandWindow(win),
        )), #:: nextInChain
      )) #:: instance.createSurface()


#_______________________________________
# @section Windows context creation
#_____________________________
elif defined(windows):
  proc getModuleHandle *(lpModuleName :cstring) :pointer {.importc: "GetModuleHandleW", stdcall, dynlib: "kernel32".}
  proc getSurfaceWin *(instance :Instance; win :glfw.Window) :Surface=
    let hwnd      = glfw.getWin32Window(win)
    let hinstance = getModuleHandle(nil)
    result = instance.create(vaddr SurfaceDescriptor(
      label       : StringView(),
      nextInChain : cast[ptr ChainedStruct](vaddr SurfaceSourceWindowsHWND(
        chain     : ChainedStruct(
          next    : nil,
          sType   : SType.SurfaceSourceWindowsHWND,
          ), #:: chain
        hinstance : hinstance,
        hwnd      : hwnd,
        )) #:: nextInChain
      )) #:: instance.createSurface()

#_______________________________________
# @section Mac context creation
#_____________________________
elif defined(macosx):
  proc getSurfaceMac *(instance :Instance; win :glfw.Window) :Surface=
    when not declared(glfw.getMetalLayer): {.error: """

      getMetalLayer must be defined to use the wgpu.getSurfaceMac() helper functions.
      -d:wgpu and nglfw must be added to your project to use it.
      You might just be missing -d:wgpu in your compile options (define pragmas are buggy on macosx)
      """.}
    result = instance.create(vaddr SurfaceDescriptor(
      label       : StringView(),
      nextInChain : cast[ptr ChainedStruct](vaddr SurfaceSourceMetalLayer(
        chain     : ChainedStruct(
          next    : nil,
          sType   : SType.SurfaceSourceMetalLayer,
          ), #:: chain
        layer     : glfw.getMetalLayer(win),
        )), #:: nextInChain
      )) #:: instance.createSurface()


#_______________________________________
# @section Native Surface: Any system
#_____________________________
when not defined(emscripten):
  proc getSurface *(instance :Instance; win :glfw.Window) :Surface=
    ## Gets the surface of the window for the given wgpu instance.
    ## Returns the appropriate native surface based on the system.
    when defined(linux) and not defined(wayland):
      result = instance.getSurfaceX11(win)
    elif defined(linux) and defined(wayland):
      {.warning: "Wayland Surface support has not been tested yet".}
      result = instance.getSurfaceWayland(win)
    elif defined(windows):
      result = instance.getSurfaceWin(win)
    elif defined(macosx):
      result = instance.getSurfaceMac(win)
    else:
      {.error: "Surface creation for this platform is currently not supported".}


#_______________________________________
# @section Information
#_____________________________
proc formats *(caps :SurfaceCapabilities) :seq[TextureFormat]=
  ## @descr Returns a seq of the formats supported by the surface described by {@arg caps}
  result = newSeqWith(caps.formatCount.int, TextureFormat 0)
  for id in 0..<caps.formatCount: result[id] = cast[ptr UncheckedArray[TextureFormat]](caps.formats)[id]
#___________________
proc presentModes *(caps :SurfaceCapabilities) :seq[PresentMode]=
  ## @descr Returns a seq of the present modes supported by the surface described by {@arg caps}
  result = newSeqWith(caps.presentModeCount.int, PresentMode 0)
  for id in 0..<caps.presentModeCount: result[id] = cast[ptr UncheckedArray[PresentMode]](caps.presentModes)[id]
#___________________
proc alphaModes *(caps :SurfaceCapabilities) :seq[CompositeAlphaMode]=
  ## @descr Returns a seq of the composite alpha modes supported by the surface described by {@arg caps}
  result = newSeqWith(caps.alphaModeCount.int, CompositeAlphaMode 0)
  for id in 0..<caps.alphaModeCount: result[id] = cast[ptr UncheckedArray[CompositeAlphaMode]](caps.alphaModes)[id]
#___________________
proc capabilities *(
    surface : Surface;
    adapter : Adapter;
  ) :extras.SurfaceCapabilities=
  ## @descr Returns the capabilities supported by the surface as a tuple of (seq[textureFormats], seq[presentModes], seq[alphaModes])
  var caps :wgpu.SurfaceCapabilities
  let status = surface.get(adapter, caps.addr)
  if status != Success: raise newException(extras.SurfaceError, "Failed to get the capabilities of the surface: " & $status)
  result.usages       = extras.toTextureUsage(caps.usages)
  result.formats      = caps.formats()
  result.presentModes = caps.presentModes()
  result.alphaModes   = caps.alphaModes()
  caps.freeMembers()
