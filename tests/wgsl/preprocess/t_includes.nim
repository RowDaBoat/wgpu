#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________
# @deps std
import std/strutils
import std/os
# @deps wgpu
import wgpu/extras/shaders/wgsl/preprocess/includes
# @deps tests
import minitest
const casesDir = currentSourcePath().parentDir()/"cases"

describe "wgsl.preprocess.includes":
  it "must add the contents of the file in the @include directive":
    # Setup Input & Dependencies
    let includerFilename = casesDir/"include_once.wgsl"
    let includedFilename = casesDir/"singleline.wgsl"
    # Expected Output
    let expectedCode = """
      before
      single line inclusion
      after

      """.dedent()
    let expectedAnnotations = @[
      LineAnnotation(line: 1, filename: includerFilename),
      LineAnnotation(line: 1, filename: includedFilename),
      LineAnnotation(line: 3, filename: includerFilename),
      LineAnnotation(line: 4, filename: includerFilename),
    ]
    # Run the process
    let (resolvedCode, annotations) = resolve(includerFilename)
    # Check the result
    check resolvedCode == expectedCode
    check annotations == expectedAnnotations

  it "must @include the same file only once":
    # Setup Input & Dependencies
    let includerFilename = casesDir/"include_twice.wgsl"
    let includedFilename = casesDir/"singleline.wgsl"
    # Expected Output
    let expectedCode = """
      before
      single line inclusion
      after

      """.dedent()
    let expectedAnnotations = @[
      LineAnnotation(line: 1, filename: includerFilename),
      LineAnnotation(line: 1, filename: includedFilename),
      LineAnnotation(line: 4, filename: includerFilename),
      LineAnnotation(line: 5, filename: includerFilename),
    ]
    # Run the process
    let (resolvedCode, annotations) = resolve(includerFilename)
    # Check the result
    expect resolvedCode == expectedCode
    expect annotations == expectedAnnotations

  it "must properly annotate line numbers":
    # Setup Input & Dependencies
    let includerFilename = casesDir/"include_multiline.wgsl"
    let includedFilename = casesDir/"multiline.wgsl"
    # Expected Output
    let expectedCode = """
      before
      multiple
      lines
      inclusion
      after

      """.dedent()
    let expectedAnnotations = @[
      LineAnnotation(line: 1, filename: includerFilename),
      LineAnnotation(line: 1, filename: includedFilename),
      LineAnnotation(line: 2, filename: includedFilename),
      LineAnnotation(line: 3, filename: includedFilename),
      LineAnnotation(line: 3, filename: includerFilename),
      LineAnnotation(line: 4, filename: includerFilename),
    ]
    # Run the process
    let (resolvedCode, annotations) = resolve(includerFilename)
    # Check the result
    expect resolvedCode == expectedCode
    expect annotations == expectedAnnotations


  it "must ignore circular inclusions for already included files":
    # Setup Input & Dependencies
    let circularInclusionFilename1 = casesDir/"include_circular1.wgsl"
    let circularInclusionFilename2 = casesDir/"include_circular2.wgsl"
    let circularInclusionFilename3 = casesDir/"include_circular3.wgsl"
    # Expected Output
    let expectedCode = """
      begin circular inclusion 1
      begin circular inclusion 2
      begin circular inclusion 3
      end circular inclusion 3

      end circular inclusion 2

      end circular inclusion 1

      """.dedent()
    let expectedAnnotations = @[
      LineAnnotation(line: 1, filename: circularInclusionFilename1),
      LineAnnotation(line: 1, filename: circularInclusionFilename2),
      LineAnnotation(line: 1, filename: circularInclusionFilename3),
      LineAnnotation(line: 3, filename: circularInclusionFilename3),
      LineAnnotation(line: 4, filename: circularInclusionFilename3),
      LineAnnotation(line: 3, filename: circularInclusionFilename2),
      LineAnnotation(line: 4, filename: circularInclusionFilename2),
      LineAnnotation(line: 3, filename: circularInclusionFilename1),
      LineAnnotation(line: 4, filename: circularInclusionFilename1),
    ]
    # Run the process
    let (resolvedCode, annotations) = resolve(circularInclusionFilename1)
    # Check the result
    expect resolvedCode == expectedCode
    expect annotations == expectedAnnotations


  it "must fail to include non-existing files":
    # Setup Input & Dependencies
    let nonExistingFile = "non-existing.wgsl"
    # Sanity Check
    expect nonExistingFile.fileExists() == false
    try:
      # Run the process
      let _ = resolve(nonExistingFile)
      fail()
    except IOError:
      let e = getCurrentException()
      # Check the result
      expect e.msg == "cannot open: " & nonExistingFile
    except CatchableError: fail()

  it "dummy":discard  # FIX: Why is this nonsense required? :puzzled:

