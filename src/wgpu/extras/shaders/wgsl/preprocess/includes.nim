#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
## @fileoverview
## `@include` resolver implementation for wgsl shaders.
##  - Resolution is recursive, nested includes will work.
##  - Each file is included only once.
##  - Circular includes are ignored.
##
## On a .wgsl file:
##   Use '@include path/to/your/library_code', without the wgsl extension.
##   The preprocessor will pull 'path/to/your/library_code.wgsl', and all its contents/dependencies, into your shader.
##
## Resolve includes on your nim code with:
## ```nim
## let (resolvedCode, lineAnnotations) = wgsl.includes.resolve("path/to/your/shader.wgsl")
## ```
##
## When compilation fails, the error message can be remapped to proper file names and lines using:
## ```nim
## let remappedError = wgsl.remapErrors(errorMessage, lineAnnotations)
## ```
#______________________________________________________________________|
# @deps std
import std/os
import std/strformat
import std/strutils
import std/sets
import std/re  # FIX: Remove this PCRE dependency completely


#_______________________________________
# @section Types
#_____________________________
type LineAnnotation * = object
  line      *:int
  filename  *:string


#_______________________________________
# @section Include Resolver
#_____________________________
proc resolve_recursive (
    filename : string,
    included : var HashSet[string];
    dirname  : string = filename.splitFile.dir;
  ) :(string, seq[LineAnnotation])=
  if filename in included: return ("", @[])

  included.incl(filename)

  var resolvedCode = ""
  var annotations :seq[LineAnnotation]= @[]
  let code = readFile(filename).split("\n")

  for number, line in code:
    let strippedLine = line.strip()

    if not strippedLine.startsWith("@include"):
      annotations.add(LineAnnotation(line: number + 1, filename: filename))
      resolvedCode &= line & "\n"
    else:
      let toInclude = strippedLine.split(" ")[1].strip()
      let relativeDir = dirname/toInclude.splitFile.dir
      let (includedCode, includedAnnotations) = resolve_recursive(relativeDir/toInclude.addFileExt("wgsl"), included, relativeDir)
      resolvedCode &= includedCode
      annotations.add(includedAnnotations)

  result = (resolvedCode, annotations)
#___________________
proc resolve *(filename :string) :(string, seq[LineAnnotation])=
  ## @descr
  ##  Resolves all @include statements in the {@arg filename} WGSL shader file.
  ##  Returns a tuple containing the resolved shader code and line number mappings.
  var included :HashSet[string]= initHashSet[string]()
  result = resolve_recursive(filename, included)


#_______________________________________
# @section Error remapping
#_____________________________
proc remapError_headers (
    error    : string;
    mappings : seq[LineAnnotation];
  ) :string=
  result = error
  let pattern = re"(wgsl):(\d+):(\d+)"
  var matches: array[3, string]
  var position = 0

  while position < result.len:
    let matchPos = result.find(pattern, matches, position)
    if matchPos == -1: break

    let line   = parseInt(matches[1])
    let column = parseInt(matches[2])

    let beforeMatch = result[0..<matchPos]
    let matchLen    = matches[0].len + matches[1].len + matches[2].len + 2
    let afterMatch  = result[matchPos + matchLen..^1]
    let mapping     = mappings[line - 1]
    let replacement = fmt"{mapping.filename}:{mapping.line}:{column}"

    result = fmt"{beforeMatch}{replacement}{afterMatch}"
    position = matchPos + replacement.len
#___________________
proc remapError_lineNumbers (
    error    : string;
    mappings : seq[LineAnnotation];
  ) :string=
  result = error
  let pattern = re"([ ]*)(\d+)[ ]│"
  var matches: array[2, string]
  var position = 0

  while position < result.len:
    let matchPos = result.find(pattern, matches, position)
    if matchPos == -1: break

    let lineString = matches[1]
    let line       = parseInt(lineString)

    let beforeMatch = result[0..<matchPos]
    let matchLen    = matches[0].len + lineString.len + " │".len
    let afterMatch  = result[matchPos + matchLen..^1]
    let mapping     = mappings[line - 1]

    let padding           = " ".repeat(matchLen)
    let replacement       = fmt"{padding}{mapping.line} │"
    let paddedReplacement = replacement.substr(replacement.len - matchLen, replacement.len - 1)

    result = fmt"{beforeMatch}{paddedReplacement}{afterMatch}"
    position = matchPos + replacement.len
#___________________
proc remapErrors *(
    error    : string;
    mappings : seq[LineAnnotation]
  ) :string=
  ## @descr
  ##  Remaps error messages to reference original source files and line numbers.
  ##  Receives the error message and the line number mappings.
  ##  Returns the remapped error message with correct file references and line numbers.
  result = error
    .remapError_headers(mappings)
    .remapError_lineNumbers(mappings)

