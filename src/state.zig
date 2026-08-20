//! Global OpenGL ES 3.0 state: capabilities, state queries, version strings
//! and hints.
//!
//! This namespace groups everything that deals with the global (context-wide)
//! state of OpenGL. Capability switches are typed with [`Capability`](Capability),
//! queryable parameters with [`GetPName`](GetPName), and version/renderer
//! strings with [`StringName`](StringName).

const loader = @import("loader.zig");
const types = @import("types.zig");

/// A boolean capability of the context, enabled or disabled with
/// [`enable`](enable)/[`disable`](disable) (`GL_BLEND`, `GL_DEPTH_TEST`, ...).
pub const Capability = enum(u32) {
    /// Blend the computed fragment color with the destination color
    /// (`GL_BLEND`).
    blend = 0x0BE2,

    /// Discard back-facing polygons (`GL_CULL_FACE`).
    cullFace = 0x0B44,

    /// Enable the depth test (`GL_DEPTH_TEST`).
    depth_test = 0x0B71,

    /// Dither color components before writing them to the framebuffer
    /// (`GL_DITHER`).
    dither = 0x0BD0,

    /// Apply a depth offset to filled polygons (`GL_POLYGON_OFFSET_FILL`).
    polygon_offset_fill = 0x8037,

    /// Enable alpha-to-coverage multisampling (`GL_SAMPLE_ALPHA_TO_COVERAGE`).
    sample_alpha_to_coverage = 0x809E,

    /// Enable per-sample coverage (`GL_SAMPLE_COVERAGE`).
    sampleCoverage = 0x80A0,

    /// Restrict writes to the scissor rectangle (`GL_SCISSOR_TEST`).
    scissor_test = 0x0C11,

    /// Enable the stencil test (`GL_STENCIL_TEST`).
    stencil_test = 0x0B90,

    /// Discard all fragments produced by rasterization (`GL_RASTERIZER_DISCARD`).
    rasterizer_discard = 0x8C89,

    /// Treat the first fixed-index vertex as a primitive restart point
    /// (`GL_PRIMITIVE_RESTART_FIXED_INDEX`).
    primitive_restart_fixed_index = 0x8D69,
};

/// Version and vendor strings returned by [`getString`](getString)
/// (`GL_VENDOR`, `GL_RENDERER`, ...).
pub const StringName = enum(u32) {
    /// Vendor of the OpenGL implementation (`GL_VENDOR`).
    vendor = 0x1F00,

    /// Name of the renderer (`GL_RENDERER`).
    renderer = 0x1F01,

    /// Version string of the OpenGL context (`GL_VERSION`).
    version = 0x1F02,

    /// Version string of the GLSL shading language (`GL_SHADING_LANGUAGE_VERSION`).
    shading_language_version = 0x8B8C,

    /// Space-separated list of supported extensions (`GL_EXTENSIONS`).
    extensions = 0x1F03,
};

/// Hint target, i.e. an aspect of the implementation that may be tuned with
/// [`hint`](hint).
pub const HintTarget = enum(u32) {
    /// Quality and performance of automatic mipmap generation
    /// (`GL_GENERATE_MIPMAP_HINT`).
    generateMipmap = 0x8192,

    /// Accuracy of derivative computation in the fragment shader
    /// (`GL_FRAGMENT_SHADER_DERIVATIVE_HINT`).
    fragment_shader_derivative = 0x8B8B,
};

/// Hint mode: how aggressively the implementation should trade quality for
/// performance for a given [`HintTarget`](HintTarget).
pub const HintMode = enum(u32) {
    /// Use the fastest implementation option (`GL_FASTEST`).
    fastest = 0x1101,

    /// Use the highest-quality implementation option (`GL_NICEST`).
    nicest = 0x1102,

    /// No preference (`GL_DONT_CARE`).
    dont_care = 0x1100,
};

/// A parameter of the global state read via the typed getter functions
/// ([`getInteger`](getInteger), [`getFloat`](getFloat), ...).
///
/// Not every parameter can be queried with every getter: e.g. float-only
/// values such as `GL_ALIASED_LINE_WIDTH_RANGE` are returned by
/// [`getFloat`](getFloat), and the driver raises an error if such a
/// parameter is requested via [`getInteger`](getInteger).
pub const GetPName = enum(u32) {
    /// Active texture unit for 2D operations (`GL_ACTIVE_TEXTURE`).
    activeTexture = 0x84E0,

    /// Range of supported line widths ([`float`], `GL_ALIASED_LINE_WIDTH_RANGE`).
    aliased_line_width_range = 0x846E,

    /// Range of supported point sizes ([`float`], `GL_ALIASED_POINT_SIZE_RANGE`).
    aliased_point_size_range = 0x846D,

    /// Number of alpha bitplanes in the color buffer of the currently bound
    /// draw framebuffer (`GL_ALPHA_BITS`).
    alpha_bits = 0x0D55,

    /// Name of the buffer bound to `GL_ARRAY_BUFFER` (`GL_ARRAY_BUFFER_BINDING`).
    array_buffer_binding = 0x8894,

    /// Current blending state (`bool`, `GL_BLEND`).
    blend = 0x0BE2,

    /// Constant blending color ([`float`] ×4, `GL_BLEND_COLOR`).
    blendColor = 0x8005,

    /// Destination alpha blend factor of the alpha component
    /// (`GL_BLEND_DST_ALPHA`).
    blend_dst_alpha = 0x80CA,

    /// Destination RGB blend factor of the RGB components
    /// (`GL_BLEND_DST_RGB`).
    blend_dst_rgb = 0x80C8,

    /// Blend equation of the alpha component (`GL_BLEND_EQUATION_ALPHA`).
    blend_equation_alpha = 0x883D,

    /// Blend equation of the RGB components (`GL_BLEND_EQUATION_RGB`).
    blend_equation_rgb = 0x8009,

    /// Source alpha blend factor of the alpha component
    /// (`GL_BLEND_SRC_ALPHA`).
    blend_src_alpha = 0x80CB,

    /// Source RGB blend factor of the RGB components (`GL_BLEND_SRC_RGB`).
    blend_src_rgb = 0x80C9,

    /// Number of blue bitplanes in the color buffer of the currently bound
    /// draw framebuffer (`GL_BLUE_BITS`).
    blue_bits = 0x0D54,

    /// Color used by [`clear.clear`](clear.clear)
    /// ([`float`] ×4, `GL_COLOR_CLEAR_VALUE`).
    color_clear_value = 0x0C22,

    /// Per-channel write mask of the color buffer
    /// ([`boolean`] ×4, `GL_COLOR_WRITEMASK`).
    color_writemask = 0x0C23,

    /// List of supported compressed texture formats (`GL_COMPRESSED_TEXTURE_FORMATS`).
    compressed_texture_formats = 0x86A3,

    /// Whether new fragments are culled by `GL_CULL_FACE` (`bool`, `GL_CULL_FACE`).
    cullFace = 0x0B44,

    /// Face currently culled ([`Face`](enums.Face), `GL_CULL_FACE_MODE`).
    cull_face_mode = 0x0B45,

    /// Name of the program in use (`GL_CURRENT_PROGRAM`).
    current_program = 0x8B8D,

    /// Name of the active query of the current target (`GL_CURRENT_QUERY`).
    current_query = 0x8865,

    /// Generic vertex attribute values of the current vertex
    /// ([`float`] ×4, `GL_CURRENT_VERTEX_ATTRIB`).
    current_vertex_attrib = 0x8626,

    /// Number of bitplanes in the depth buffer of the currently bound
    /// framebuffer (`GL_DEPTH_BITS`).
    depth_bits = 0x0D56,

    /// Value used by [`clear.clear`](clear.clear) for the depth buffer
    /// ([`float`], `GL_DEPTH_CLEAR_VALUE`).
    depth_clear_value = 0x0B73,

    /// Depth comparison function ([`Comparison`](enums.Comparison),
    /// `GL_DEPTH_FUNC`).
    depthFunc = 0x0B74,

    /// Distance range of the depth buffer ([`float`] ×2, `GL_DEPTH_RANGE`).
    depthRange = 0x0B70,

    /// Whether the depth test is enabled (`bool`, `GL_DEPTH_TEST`).
    depth_test = 0x0B71,

    /// Write mask of the depth buffer ([`boolean`], `GL_DEPTH_WRITEMASK`).
    depth_writemask = 0x0B72,

    /// Whether dithering is enabled (`bool`, `GL_DITHER`).
    dither = 0x0BD0,

    /// Destination buffer of fragment output 0 (see
    /// [`drawBuffers`](state.drawBuffers), `GL_DRAW_BUFFER0`).
    draw_buffer0 = 0x8825,

    /// Destination buffer of fragment output 1 (`GL_DRAW_BUFFER1`).
    draw_buffer1 = 0x8826,

    /// Destination buffer of fragment output 2 (`GL_DRAW_BUFFER2`).
    draw_buffer2 = 0x8827,

    /// Destination buffer of fragment output 3 (`GL_DRAW_BUFFER3`).
    draw_buffer3 = 0x8828,

    /// Destination buffer of fragment output 4 (`GL_DRAW_BUFFER4`).
    draw_buffer4 = 0x8829,

    /// Destination buffer of fragment output 5 (`GL_DRAW_BUFFER5`).
    draw_buffer5 = 0x882A,

    /// Destination buffer of fragment output 6 (`GL_DRAW_BUFFER6`).
    draw_buffer6 = 0x882B,

    /// Destination buffer of fragment output 7 (`GL_DRAW_BUFFER7`).
    draw_buffer7 = 0x882C,

    /// Destination buffer of fragment output 8 (`GL_DRAW_BUFFER8`).
    draw_buffer8 = 0x882D,

    /// Destination buffer of fragment output 9 (`GL_DRAW_BUFFER9`).
    draw_buffer9 = 0x882E,

    /// Destination buffer of fragment output 10 (`GL_DRAW_BUFFER10`).
    draw_buffer10 = 0x882F,

    /// Destination buffer of fragment output 11 (`GL_DRAW_BUFFER11`).
    draw_buffer11 = 0x8830,

    /// Destination buffer of fragment output 12 (`GL_DRAW_BUFFER12`).
    draw_buffer12 = 0x8831,

    /// Destination buffer of fragment output 13 (`GL_DRAW_BUFFER13`).
    draw_buffer13 = 0x8832,

    /// Destination buffer of fragment output 14 (`GL_DRAW_BUFFER14`).
    draw_buffer14 = 0x8833,

    /// Destination buffer of fragment output 15 (`GL_DRAW_BUFFER15`).
    draw_buffer15 = 0x8834,

    /// Name of the buffer bound to `GL_ELEMENT_ARRAY_BUFFER`
    /// (`GL_ELEMENT_ARRAY_BUFFER_BINDING`).
    element_array_buffer_binding = 0x8895,

    /// Name of the framebuffer bound to `GL_FRAMEBUFFER`
    /// (`GL_FRAMEBUFFER_BINDING`).
    framebuffer_binding = 0x8CA6,

    /// Current front-face winding mode ([`FrontFaceDirection`](rasterization.FrontFaceDirection),
    /// `GL_FRONT_FACE`).
    frontFace = 0x0B46,

    /// Mipmap generation hint (`GL_GENERATE_MIPMAP_HINT`).
    generate_mipmap_hint = 0x8192,

    /// Number of green bitplanes in the color buffer of the currently bound
    /// draw framebuffer (`GL_GREEN_BITS`).
    green_bits = 0x0D53,

    /// Preferred format for raw framebuffer reads (`GL_IMPLEMENTATION_COLOR_READ_FORMAT`).
    implementation_color_read_format = 0x8B9B,

    /// Preferred type for raw framebuffer reads (`GL_IMPLEMENTATION_COLOR_READ_TYPE`).
    implementation_color_read_type = 0x8B9A,

    /// Current line width ([`float`], `GL_LINE_WIDTH`).
    lineWidth = 0x0B21,

    /// Major context version (e.g. `3`, `GL_MAJOR_VERSION`).
    major_version = 0x821B,

    /// Minor context version (e.g. `0`, `GL_MINOR_VERSION`).
    minor_version = 0x821C,

    /// Maximum size of a 3D texture dimension (`GL_MAX_3D_TEXTURE_SIZE`).
    max_3d_texture_size = 0x8073,

    /// Maximum number of layers in an array texture (`GL_MAX_ARRAY_TEXTURE_LAYERS`).
    max_array_texture_layers = 0x88FF,

    /// Maximum number of color attachments of a framebuffer
    /// (`GL_MAX_COLOR_ATTACHMENTS`).
    max_color_attachments = 0x8CDF,

    /// Maximum number of uniform components available to the fragment shader
    /// (`GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS`).
    max_combined_fragment_uniform_components = 0x8A33,

    /// Maximum number of texture units available to the shaders
    /// (`GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS`).
    max_combined_texture_image_units = 0x8B4D,

    /// Maximum number of uniform blocks available to the shaders
    /// (`GL_MAX_COMBINED_UNIFORM_BLOCKS`).
    max_combined_uniform_blocks = 0x8A2E,

    /// Maximum number of uniform components available to the vertex shader
    /// (`GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS`).
    max_combined_vertex_uniform_components = 0x8A31,

    /// Maximum size of a cube map face dimension (`GL_MAX_CUBE_MAP_TEXTURE_SIZE`).
    max_cube_map_texture_size = 0x851C,

    /// Maximum number of draw buffers (`GL_MAX_DRAW_BUFFERS`).
    max_draw_buffers = 0x8824,

    /// Maximum value of the index used in indexed drawing (`GL_MAX_ELEMENT_INDEX`).
    max_element_index = 0x8D6B,

    /// Maximum number of indices in a single draw call (`GL_MAX_ELEMENTS_INDICES`).
    max_elements_indices = 0x80E9,

    /// Maximum number of vertices in a single draw call (`GL_MAX_ELEMENTS_VERTICES`).
    max_elements_vertices = 0x80E8,

    /// Maximum number of inputs of the fragment shader (`GL_MAX_FRAGMENT_INPUT_COMPONENTS`).
    max_fragment_input_components = 0x9125,

    /// Maximum number of uniform blocks of the fragment shader
    /// (`GL_MAX_FRAGMENT_UNIFORM_BLOCKS`).
    max_fragment_uniform_blocks = 0x8A2D,

    /// Maximum number of uniform components in the fragment shader
    /// (`GL_MAX_FRAGMENT_UNIFORM_COMPONENTS`).
    max_fragment_uniform_components = 0x8B49,

    /// Maximum number of uniform vectors in the fragment shader
    /// (`GL_MAX_FRAGMENT_UNIFORM_VECTORS`).
    max_fragment_uniform_vectors = 0x8DFD,

    /// Maximum texel offset for texture sampling (`GL_MAX_PROGRAM_TEXEL_OFFSET`).
    max_program_texel_offset = 0x8905,

    /// Maximum size of a renderbuffer dimension (`GL_MAX_RENDERBUFFER_SIZE`).
    max_renderbuffer_size = 0x84E8,

    /// Maximum number of samples per pixel (`GL_MAX_SAMPLES`).
    max_samples = 0x8D57,

    /// Maximum timeout of `glClientWaitSync` ([`int64`], `GL_MAX_SERVER_WAIT_TIMEOUT`).
    max_server_wait_timeout = 0x9111,

    /// Maximum number of texture image units available to the fragment shader
    /// (`GL_MAX_TEXTURE_IMAGE_UNITS`).
    max_texture_image_units = 0x8872,

    /// Maximum absolute value of the texture LOD bias (`GL_MAX_TEXTURE_LOD_BIAS`).
    max_texture_lod_bias = 0x84FD,

    /// Maximum size of a 2D texture dimension (`GL_MAX_TEXTURE_SIZE`).
    max_texture_size = 0x0D33,

    /// Maximum number of interleaved transform feedback components
    /// (`GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS`).
    max_transform_feedback_interleaved_components = 0x8C8A,

    /// Maximum number of transform feedback attributes
    /// (`GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS`).
    max_transform_feedback_separate_attribs = 0x8C8B,

    /// Maximum number of separate transform feedback components
    /// (`GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS`).
    max_transform_feedback_separate_components = 0x8C80,

    /// Maximum size of a uniform block in bytes (`GL_MAX_UNIFORM_BLOCK_SIZE`).
    max_uniform_block_size = 0x8A30,

    /// Maximum number of uniform buffer binding points
    /// (`GL_MAX_UNIFORM_BUFFER_BINDINGS`).
    max_uniform_buffer_bindings = 0x8A2F,

    /// Maximum number of varying components (alias for
    /// `GL_MAX_VARYING_FLOATS`, `GL_MAX_VARYING_COMPONENTS`).
    max_varying_components = 0x8B4B,

    /// Maximum number of varying vectors (`GL_MAX_VARYING_VECTORS`).
    max_varying_vectors = 0x8DFC,

    /// Maximum number of generic vertex attributes (`GL_MAX_VERTEX_ATTRIBS`).
    max_vertex_attribs = 0x8869,

    /// Maximum number of outputs of the vertex shader (`GL_MAX_VERTEX_OUTPUT_COMPONENTS`).
    max_vertex_output_components = 0x9122,

    /// Maximum number of texture image units available to the vertex shader
    /// (`GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS`).
    max_vertex_texture_image_units = 0x8B4C,

    /// Maximum number of uniform blocks of the vertex shader
    /// (`GL_MAX_VERTEX_UNIFORM_BLOCKS`).
    max_vertex_uniform_blocks = 0x8A2B,

    /// Maximum number of uniform components in the vertex shader
    /// (`GL_MAX_VERTEX_UNIFORM_COMPONENTS`).
    max_vertex_uniform_components = 0x8B4A,

    /// Maximum number of uniform vectors in the vertex shader
    /// (`GL_MAX_VERTEX_UNIFORM_VECTORS`).
    max_vertex_uniform_vectors = 0x8DFB,

    /// Maximum dimensions of the viewport ([`float`] ×2, `GL_MAX_VIEWPORT_DIMS`).
    max_viewport_dims = 0x0D3A,

    /// Minimum texel offset for texture sampling (`GL_MIN_PROGRAM_TEXEL_OFFSET`).
    min_program_texel_offset = 0x8904,

    /// Number of supported compressed texture formats
    /// (`GL_NUM_COMPRESSED_TEXTURE_FORMATS`).
    num_compressed_texture_formats = 0x86A2,

    /// Number of extensions (`GL_NUM_EXTENSIONS`).
    num_extensions = 0x821D,

    /// Number of supported program binary formats (`GL_NUM_PROGRAM_BINARY_FORMATS`).
    num_program_binary_formats = 0x87FE,

    /// Number of usable sample counts (`GL_NUM_SAMPLE_COUNTS`).
    num_sample_counts = 0x9380,

    /// Number of supported shader binary formats (`GL_NUM_SHADER_BINARY_FORMATS`).
    num_shader_binary_formats = 0x8DF9,

    /// Byte alignment used when packing pixel data ([`integer`], `GL_PACK_ALIGNMENT`).
    pack_alignment = 0x0D05,

    /// Row length used when packing pixel data (`GL_PACK_ROW_LENGTH`).
    pack_row_length = 0x0D02,

    /// Number of pixels skipped at the start of each row when packing
    /// (`GL_PACK_SKIP_PIXELS`).
    pack_skip_pixels = 0x0D04,

    /// Number of rows skipped when packing pixel data (`GL_PACK_SKIP_ROWS`).
    pack_skip_rows = 0x0D03,

    /// Name of the buffer bound to `GL_PIXEL_PACK_BUFFER`
    /// (`GL_PIXEL_PACK_BUFFER_BINDING`).
    pixel_pack_buffer_binding = 0x88ED,

    /// Name of the buffer bound to `GL_PIXEL_UNPACK_BUFFER`
    /// (`GL_PIXEL_UNPACK_BUFFER_BINDING`).
    pixel_unpack_buffer_binding = 0x88EF,

    /// Depth offset factor ([`float`], `GL_POLYGON_OFFSET_FACTOR`).
    polygon_offset_factor = 0x8038,

    /// Whether `GL_POLYGON_OFFSET_FILL` is enabled (`bool`,
    /// `GL_POLYGON_OFFSET_FILL`).
    polygon_offset_fill = 0x8037,

    /// Depth offset units ([`float`], `GL_POLYGON_OFFSET_UNITS`).
    polygon_offset_units = 0x2A00,

    /// List of supported program binary formats (`GL_PROGRAM_BINARY_FORMATS`).
    program_binary_formats = 0x87FF,

    /// Number of red bitplanes in the color buffer of the currently bound
    /// draw framebuffer (`GL_RED_BITS`).
    red_bits = 0x0D52,

    /// Name of the renderbuffer bound to `GL_RENDERBUFFER`
    /// (`GL_RENDERBUFFER_BINDING`).
    renderbuffer_binding = 0x8CA7,

    /// Name of the sampler bound to the active texture unit
    /// (`GL_SAMPLER_BINDING`).
    sampler_binding = 0x8919,

    /// Whether `GL_SAMPLE_ALPHA_TO_COVERAGE` is enabled (`bool`,
    /// `GL_SAMPLE_ALPHA_TO_COVERAGE`).
    sample_alpha_to_coverage = 0x809E,

    /// Number of multisample buffers in the default framebuffer
    /// (`GL_SAMPLE_BUFFERS`).
    sample_buffers = 0x80A8,

    /// Whether `GL_SAMPLE_COVERAGE` is enabled (`bool`, `GL_SAMPLE_COVERAGE`).
    sampleCoverage = 0x80A0,

    /// Whether sample coverage is inverted ([`boolean`],
    /// `GL_SAMPLE_COVERAGE_INVERT`).
    sample_coverage_invert = 0x80AB,

    /// Sample coverage value ([`float`], `GL_SAMPLE_COVERAGE_VALUE`).
    sample_coverage_value = 0x80AA,

    /// Number of samples in the default framebuffer (`GL_SAMPLES`).
    samples = 0x80A9,

    /// Scissor rectangle ([`integer`] ×4, `GL_SCISSOR_BOX`).
    scissor_box = 0x0C10,

    /// Whether the scissor test is enabled (`bool`, `GL_SCISSOR_TEST`).
    scissor_test = 0x0C11,

    /// Whether a shader compiler is available ([`boolean`],
    /// `GL_SHADER_COMPILER`).
    shader_compiler = 0x8DFA,

    /// List of supported shader binary formats (`GL_SHADER_BINARY_FORMATS`).
    shader_binary_formats = 0x8DF8,

    /// Stencil fail operation for the back faces (`GL_STENCIL_BACK_FAIL`).
    stencil_back_fail = 0x8801,

    /// Stencil function for the back faces (`GL_STENCIL_BACK_FUNC`).
    stencil_back_func = 0x8800,

    /// Depth-fail stencil operation for the back faces
    /// (`GL_STENCIL_BACK_PASS_DEPTH_FAIL`).
    stencil_back_pass_depth_fail = 0x8802,

    /// Depth-pass stencil operation for the back faces
    /// (`GL_STENCIL_BACK_PASS_DEPTH_PASS`).
    stencil_back_pass_depth_pass = 0x8803,

    /// Stencil reference value for the back faces (`GL_STENCIL_BACK_REF`).
    stencil_back_ref = 0x8CA3,

    /// Stencil value mask for the back faces (`GL_STENCIL_BACK_VALUE_MASK`).
    stencil_back_value_mask = 0x8CA4,

    /// Stencil write mask for the back faces (`GL_STENCIL_BACK_WRITEMASK`).
    stencil_back_writemask = 0x8CA5,

    /// Number of bitplanes in the stencil buffer of the currently bound
    /// framebuffer (`GL_STENCIL_BITS`).
    stencil_bits = 0x0D57,

    /// Value used by [`clear.clear`](clear.clear) for the stencil buffer
    /// ([`integer`], `GL_STENCIL_CLEAR_VALUE`).
    stencil_clear_value = 0x0B91,

    /// Stencil fail operation for the front faces ([`StencilOp`](stencil.StencilOp),
    /// `GL_STENCIL_FAIL`).
    stencil_fail = 0x0B94,

    /// Stencil function for the front faces ([`Comparison`](enums.Comparison),
    /// `GL_STENCIL_FUNC`).
    stencilFunc = 0x0B92,

    /// Depth-fail stencil operation for the front faces
    /// ([`StencilOp`](stencil.StencilOp), `GL_STENCIL_PASS_DEPTH_FAIL`).
    stencil_pass_depth_fail = 0x0B95,

    /// Depth-pass stencil operation for the front faces
    /// ([`StencilOp`](stencil.StencilOp), `GL_STENCIL_PASS_DEPTH_PASS`).
    stencil_pass_depth_pass = 0x0B96,

    /// Stencil reference value for the front faces (`GL_STENCIL_REF`).
    stencil_ref = 0x0B97,

    /// Whether the stencil test is enabled (`bool`, `GL_STENCIL_TEST`).
    stencil_test = 0x0B90,

    /// Stencil value mask for the front faces (`GL_STENCIL_VALUE_MASK`).
    stencil_value_mask = 0x0B93,

    /// Stencil write mask for the front faces (`GL_STENCIL_WRITEMASK`).
    stencil_writemask = 0x0B98,

    /// Name of the 2D texture bound to the active texture unit
    /// (`GL_TEXTURE_BINDING_2D`).
    texture_binding_2d = 0x8069,

    /// Name of the 2D array texture bound to the active texture unit
    /// (`GL_TEXTURE_BINDING_2D_ARRAY`).
    texture_binding_2d_array = 0x8C1D,

    /// Name of the 3D texture bound to the active texture unit
    /// (`GL_TEXTURE_BINDING_3D`).
    texture_binding_3d = 0x806A,

    /// Name of the cube map texture bound to the active texture unit
    /// (`GL_TEXTURE_BINDING_CUBE_MAP`).
    texture_binding_cube_map = 0x8514,

    /// Whether transform feedback is active ([`boolean`],
    /// `GL_TRANSFORM_FEEDBACK_ACTIVE`).
    transform_feedback_active = 0x8E24,

    /// Name of the transform feedback object bound to `GL_TRANSFORM_FEEDBACK`
    /// (`GL_TRANSFORM_FEEDBACK_BINDING`).
    transform_feedback_binding = 0x8E25,

    /// Name of the buffer bound to `GL_TRANSFORM_FEEDBACK_BUFFER`
    /// (`GL_TRANSFORM_FEEDBACK_BUFFER_BINDING`).
    transform_feedback_buffer_binding = 0x8C8F,

    /// Whether transform feedback is paused ([`boolean`],
    /// `GL_TRANSFORM_FEEDBACK_PAUSED`).
    transform_feedback_paused = 0x8E23,

    /// Name of the buffer bound to `GL_UNIFORM_BUFFER`
    /// (`GL_UNIFORM_BUFFER_BINDING`).
    uniform_buffer_binding = 0x8A28,

    /// Alignment of uniform buffer offsets in bytes (`GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT`).
    uniform_buffer_offset_alignment = 0x8A34,

    /// Byte alignment used when unpacking pixel data ([`integer`],
    /// `GL_UNPACK_ALIGNMENT`).
    unpack_alignment = 0x0CF5,

    /// Row length used when unpacking pixel data (`GL_UNPACK_ROW_LENGTH`).
    unpack_row_length = 0x0CF2,

    /// Number of pixels skipped at the start of each row when unpacking
    /// (`GL_UNPACK_SKIP_PIXELS`).
    unpack_skip_pixels = 0x0CF4,

    /// Number of rows skipped when unpacking pixel data (`GL_UNPACK_SKIP_ROWS`).
    unpack_skip_rows = 0x0CF3,

    /// Viewport rectangle ([`integer`] ×4, `GL_VIEWPORT`).
    viewport = 0x0BA2,
};

/// Enables the given capability (`GL_BLEND`, `GL_DEPTH_TEST`, ...).
///
/// ```
/// gl.state.enable(.depth_test);
/// gl.state.enable(.blend);
/// ```
pub fn enable(cap: Capability) void {
    loader.context.enable(@intFromEnum(cap));
}

/// Disables the given capability.
pub fn disable(cap: Capability) void {
    loader.context.disable(@intFromEnum(cap));
}

/// Returns whether the given capability is currently enabled.
pub fn isEnabled(cap: Capability) bool {
    return loader.context.isEnabled(@intFromEnum(cap)) != 0;
}

/// Reads a boolean-valued parameter of the global state.
///
/// `data` must point to an array large enough to hold the value(s) of
/// `pname` (one item for single-valued parameters, more for e.g.
/// `GL_COLOR_WRITEMASK`).
pub fn getBoolean(pname: GetPName, data: [*]u8) void {
    loader.context.get_boolean_v(@intFromEnum(pname), data);
}

/// Reads an integer-valued parameter of the global state.
pub fn getInteger(pname: GetPName, data: [*]i32) void {
    loader.context.get_integer_v(@intFromEnum(pname), data);
}

/// Reads a 64-bit integer-valued parameter of the global state.
pub fn getInteger64(pname: GetPName, data: [*]i64) void {
    loader.context.get_integer64_v(@intFromEnum(pname), data);
}

/// Reads an indexed integer-valued parameter of the global state
/// (port of `glGetIntegeri_v`).
///
/// `target` is a binding point such as `GL_TRANSFORM_FEEDBACK_BUFFER_BINDING`
/// or `GL_UNIFORM_BUFFER_BINDING`; see [`buffers.BufferTarget`](buffers.BufferTarget).
/// The native value is written into `data` (first item of the array).
pub fn getIntegerI(target: u32, index: u32, data: [*]i32) void {
    loader.context.get_integer_i_v(target, index, data);
}

/// Reads an indexed 64-bit integer-valued parameter of the global state
/// (port of `glGetInteger64i_v`).
///
/// `target` is a binding point such as `GL_TRANSFORM_FEEDBACK_BUFFER_SIZE`
/// or `GL_UNIFORM_BUFFER_SIZE`; see [`buffers.BufferTarget`](buffers.BufferTarget).
pub fn getInteger64I(target: u32, index: u32, data: [*]i64) void {
    loader.context.get_integer64_i_v(target, index, data);
}

/// Reads a floating-point valued parameter of the global state.
pub fn getFloat(pname: GetPName, data: [*]f32) void {
    loader.context.get_float_v(@intFromEnum(pname), data);
}

/// Retrieves a version, vendor or extension string of the context
/// (port of `glGetString`).
///
/// Returns `null` if the driver does not provide the requested string.
/// The returned slice is a NUL-terminated string valid until the next call
/// to `getString`.
///
/// ```
/// const version = gl.state.getString(.version) orelse "unknown";
/// ```
pub fn getString(name: StringName) ?[:0]const u8 {
    const ptr = loader.context.getString(@intFromEnum(name));
    if (ptr == null) return null;
    return std.mem.sliceTo(ptr.?, 0);
}

/// Retrieves the extension string at the given index (port of `glGetStringi`).
///
/// The index ranges over `[0, GL_NUM_EXTENSIONS)`; the extension names can
/// also be tested directly with [`loader.hasExtension`](loader.hasExtension).
pub fn getStringI(name: StringName, index: u32) ?[:0]const u8 {
    const ptr = loader.context.getStringI(@intFromEnum(name), index);
    if (ptr == null) return null;
    return std.mem.sliceTo(ptr.?, 0);
}

/// Suggests quality-versus-performance preferences for a given hint target.
pub fn hint(target: HintTarget, mode: HintMode) void {
    loader.context.hint(@intFromEnum(target), @intFromEnum(mode));
}

/// Blocks until all previously submitted GL commands have completed.
///
/// Only fails with an error if an error occured during execution of the
/// commands; prefer [`flush`](flush) when synchronization is not required.
pub fn finish() void {
    loader.context.finish();
}

/// Flushes pending GL commands to the underlying command stream.
///
/// The commands are guaranteed to be processed eventually, but not
/// necessarily before the function returns.
pub fn flush() void {
    loader.context.flush();
}

const std = @import("std");