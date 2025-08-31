#:___________________________________________________
#  wgpu  |  Copyright (C) Nim wgpu Authors  |  MIT  :
#:___________________________________________________

const  # Not Used, reference only : Undefined Limits are set with `type.high`
  MaxVertexAttributes      * = 16
  UndefinedArrayLayerCount * = 0xffffffff          # define WGPU_ARRAY_LAYER_COUNT_UNDEFINED (0xffffffffUL)
  UndefinedCopyStride      * = 0xffffffff          # define WGPU_COPY_STRIDE_UNDEFINED       (0xffffffffUL)
  UndefinedLimitU32        * = 0xffffffff          # define WGPU_LIMIT_U32_UNDEFINED         (0xffffffffUL)
  UndefinedLimitU64        * = 0xffffffffffffffff  # define WGPU_LIMIT_U64_UNDEFINED         (0xffffffffffffffffULL)
  UndefinedMipLevelCount   * = 0xffffffff          # define WGPU_MIP_LEVEL_COUNT_UNDEFINED   (0xffffffffUL)
  WholeMapSize             * = csize_t.high        # define WGPU_WHOLE_MAP_SIZE              SIZE_MAX
  WholeSize                * = 0xffffffffffffffff  # define WGPU_WHOLE_SIZE                  (0xffffffffffffffffULL)

