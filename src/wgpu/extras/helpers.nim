#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
## @fileoverview General Purpose Helpers
#________________________________________|

template vaddr *(val :auto) :untyped=
  ## @descr
  ##  Returns the `addr` of anything, through a temp val.
  ##  Useful when the objects have not been created yet.
  let temp = val; temp.unsafeAddr
#___________________
template iaddr *[T](num :SomeUnsignedInt) :ptr T=
  ## @descr
  ##  Returns the SignedInt `addr` of an UnsignedInt.
  ##  Useful for C interop. Equivalent to `(int*)&someUint`
  when T isnot SomeSignedInt: {.fatal: "iaddr can only be used to get SignedInt addresses".}
  cast[ptr T](num.addr)
#___________________
template iaddr *(num :uint32) :ptr int32=  cast[ptr int32](num.addr)
  ## @descr
  ##  Explicit instantiation of iaddr[T] for uint32-to-int32.
  ##  Returns the int32 `addr` of an uint32.
  ##  Useful for C interop. Equivalent to `(int32_t*)&someUint32`

