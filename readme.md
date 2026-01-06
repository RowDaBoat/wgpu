![wgpu](./doc/res/gh_banner.png)
# wgpu bindings for Nim
## How to
1. Install requirements: `rust`, `git`, `nim`  
2. Install the bindings with `nimble install https://github.com/heysokam/wgpu`, or add them to your project's nimble file  
3. Use `import wgpu` to access the wgpu bindings.  

I highly recommend to follow [Learn WebGPU C++](https://eliemichel.github.io/LearnWebGPU/) for learning the API.  
It's the best newbie-friendly tutorial out there for wgpu, and it doesn't require knowing TypeScript or Rust.  
_As a reference, it is easier to follow than the infamous Learn OpenGL, in my opinion._  

## Current state and todo
- [x] Wrapper for wgpu-native latest
- [x] Rename system
  - [x] Raw api access  _(for those who don't like the renames)_
  - [x] Shortened `camelCase` for Function names
- [x] Linux suppport
- [x] Mac support
- [x] Windows support
- [ ] Web support (wasm with emscripten)  
      _(note: not planned. send a PR if you figure it out)_

## Build Info
### Requirements  (manually installed by the user)
- [Rust](https://rust-lang.org/)
- [LLVM](https://rust-lang.github.io/rust-bindgen/requirements.html)
- [MSBuild](https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild?view=visualstudio&viewFallbackFrom=vs-2019)
- [Windows SDK and MSVC](https://learn.microsoft.com/en-us/windows/apps/windows-sdk/)
- [nglfw](https://github.com/RowDaBoat/nglfw): for extra features provided at `wgpu/extras`
- [Make](https://gnuwin32.sourceforge.net/packages/make.htm)
- [CMake](https://cmake.org/)

### Static Linking
This library is compiled automatically and linked statically when importing.  
> _Dynamic linking is not supported in the automated builder (and not planned),_  
> _but will work if you provide support for it in your buildsystem._  


## Disclaimers and Other Info
### About bindings generation
This wrapper is auto-generated with Futhark.  
Most names are renamed with a Callback function for ergonomics.  

See the @[gen/cfg](./gen/cfg.nim) file for a detailed list for renaming rules.  
Use the raw api @[wgpu/raw](./src/wgpu/raw.nim) for access to the verbatim C names.  
Use the api @[wgpu](./src/wgpu.nim) for access to the standard Nim-mified names and extras.  

### About the buildsystem
The buildsystem of this lib depends on cargo and git.  
They will be called automatically when you build your project.  
