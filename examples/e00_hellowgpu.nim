#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# Tests that wgpu loaded correctly.                 |
# Creates a wgpu.Instance and prints its address.   |
# Creates a window that remains open until closed.  |
#___________________________________________________|
# @deps external
from pkg/nglfw as glfw import nil
# @deps wgpu
import wgpu
# @deps examples
import ./extras



#________________________________________________
# window.nim
#__________________
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  if (key == glfw.KeyEscape and action == glfw.Press):
    glfw.setWindowShouldClose(win, true)

#__________________
template getAddr [T](val :T) :string=  cast[ByteAddress](val.addr).repr
  ## Returns the string representation of an address.
  ## Only for readability. Not required by the app.

#________________________________________________
# state.nim
#__________________
var window = Window(
  ct: nil, title: "wgpu | Hello wgpu",
  w:960, h:540,
  )


#________________________________________________
# Entry Point
#__________________
proc run=
  echo "Hello wgpu"
  window.init(key)
  var descriptor = wgpu.InstanceDescriptor(nextInChain: nil)
  var instance   = wgpu.create(descriptor.addr)
  doAssert instance != nil, "Couldn't create the wgpu-native instance."
  echo "wgpu works | Press Escape to close the window."
  echo "           | descriptor address is: ", descriptor.getAddr()
  echo "           | instance   address is: ", instance.getAddr()
  while not window.close():
    window.update()
  window.term()
#__________________
when isMainModule: run()

