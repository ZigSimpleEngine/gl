//! State parameters: typed Zig helpers over the global OpenGL ES 3.0 state.
//!
//! This namespace is a WebGL-friendly view over [`state`](state): where
//! WebGL exposes a single dynamically typed `getParameter(pname)`, here every
//! parameter has its own function with a precise return type, so no
//! caller-provided `out` pointer (`[*]i32`, `[*]f32`, ...) is needed.
//!
//! Naming follows Zig conventions: value getters are `get*` in camelCase,
//! boolean getters are `is*` in camelCase. No abbreviated variable names are
//! used: the allocator parameter is always named `allocator`, indices are
//! named `index`, and so on.
//!
//! Official sources used for every mapping below (query function, component
//! count and value domain — nothing is invented):
//!
//! - Khronos `glGet` reference (`glGetBooleanv`, `glGetIntegerv`,
//!   `glGetInteger64v`, `glGetFloatv`, `glGetIntegeri_v`,
//!   `glGetInteger64i_v`, `glGetString`, `glGetStringi`):
//!   <https://registry.khronos.org/OpenGL-Refpages/es3/html/glGet.xhtml>
//! - OpenGL ES 3.0 specification, state tables 6.28–6.36 (which `pname`
//!   returns how many components of which type):
//!   <https://registry.khronos.org/OpenGL/specs/es/3.0/es_spec_3.0.pdf>
//! - WebGL2 `getParameter` mapping (naming cross-check only):
//!   <https://registry.khronos.org/WebGL/specs/latest/2.0/>
//!
//! Multi-component values are returned as documented structs with meaningful
//! field names. Variable-length lists (compressed texture formats, program
//! binary formats, shader binary formats, extension list) allocate with the
//! provided `allocator` and return an owned slice that the caller must free
//! with `allocator.free`.
//!
//! All functions require a loaded context (`gl.loader.load`) first.
//!
//! ```
//! const maximum = gl.state_parameters.getMaxTextureSize();
//! const viewport = gl.state_parameters.getViewport();
//! const blending = gl.state_parameters.isBlend();
//! ```

const std = @import("std");
const state = @import("state.zig");
const enums = @import("enums.zig");
const blending = @import("blending.zig");
const stencil = @import("stencil.zig");
const rasterization = @import("rasterization.zig");
const textures = @import("textures.zig");
const framebuffers = @import("framebuffers.zig");
const buffers = @import("buffers.zig");

// ---------------------------------------------------------------------------
// Local type aliases (no inline `std.mem.Allocator` or long paths in
// signatures below).
// ---------------------------------------------------------------------------

/// Allocator used by variable-length helpers.
const Allocator = std.mem.Allocator;
/// Depth / stencil comparison function.
const Comparison = enums.Comparison;
/// Polygon face selector.
const Face = enums.Face;
/// Front-face winding direction.
const FrontFaceDirection = rasterization.FrontFaceDirection;
/// Blend scaling factor.
const BlendFactor = blending.BlendFactor;
/// Blend arithmetic equation.
const BlendEquation = blending.BlendEquation;
/// Stencil buffer action.
const StencilOperation = stencil.StencilOp;
/// Texture image unit.
const TextureUnit = textures.TextureUnit;
/// Pixel data format.
const PixelFormat = textures.PixelFormat;
/// Pixel data type.
const DataType = enums.DataType;
/// Draw destination buffer.
const DrawBuffer = framebuffers.DrawBuffer;
/// Quality-versus-performance hint mode.
const HintMode = state.HintMode;
/// Buffer binding target for indexed queries.
const BufferTarget = buffers.BufferTarget;

// ---------------------------------------------------------------------------
// Multi-component result structs.
// ---------------------------------------------------------------------------

/// Blend constant color: red, green, blue and alpha components of
/// `GL_BLEND_COLOR` (`glGetFloatv`, 4 × float).
pub const BlendColor = struct {
    /// Red component of the blend color.
    red: f32,
    /// Green component of the blend color.
    green: f32,
    /// Blue component of the blend color.
    blue: f32,
    /// Alpha component of the blend color.
    alpha: f32,
};

/// Clear color used for the color buffer: `GL_COLOR_CLEAR_VALUE`
/// (`glGetFloatv`, 4 × float).
pub const ColorClearValue = struct {
    /// Red component of the clear color.
    red: f32,
    /// Green component of the clear color.
    green: f32,
    /// Blue component of the clear color.
    blue: f32,
    /// Alpha component of the clear color.
    alpha: f32,
};

/// Per-channel color write mask: `GL_COLOR_WRITEMASK`
/// (`glGetBooleanv`, 4 × boolean).
pub const ColorWritemask = struct {
    /// Whether the red channel is writable.
    red: bool,
    /// Whether the green channel is writable.
    green: bool,
    /// Whether the blue channel is writable.
    blue: bool,
    /// Whether the alpha channel is writable.
    alpha: bool,
};

/// Current generic vertex attribute values: `GL_CURRENT_VERTEX_ATTRIB`
/// (4 × float).
pub const CurrentVertexAttribute = struct {
    /// First component of the current vertex attribute.
    x: f32,
    /// Second component of the current vertex attribute.
    y: f32,
    /// Third component of the current vertex attribute.
    z: f32,
    /// Fourth component of the current vertex attribute.
    w: f32,
};

/// Depth range mapping limits: `GL_DEPTH_RANGE` (`glGetFloatv`, 2 × float).
pub const DepthRange = struct {
    /// Near mapping limit of the depth buffer.
    near: f32,
    /// Far mapping limit of the depth buffer.
    far: f32,
};

/// Minimum/maximum range pair: `GL_ALIASED_LINE_WIDTH_RANGE` and
/// `GL_ALIASED_POINT_SIZE_RANGE` (`glGetFloatv`, 2 × float).
pub const FloatRange = struct {
    /// Minimum supported value.
    minimum: f32,
    /// Maximum supported value.
    maximum: f32,
};

/// Maximum viewport dimensions: `GL_MAX_VIEWPORT_DIMS`
/// (`glGetIntegerv`, 2 × integer).
pub const MaximumViewportDimensions = struct {
    /// Maximum viewport width in pixels.
    width: i32,
    /// Maximum viewport height in pixels.
    height: i32,
};

/// Scissor rectangle: `GL_SCISSOR_BOX` (`glGetIntegerv`, 4 × integer).
pub const ScissorBox = struct {
    /// Lower-left horizontal coordinate in pixels.
    x: i32,
    /// Lower-left vertical coordinate in pixels.
    y: i32,
    /// Width of the scissor rectangle in pixels.
    width: i32,
    /// Height of the scissor rectangle in pixels.
    height: i32,
};

/// Viewport rectangle: `GL_VIEWPORT` (`glGetIntegerv`, 4 × integer).
pub const Viewport = struct {
    /// Lower-left horizontal coordinate in pixels.
    x: i32,
    /// Lower-left vertical coordinate in pixels.
    y: i32,
    /// Width of the viewport rectangle in pixels.
    width: i32,
    /// Height of the viewport rectangle in pixels.
    height: i32,
};

// ---------------------------------------------------------------------------
// Internal helpers (not part of the public parameter surface).
// ---------------------------------------------------------------------------

fn readBooleanValue(parameter: state.GetPName) bool {
    var storage: [4]u8 = .{ 0, 0, 0, 0 };
    state.getBoolean(parameter, &storage);
    return storage[0] != 0;
}

fn readIntegerValue(parameter: state.GetPName) i32 {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(parameter, &storage);
    return storage[0];
}

fn readUnsignedValue(parameter: state.GetPName) u32 {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(parameter, &storage);
    return @bitCast(storage[0]);
}

fn readFloatValue(parameter: state.GetPName) f32 {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(parameter, &storage);
    return storage[0];
}

fn readInteger64Value(parameter: state.GetPName) i64 {
    var storage: [4]i64 = .{ 0, 0, 0, 0 };
    state.getInteger64(parameter, &storage);
    return storage[0];
}

fn readEnumValue(comptime Result: type, parameter: state.GetPName) Result {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(parameter, &storage);
    return @fromBackingInt(@intCast(@as(u32, @bitCast(storage[0]))));
}

// ---------------------------------------------------------------------------
// Active texture unit and ranges.
// ---------------------------------------------------------------------------

/// Active multitexture unit: `GL_ACTIVE_TEXTURE` (`glGetIntegerv`, 1 × enum,
/// initial `GL_TEXTURE0`).
///
/// WebGL equivalent: `gl.getParameter(gl.ACTIVE_TEXTURE)`.
pub fn getActiveTexture() TextureUnit {
    return readEnumValue(TextureUnit, .activeTexture);
}

/// Range of supported aliased line widths: `GL_ALIASED_LINE_WIDTH_RANGE`
/// (`glGetFloatv`, 2 × float).
pub fn getAliasedLineWidthRange() FloatRange {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.aliased_line_width_range, &storage);
    return .{ .minimum = storage[0], .maximum = storage[1] };
}

/// Smallest and largest supported point sizes:
/// `GL_ALIASED_POINT_SIZE_RANGE` (`glGetFloatv`, 2 × float).
pub fn getAliasedPointSizeRange() FloatRange {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.aliased_point_size_range, &storage);
    return .{ .minimum = storage[0], .maximum = storage[1] };
}

// ---------------------------------------------------------------------------
// Framebuffer bit depths.
// ---------------------------------------------------------------------------

/// Number of alpha bitplanes in the color buffer: `GL_ALPHA_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getAlphaBits() i32 {
    return readIntegerValue(.alpha_bits);
}

/// Number of blue bitplanes in the color buffer: `GL_BLUE_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getBlueBits() i32 {
    return readIntegerValue(.blue_bits);
}

/// Number of green bitplanes in the color buffer: `GL_GREEN_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getGreenBits() i32 {
    return readIntegerValue(.green_bits);
}

/// Number of red bitplanes in the color buffer: `GL_RED_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getRedBits() i32 {
    return readIntegerValue(.red_bits);
}

/// Number of bitplanes in the depth buffer: `GL_DEPTH_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getDepthBits() i32 {
    return readIntegerValue(.depth_bits);
}

/// Number of bitplanes in the stencil buffer: `GL_STENCIL_BITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getStencilBits() i32 {
    return readIntegerValue(.stencil_bits);
}

// ---------------------------------------------------------------------------
// Buffer and object bindings (object names).
// ---------------------------------------------------------------------------

/// Name of the buffer bound to `GL_ARRAY_BUFFER`:
/// `GL_ARRAY_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name, 0 if none).
pub fn getArrayBufferBinding() u32 {
    return readUnsignedValue(.array_buffer_binding);
}

/// Name of the buffer bound to `GL_ELEMENT_ARRAY_BUFFER`:
/// `GL_ELEMENT_ARRAY_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getElementArrayBufferBinding() u32 {
    return readUnsignedValue(.element_array_buffer_binding);
}

/// Name of the buffer bound to `GL_PIXEL_PACK_BUFFER`:
/// `GL_PIXEL_PACK_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getPixelPackBufferBinding() u32 {
    return readUnsignedValue(.pixel_pack_buffer_binding);
}

/// Name of the buffer bound to `GL_PIXEL_UNPACK_BUFFER`:
/// `GL_PIXEL_UNPACK_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getPixelUnpackBufferBinding() u32 {
    return readUnsignedValue(.pixel_unpack_buffer_binding);
}

/// Name of the framebuffer bound to `GL_FRAMEBUFFER`:
/// `GL_FRAMEBUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getFramebufferBinding() u32 {
    return readUnsignedValue(.framebuffer_binding);
}

/// Name of the renderbuffer bound to `GL_RENDERBUFFER`:
/// `GL_RENDERBUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getRenderbufferBinding() u32 {
    return readUnsignedValue(.renderbuffer_binding);
}

/// Name of the sampler bound to the active texture unit:
/// `GL_SAMPLER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getSamplerBinding() u32 {
    return readUnsignedValue(.sampler_binding);
}

/// Name of the program currently in use: `GL_CURRENT_PROGRAM`
/// (`glGetIntegerv`, 1 × object name, 0 if none).
pub fn getCurrentProgram() u32 {
    return readUnsignedValue(.current_program);
}

/// Name of the active query of the current target: `GL_CURRENT_QUERY`
/// (1 × object name, queried via `glGetQueryiv` semantics).
pub fn getCurrentQuery() u32 {
    return readUnsignedValue(.current_query);
}

/// Name of the transform feedback object bound to `GL_TRANSFORM_FEEDBACK`:
/// `GL_TRANSFORM_FEEDBACK_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getTransformFeedbackBinding() u32 {
    return readUnsignedValue(.transform_feedback_binding);
}

/// Name of the buffer bound to `GL_TRANSFORM_FEEDBACK_BUFFER`:
/// `GL_TRANSFORM_FEEDBACK_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getTransformFeedbackBufferBinding() u32 {
    return readUnsignedValue(.transform_feedback_buffer_binding);
}

/// Name of the buffer bound to `GL_UNIFORM_BUFFER`:
/// `GL_UNIFORM_BUFFER_BINDING` (`glGetIntegerv`, 1 × object name).
pub fn getUniformBufferBinding() u32 {
    return readUnsignedValue(.uniform_buffer_binding);
}

/// Name of the 2D texture bound to the active unit:
/// `GL_TEXTURE_BINDING_2D` (`glGetIntegerv`, 1 × object name).
pub fn getTextureBinding2D() u32 {
    return readUnsignedValue(.texture_binding_2d);
}

/// Name of the 2D array texture bound to the active unit:
/// `GL_TEXTURE_BINDING_2D_ARRAY` (`glGetIntegerv`, 1 × object name).
pub fn getTextureBinding2DArray() u32 {
    return readUnsignedValue(.texture_binding_2d_array);
}

/// Name of the 3D texture bound to the active unit:
/// `GL_TEXTURE_BINDING_3D` (`glGetIntegerv`, 1 × object name).
pub fn getTextureBinding3D() u32 {
    return readUnsignedValue(.texture_binding_3d);
}

/// Name of the cube map texture bound to the active unit:
/// `GL_TEXTURE_BINDING_CUBE_MAP` (`glGetIntegerv`, 1 × object name).
pub fn getTextureBindingCubeMap() u32 {
    return readUnsignedValue(.texture_binding_cube_map);
}

// ---------------------------------------------------------------------------
// Blending state.
// ---------------------------------------------------------------------------

/// Whether blending is enabled: `GL_BLEND` (`glGetBooleanv`, 1 × boolean).
///
/// WebGL equivalent: `gl.getParameter(gl.BLEND)`.
pub fn isBlend() bool {
    return state.isEnabled(.blend);
}

/// Constant blend color: `GL_BLEND_COLOR` (`glGetFloatv`, 4 × float).
pub fn getBlendColor() BlendColor {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.blendColor, &storage);
    return .{
        .red = storage[0],
        .green = storage[1],
        .blue = storage[2],
        .alpha = storage[3],
    };
}

/// Alpha destination blend function: `GL_BLEND_DST_ALPHA`
/// (`glGetIntegerv`, 1 × enum).
pub fn getBlendDestinationAlpha() BlendFactor {
    return readEnumValue(BlendFactor, .blend_dst_alpha);
}

/// Red-green-blue destination blend function: `GL_BLEND_DST_RGB`
/// (`glGetIntegerv`, 1 × enum).
pub fn getBlendDestinationRgb() BlendFactor {
    return readEnumValue(BlendFactor, .blend_dst_rgb);
}

/// Alpha blend equation: `GL_BLEND_EQUATION_ALPHA`
/// (`glGetIntegerv`, 1 × enum).
pub fn getBlendEquationAlpha() BlendEquation {
    return readEnumValue(BlendEquation, .blend_equation_alpha);
}

/// Red-green-blue blend equation: `GL_BLEND_EQUATION_RGB`
/// (`glGetIntegerv`, 1 × enum).
pub fn getBlendEquationRgb() BlendEquation {
    return readEnumValue(BlendEquation, .blend_equation_rgb);
}

/// Alpha source blend function: `GL_BLEND_SRC_ALPHA`
/// (`glGetIntegerv`, 1 × enum, initial `GL_ONE`).
pub fn getBlendSourceAlpha() BlendFactor {
    return readEnumValue(BlendFactor, .blend_src_alpha);
}

/// Red-green-blue source blend function: `GL_BLEND_SRC_RGB`
/// (`glGetIntegerv`, 1 × enum, initial `GL_ONE`).
pub fn getBlendSourceRgb() BlendFactor {
    return readEnumValue(BlendFactor, .blend_src_rgb);
}

// ---------------------------------------------------------------------------
// Clear values and write masks.
// ---------------------------------------------------------------------------

/// Color buffer clear values: `GL_COLOR_CLEAR_VALUE`
/// (`glGetFloatv`, 4 × float, initial `(0, 0, 0, 0)`).
pub fn getColorClearValue() ColorClearValue {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.color_clear_value, &storage);
    return .{
        .red = storage[0],
        .green = storage[1],
        .blue = storage[2],
        .alpha = storage[3],
    };
}

/// Per-channel color write mask: `GL_COLOR_WRITEMASK`
/// (`glGetBooleanv`, 4 × boolean).
pub fn getColorWritemask() ColorWritemask {
    var storage: [4]u8 = .{ 0, 0, 0, 0 };
    state.getBoolean(.color_writemask, &storage);
    return .{
        .red = storage[0] != 0,
        .green = storage[1] != 0,
        .blue = storage[2] != 0,
        .alpha = storage[3] != 0,
    };
}

/// Depth buffer clear value: `GL_DEPTH_CLEAR_VALUE`
/// (`glGetFloatv`, 1 × float, initial `1`).
pub fn getDepthClearValue() f32 {
    return readFloatValue(.depth_clear_value);
}

/// Stencil buffer clear value: `GL_STENCIL_CLEAR_VALUE`
/// (`glGetIntegerv`, 1 × integer).
pub fn getStencilClearValue() i32 {
    return readIntegerValue(.stencil_clear_value);
}

// ---------------------------------------------------------------------------
// Variable-length format lists (allocator-based).
// ---------------------------------------------------------------------------

/// Number of supported compressed texture formats:
/// `GL_NUM_COMPRESSED_TEXTURE_FORMATS` (`glGetIntegerv`, 1 × integer).
pub fn getNumberOfCompressedTextureFormats() i32 {
    return readIntegerValue(.num_compressed_texture_formats);
}

/// Supported compressed texture formats: `GL_COMPRESSED_TEXTURE_FORMATS`
/// (list of length `GL_NUM_COMPRESSED_TEXTURE_FORMATS`).
///
/// The returned slice is owned by the caller and must be freed with
/// `allocator.free`.
pub fn getCompressedTextureFormats(allocator: Allocator) ![]u32 {
    const number = getNumberOfCompressedTextureFormats();
    if (number <= 0) return try allocator.alloc(u32, 0);
    const count: usize = @intCast(number);
    const integerStorage = try allocator.alloc(i32, count);
    defer allocator.free(integerStorage);
    state.getInteger(.compressed_texture_formats, integerStorage.ptr);
    const result = try allocator.alloc(u32, count);
    for (integerStorage, 0..) |value, position| {
        result[position] = @bitCast(value);
    }
    return result;
}

/// Number of supported program binary formats:
/// `GL_NUM_PROGRAM_BINARY_FORMATS` (`glGetIntegerv`, 1 × integer).
pub fn getNumberOfProgramBinaryFormats() i32 {
    return readIntegerValue(.num_program_binary_formats);
}

/// Supported program binary formats: `GL_PROGRAM_BINARY_FORMATS`
/// (list of length `GL_NUM_PROGRAM_BINARY_FORMATS`).
///
/// The returned slice is owned by the caller and must be freed with
/// `allocator.free`.
pub fn getProgramBinaryFormats(allocator: Allocator) ![]u32 {
    const number = getNumberOfProgramBinaryFormats();
    if (number <= 0) return try allocator.alloc(u32, 0);
    const count: usize = @intCast(number);
    const integerStorage = try allocator.alloc(i32, count);
    defer allocator.free(integerStorage);
    state.getInteger(.program_binary_formats, integerStorage.ptr);
    const result = try allocator.alloc(u32, count);
    for (integerStorage, 0..) |value, position| {
        result[position] = @bitCast(value);
    }
    return result;
}

/// Number of supported shader binary formats:
/// `GL_NUM_SHADER_BINARY_FORMATS` (`glGetIntegerv`, 1 × integer).
pub fn getNumberOfShaderBinaryFormats() i32 {
    return readIntegerValue(.num_shader_binary_formats);
}

/// Supported shader binary formats: `GL_SHADER_BINARY_FORMATS`
/// (list of length `GL_NUM_SHADER_BINARY_FORMATS`).
///
/// The returned slice is owned by the caller and must be freed with
/// `allocator.free`.
pub fn getShaderBinaryFormats(allocator: Allocator) ![]u32 {
    const number = getNumberOfShaderBinaryFormats();
    if (number <= 0) return try allocator.alloc(u32, 0);
    const count: usize = @intCast(number);
    const integerStorage = try allocator.alloc(i32, count);
    defer allocator.free(integerStorage);
    state.getInteger(.shader_binary_formats, integerStorage.ptr);
    const result = try allocator.alloc(u32, count);
    for (integerStorage, 0..) |value, position| {
        result[position] = @bitCast(value);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Culling, depth, dither and polygon offset.
// ---------------------------------------------------------------------------

/// Whether polygon culling is enabled: `GL_CULL_FACE`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isCullFace() bool {
    return state.isEnabled(.cullFace);
}

/// Polygon culling mode: `GL_CULL_FACE_MODE` (`glGetIntegerv`, 1 × enum,
/// initial `GL_BACK`).
pub fn getCullFaceMode() Face {
    return readEnumValue(Face, .cull_face_mode);
}

/// Current generic vertex attribute values: `GL_CURRENT_VERTEX_ATTRIB`
/// (4 × float).
pub fn getCurrentVertexAttribute() CurrentVertexAttribute {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.current_vertex_attrib, &storage);
    return .{
        .x = storage[0],
        .y = storage[1],
        .z = storage[2],
        .w = storage[3],
    };
}

/// Depth comparison function: `GL_DEPTH_FUNC` (`glGetIntegerv`, 1 × enum,
/// initial `GL_LESS`).
pub fn getDepthFunction() Comparison {
    return readEnumValue(Comparison, .depthFunc);
}

/// Near and far depth mapping limits: `GL_DEPTH_RANGE`
/// (`glGetFloatv`, 2 × float, initial `(0, 1)`).
pub fn getDepthRange() DepthRange {
    var storage: [4]f32 = .{ 0, 0, 0, 0 };
    state.getFloat(.depthRange, &storage);
    return .{ .near = storage[0], .far = storage[1] };
}

/// Whether depth testing is enabled: `GL_DEPTH_TEST`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isDepthTest() bool {
    return state.isEnabled(.depth_test);
}

/// Whether the depth buffer is writable: `GL_DEPTH_WRITEMASK`
/// (`glGetBooleanv`, 1 × boolean, initial `GL_TRUE`).
pub fn isDepthWritemask() bool {
    return readBooleanValue(.depth_writemask);
}

/// Whether dithering is enabled: `GL_DITHER` (`glGetBooleanv`, 1 × boolean,
/// initial `GL_TRUE`).
pub fn isDither() bool {
    return state.isEnabled(.dither);
}

/// Depth offset factor: `GL_POLYGON_OFFSET_FACTOR`
/// (`glGetFloatv`, 1 × float).
pub fn getPolygonOffsetFactor() f32 {
    return readFloatValue(.polygon_offset_factor);
}

/// Whether polygon offset for filled polygons is enabled:
/// `GL_POLYGON_OFFSET_FILL` (`glGetBooleanv`, 1 × boolean).
pub fn isPolygonOffsetFill() bool {
    return state.isEnabled(.polygon_offset_fill);
}

/// Depth offset units: `GL_POLYGON_OFFSET_UNITS`
/// (`glGetFloatv`, 1 × float).
pub fn getPolygonOffsetUnits() f32 {
    return readFloatValue(.polygon_offset_units);
}

// ---------------------------------------------------------------------------
// Draw buffers (indexed `GL_DRAW_BUFFER0` … `GL_DRAW_BUFFER15`).
// ---------------------------------------------------------------------------

/// Destination buffer of the given fragment output:
/// `GL_DRAW_BUFFER0` … `GL_DRAW_BUFFER15` (`glGetIntegerv`, 1 × enum each).
///
/// `index` selects the output color number (0–15). The initial value of index
/// 0 is `GL_BACK`; all other outputs start as `GL_NONE`.
pub fn getDrawBuffer(index: u32) DrawBuffer {
    const base: u32 = @backingInt(state.GetPName.draw_buffer0);
    const parameter: state.GetPName = @fromBackingInt(@intCast(base + index));
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(parameter, &storage);
    return @fromBackingInt(@intCast(@as(u32, @bitCast(storage[0]))));
}

// ---------------------------------------------------------------------------
// Front face, hints, implementation limits.
// ---------------------------------------------------------------------------

/// Front-face winding order: `GL_FRONT_FACE` (`glGetIntegerv`, 1 × enum,
/// initial `GL_CCW`).
pub fn getFrontFace() FrontFaceDirection {
    return readEnumValue(FrontFaceDirection, .frontFace);
}

/// Mipmap generation quality hint: `GL_GENERATE_MIPMAP_HINT`
/// (`glGetIntegerv`, 1 × enum, initial `GL_DONT_CARE`).
pub fn getGenerateMipmapHint() HintMode {
    return readEnumValue(HintMode, .generate_mipmap_hint);
}

/// Preferred pixel format for framebuffer reads:
/// `GL_IMPLEMENTATION_COLOR_READ_FORMAT` (`glGetIntegerv`, 1 × enum).
pub fn getImplementationColorReadFormat() PixelFormat {
    return readEnumValue(PixelFormat, .implementation_color_read_format);
}

/// Preferred pixel type for framebuffer reads:
/// `GL_IMPLEMENTATION_COLOR_READ_TYPE` (`glGetIntegerv`, 1 × enum).
pub fn getImplementationColorReadType() DataType {
    return readEnumValue(DataType, .implementation_color_read_type);
}

/// Current line width: `GL_LINE_WIDTH` (`glGetFloatv`, 1 × float,
/// initial `1`).
pub fn getLineWidth() f32 {
    return readFloatValue(.lineWidth);
}

/// Major version of the context: `GL_MAJOR_VERSION`
/// (`glGetIntegerv`, 1 × integer, always `3` on ES 3.0).
pub fn getMajorVersion() i32 {
    return readIntegerValue(.major_version);
}

/// Minor version of the context: `GL_MINOR_VERSION`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMinorVersion() i32 {
    return readIntegerValue(.minor_version);
}

// ---------------------------------------------------------------------------
// Implementation-dependent maximums.
// ---------------------------------------------------------------------------

/// Largest supported 3D texture dimension: `GL_MAX_3D_TEXTURE_SIZE`
/// (`glGetIntegerv`, 1 × integer, at least `256`).
pub fn getMax3DTextureSize() i32 {
    return readIntegerValue(.max_3d_texture_size);
}

/// Maximum number of array texture layers: `GL_MAX_ARRAY_TEXTURE_LAYERS`
/// (`glGetIntegerv`, 1 × integer, at least `256`).
pub fn getMaxArrayTextureLayers() i32 {
    return readIntegerValue(.max_array_texture_layers);
}

/// Maximum number of framebuffer color attachments:
/// `GL_MAX_COLOR_ATTACHMENTS` (`glGetIntegerv`, 1 × integer, at least `4`).
pub fn getMaxColorAttachments() i32 {
    return readIntegerValue(.max_color_attachments);
}

/// Maximum fragment-shader uniform components across all blocks:
/// `GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxCombinedFragmentUniformComponents() i32 {
    return readIntegerValue(.max_combined_fragment_uniform_components);
}

/// Maximum texture units available to all shaders:
/// `GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxCombinedTextureImageUnits() i32 {
    return readIntegerValue(.max_combined_texture_image_units);
}

/// Maximum uniform blocks available to all shaders:
/// `GL_MAX_COMBINED_UNIFORM_BLOCKS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxCombinedUniformBlocks() i32 {
    return readIntegerValue(.max_combined_uniform_blocks);
}

/// Maximum vertex-shader uniform components across all blocks:
/// `GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxCombinedVertexUniformComponents() i32 {
    return readIntegerValue(.max_combined_vertex_uniform_components);
}

/// Largest supported cube map face dimension:
/// `GL_MAX_CUBE_MAP_TEXTURE_SIZE` (`glGetIntegerv`, 1 × integer).
pub fn getMaxCubeMapTextureSize() i32 {
    return readIntegerValue(.max_cube_map_texture_size);
}

/// Maximum number of draw buffers: `GL_MAX_DRAW_BUFFERS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxDrawBuffers() i32 {
    return readIntegerValue(.max_draw_buffers);
}

/// Maximum index value used in indexed drawing: `GL_MAX_ELEMENT_INDEX`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxElementIndex() i32 {
    return readIntegerValue(.max_element_index);
}

/// Maximum number of indices in a single draw call:
/// `GL_MAX_ELEMENTS_INDICES` (`glGetIntegerv`, 1 × integer).
pub fn getMaxElementsIndices() i32 {
    return readIntegerValue(.max_elements_indices);
}

/// Maximum number of vertices in a single draw call:
/// `GL_MAX_ELEMENTS_VERTICES` (`glGetIntegerv`, 1 × integer).
pub fn getMaxElementsVertices() i32 {
    return readIntegerValue(.max_elements_vertices);
}

/// Maximum fragment-shader inputs: `GL_MAX_FRAGMENT_INPUT_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxFragmentInputComponents() i32 {
    return readIntegerValue(.max_fragment_input_components);
}

/// Maximum fragment-shader uniform blocks:
/// `GL_MAX_FRAGMENT_UNIFORM_BLOCKS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxFragmentUniformBlocks() i32 {
    return readIntegerValue(.max_fragment_uniform_blocks);
}

/// Maximum fragment-shader uniform components:
/// `GL_MAX_FRAGMENT_UNIFORM_COMPONENTS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxFragmentUniformComponents() i32 {
    return readIntegerValue(.max_fragment_uniform_components);
}

/// Maximum fragment-shader uniform vectors:
/// `GL_MAX_FRAGMENT_UNIFORM_VECTORS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxFragmentUniformVectors() i32 {
    return readIntegerValue(.max_fragment_uniform_vectors);
}

/// Maximum texture sampling offset: `GL_MAX_PROGRAM_TEXEL_OFFSET`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxProgramTexelOffset() i32 {
    return readIntegerValue(.max_program_texel_offset);
}

/// Largest supported renderbuffer dimension: `GL_MAX_RENDERBUFFER_SIZE`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxRenderbufferSize() i32 {
    return readIntegerValue(.max_renderbuffer_size);
}

/// Maximum samples per pixel: `GL_MAX_SAMPLES`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxSamples() i32 {
    return readIntegerValue(.max_samples);
}

/// Maximum server wait timeout: `GL_MAX_SERVER_WAIT_TIMEOUT`
/// (`glGetInteger64v`, 1 × 64-bit integer).
pub fn getMaxServerWaitTimeout() i64 {
    return readInteger64Value(.max_server_wait_timeout);
}

/// Maximum fragment-shader texture units: `GL_MAX_TEXTURE_IMAGE_UNITS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxTextureImageUnits() i32 {
    return readIntegerValue(.max_texture_image_units);
}

/// Maximum texture level-of-detail bias: `GL_MAX_TEXTURE_LOD_BIAS`
/// (`glGetFloatv`, 1 × float).
pub fn getMaxTextureLevelOfDetailBias() f32 {
    return readFloatValue(.max_texture_lod_bias);
}

/// Largest supported 2D texture dimension: `GL_MAX_TEXTURE_SIZE`
/// (`glGetIntegerv`, 1 × integer).
///
/// WebGL equivalent: `gl.getParameter(gl.MAX_TEXTURE_SIZE)`.
pub fn getMaxTextureSize() i32 {
    return readIntegerValue(.max_texture_size);
}

/// Maximum interleaved transform feedback components:
/// `GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxTransformFeedbackInterleavedComponents() i32 {
    return readIntegerValue(.max_transform_feedback_interleaved_components);
}

/// Maximum transform feedback attributes:
/// `GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxTransformFeedbackSeparateAttributes() i32 {
    return readIntegerValue(.max_transform_feedback_separate_attribs);
}

/// Maximum separate transform feedback components:
/// `GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxTransformFeedbackSeparateComponents() i32 {
    return readIntegerValue(.max_transform_feedback_separate_components);
}

/// Maximum uniform block size in bytes: `GL_MAX_UNIFORM_BLOCK_SIZE`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxUniformBlockSize() i32 {
    return readIntegerValue(.max_uniform_block_size);
}

/// Maximum uniform buffer bindings: `GL_MAX_UNIFORM_BUFFER_BINDINGS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxUniformBufferBindings() i32 {
    return readIntegerValue(.max_uniform_buffer_bindings);
}

/// Maximum varying components: `GL_MAX_VARYING_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVaryingComponents() i32 {
    return readIntegerValue(.max_varying_components);
}

/// Maximum varying vectors: `GL_MAX_VARYING_VECTORS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVaryingVectors() i32 {
    return readIntegerValue(.max_varying_vectors);
}

/// Maximum generic vertex attributes: `GL_MAX_VERTEX_ATTRIBS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexAttributes() i32 {
    return readIntegerValue(.max_vertex_attribs);
}

/// Maximum vertex-shader outputs: `GL_MAX_VERTEX_OUTPUT_COMPONENTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexOutputComponents() i32 {
    return readIntegerValue(.max_vertex_output_components);
}

/// Maximum vertex-shader texture units:
/// `GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexTextureImageUnits() i32 {
    return readIntegerValue(.max_vertex_texture_image_units);
}

/// Maximum vertex-shader uniform blocks: `GL_MAX_VERTEX_UNIFORM_BLOCKS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexUniformBlocks() i32 {
    return readIntegerValue(.max_vertex_uniform_blocks);
}

/// Maximum vertex-shader uniform components:
/// `GL_MAX_VERTEX_UNIFORM_COMPONENTS` (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexUniformComponents() i32 {
    return readIntegerValue(.max_vertex_uniform_components);
}

/// Maximum vertex-shader uniform vectors: `GL_MAX_VERTEX_UNIFORM_VECTORS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMaxVertexUniformVectors() i32 {
    return readIntegerValue(.max_vertex_uniform_vectors);
}

/// Maximum viewport dimensions: `GL_MAX_VIEWPORT_DIMS`
/// (`glGetIntegerv`, 2 × integer).
pub fn getMaxViewportDimensions() MaximumViewportDimensions {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(.max_viewport_dims, &storage);
    return .{ .width = storage[0], .height = storage[1] };
}

/// Minimum texture sampling offset: `GL_MIN_PROGRAM_TEXEL_OFFSET`
/// (`glGetIntegerv`, 1 × integer).
pub fn getMinProgramTexelOffset() i32 {
    return readIntegerValue(.min_program_texel_offset);
}

// ---------------------------------------------------------------------------
// Counters.
// ---------------------------------------------------------------------------

/// Number of extensions: `GL_NUM_EXTENSIONS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getNumberOfExtensions() i32 {
    return readIntegerValue(.num_extensions);
}

/// Number of usable sample counts: `GL_NUM_SAMPLE_COUNTS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getNumberOfSampleCounts() i32 {
    return readIntegerValue(.num_sample_counts);
}

// ---------------------------------------------------------------------------
// Pixel store state.
// ---------------------------------------------------------------------------

/// Pack alignment: `GL_PACK_ALIGNMENT` (`glGetIntegerv`, 1 × integer).
pub fn getPackAlignment() i32 {
    return readIntegerValue(.pack_alignment);
}

/// Pack row length: `GL_PACK_ROW_LENGTH` (`glGetIntegerv`, 1 × integer).
pub fn getPackRowLength() i32 {
    return readIntegerValue(.pack_row_length);
}

/// Pack skip pixels: `GL_PACK_SKIP_PIXELS` (`glGetIntegerv`, 1 × integer).
pub fn getPackSkipPixels() i32 {
    return readIntegerValue(.pack_skip_pixels);
}

/// Pack skip rows: `GL_PACK_SKIP_ROWS` (`glGetIntegerv`, 1 × integer).
pub fn getPackSkipRows() i32 {
    return readIntegerValue(.pack_skip_rows);
}

/// Unpack alignment: `GL_UNPACK_ALIGNMENT` (`glGetIntegerv`, 1 × integer).
pub fn getUnpackAlignment() i32 {
    return readIntegerValue(.unpack_alignment);
}

/// Unpack row length: `GL_UNPACK_ROW_LENGTH`
/// (`glGetIntegerv`, 1 × integer).
pub fn getUnpackRowLength() i32 {
    return readIntegerValue(.unpack_row_length);
}

/// Unpack skip pixels: `GL_UNPACK_SKIP_PIXELS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getUnpackSkipPixels() i32 {
    return readIntegerValue(.unpack_skip_pixels);
}

/// Unpack skip rows: `GL_UNPACK_SKIP_ROWS` (`glGetIntegerv`, 1 × integer).
pub fn getUnpackSkipRows() i32 {
    return readIntegerValue(.unpack_skip_rows);
}

// ---------------------------------------------------------------------------
// Multisampling state.
// ---------------------------------------------------------------------------

/// Whether alpha-to-coverage multisampling is enabled:
/// `GL_SAMPLE_ALPHA_TO_COVERAGE` (`glGetBooleanv`, 1 × boolean).
pub fn isSampleAlphaToCoverage() bool {
    return state.isEnabled(.sample_alpha_to_coverage);
}

/// Number of multisample buffers: `GL_SAMPLE_BUFFERS`
/// (`glGetIntegerv`, 1 × integer).
pub fn getSampleBuffers() i32 {
    return readIntegerValue(.sample_buffers);
}

/// Whether per-sample coverage is enabled: `GL_SAMPLE_COVERAGE`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isSampleCoverage() bool {
    return state.isEnabled(.sampleCoverage);
}

/// Whether sample coverage is inverted: `GL_SAMPLE_COVERAGE_INVERT`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isSampleCoverageInverted() bool {
    return readBooleanValue(.sample_coverage_invert);
}

/// Sample coverage value: `GL_SAMPLE_COVERAGE_VALUE`
/// (`glGetFloatv`, 1 × float).
pub fn getSampleCoverageValue() f32 {
    return readFloatValue(.sample_coverage_value);
}

/// Number of samples in the default framebuffer: `GL_SAMPLES`
/// (`glGetIntegerv`, 1 × integer).
pub fn getSamples() i32 {
    return readIntegerValue(.samples);
}

// ---------------------------------------------------------------------------
// Scissor and shader compiler.
// ---------------------------------------------------------------------------

/// Scissor rectangle: `GL_SCISSOR_BOX` (`glGetIntegerv`, 4 × integer).
pub fn getScissorBox() ScissorBox {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(.scissor_box, &storage);
    return .{
        .x = storage[0],
        .y = storage[1],
        .width = storage[2],
        .height = storage[3],
    };
}

/// Whether the scissor test is enabled: `GL_SCISSOR_TEST`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isScissorTest() bool {
    return state.isEnabled(.scissor_test);
}

/// Whether a shader compiler is available: `GL_SHADER_COMPILER`
/// (`glGetBooleanv`, 1 × boolean, always true on ES 3.0).
pub fn isShaderCompiler() bool {
    return readBooleanValue(.shader_compiler);
}

// ---------------------------------------------------------------------------
// Stencil state.
// ---------------------------------------------------------------------------

/// Back-face stencil fail operation: `GL_STENCIL_BACK_FAIL`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilBackFailOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_back_fail);
}

/// Back-face stencil function: `GL_STENCIL_BACK_FUNC`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilBackFunction() Comparison {
    return readEnumValue(Comparison, .stencil_back_func);
}

/// Back-face depth-fail stencil operation:
/// `GL_STENCIL_BACK_PASS_DEPTH_FAIL` (`glGetIntegerv`, 1 × enum).
pub fn getStencilBackPassDepthFailOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_back_pass_depth_fail);
}

/// Back-face depth-pass stencil operation:
/// `GL_STENCIL_BACK_PASS_DEPTH_PASS` (`glGetIntegerv`, 1 × enum).
pub fn getStencilBackPassDepthPassOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_back_pass_depth_pass);
}

/// Back-face stencil reference value: `GL_STENCIL_BACK_REF`
/// (`glGetIntegerv`, 1 × integer).
pub fn getStencilBackReference() i32 {
    return readIntegerValue(.stencil_back_ref);
}

/// Back-face stencil value mask: `GL_STENCIL_BACK_VALUE_MASK`
/// (`glGetIntegerv`, 1 × integer mask).
pub fn getStencilBackValueMask() u32 {
    return readUnsignedValue(.stencil_back_value_mask);
}

/// Back-face stencil write mask: `GL_STENCIL_BACK_WRITEMASK`
/// (`glGetIntegerv`, 1 × integer mask).
pub fn getStencilBackWritemask() u32 {
    return readUnsignedValue(.stencil_back_writemask);
}

/// Front-face stencil fail operation: `GL_STENCIL_FAIL`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilFailOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_fail);
}

/// Front-face stencil function: `GL_STENCIL_FUNC`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilFunction() Comparison {
    return readEnumValue(Comparison, .stencilFunc);
}

/// Front-face depth-fail stencil operation: `GL_STENCIL_PASS_DEPTH_FAIL`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilPassDepthFailOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_pass_depth_fail);
}

/// Front-face depth-pass stencil operation: `GL_STENCIL_PASS_DEPTH_PASS`
/// (`glGetIntegerv`, 1 × enum).
pub fn getStencilPassDepthPassOperation() StencilOperation {
    return readEnumValue(StencilOperation, .stencil_pass_depth_pass);
}

/// Front-face stencil reference value: `GL_STENCIL_REF`
/// (`glGetIntegerv`, 1 × integer).
pub fn getStencilReference() i32 {
    return readIntegerValue(.stencil_ref);
}

/// Whether the stencil test is enabled: `GL_STENCIL_TEST`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isStencilTest() bool {
    return state.isEnabled(.stencil_test);
}

/// Front-face stencil value mask: `GL_STENCIL_VALUE_MASK`
/// (`glGetIntegerv`, 1 × integer mask).
pub fn getStencilValueMask() u32 {
    return readUnsignedValue(.stencil_value_mask);
}

/// Front-face stencil write mask: `GL_STENCIL_WRITEMASK`
/// (`glGetIntegerv`, 1 × integer mask).
pub fn getStencilWritemask() u32 {
    return readUnsignedValue(.stencil_writemask);
}

// ---------------------------------------------------------------------------
// Transform feedback and uniform buffer state.
// ---------------------------------------------------------------------------

/// Whether transform feedback is active: `GL_TRANSFORM_FEEDBACK_ACTIVE`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isTransformFeedbackActive() bool {
    return readBooleanValue(.transform_feedback_active);
}

/// Whether transform feedback is paused: `GL_TRANSFORM_FEEDBACK_PAUSED`
/// (`glGetBooleanv`, 1 × boolean).
pub fn isTransformFeedbackPaused() bool {
    return readBooleanValue(.transform_feedback_paused);
}

/// Uniform buffer offset alignment:
/// `GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT` (`glGetIntegerv`, 1 × integer).
pub fn getUniformBufferOffsetAlignment() i32 {
    return readIntegerValue(.uniform_buffer_offset_alignment);
}

// ---------------------------------------------------------------------------
// Viewport.
// ---------------------------------------------------------------------------

/// Viewport rectangle: `GL_VIEWPORT` (`glGetIntegerv`, 4 × integer).
///
/// WebGL equivalent: `gl.getParameter(gl.VIEWPORT)`.
pub fn getViewport() Viewport {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getInteger(.viewport, &storage);
    return .{
        .x = storage[0],
        .y = storage[1],
        .width = storage[2],
        .height = storage[3],
    };
}

// ---------------------------------------------------------------------------
// Capability switches not otherwise covered above.
// ---------------------------------------------------------------------------

/// Whether rasterizer discard is enabled: `GL_RASTERIZER_DISCARD`
/// (queried via `glIsEnabled`, 1 × boolean).
pub fn isRasterizerDiscard() bool {
    return state.isEnabled(.rasterizer_discard);
}

/// Whether primitive restart with fixed index is enabled:
/// `GL_PRIMITIVE_RESTART_FIXED_INDEX` (queried via `glIsEnabled`,
/// 1 × boolean).
pub fn isPrimitiveRestartFixedIndex() bool {
    return state.isEnabled(.primitive_restart_fixed_index);
}

// ---------------------------------------------------------------------------
// Version and vendor strings.
// ---------------------------------------------------------------------------

/// Vendor of the implementation: `GL_VENDOR` (`glGetString`).
pub fn getVendor() ?[:0]const u8 {
    return state.getString(.vendor);
}

/// Name of the renderer: `GL_RENDERER` (`glGetString`).
pub fn getRenderer() ?[:0]const u8 {
    return state.getString(.renderer);
}

/// Version string of the context: `GL_VERSION` (`glGetString`).
pub fn getVersion() ?[:0]const u8 {
    return state.getString(.version);
}

/// Shading language version: `GL_SHADING_LANGUAGE_VERSION`
/// (`glGetString`).
pub fn getShadingLanguageVersion() ?[:0]const u8 {
    return state.getString(.shading_language_version);
}

/// Extension string at the given index: `GL_EXTENSIONS` via `glGetStringi`.
///
/// `index` ranges over `0 .. getNumberOfExtensions()`.
pub fn getExtensionAtIndex(index: u32) ?[:0]const u8 {
    return state.getStringI(.extensions, index);
}

/// Full extension list via `glGetStringi`.
///
/// The returned slice is owned by the caller and must be freed with
/// `allocator.free`. The pointed-to strings themselves remain owned by the
/// driver and must not be freed.
pub fn getExtensionList(allocator: Allocator) ![]?[:0]const u8 {
    const number = getNumberOfExtensions();
    if (number <= 0) return try allocator.alloc(?[:0]const u8, 0);
    const count: usize = @intCast(number);
    const result = try allocator.alloc(?[:0]const u8, count);
    var position: usize = 0;
    while (position < count) : (position += 1) {
        result[position] = state.getStringI(.extensions, @intCast(position));
    }
    return result;
}

// ---------------------------------------------------------------------------
// Indexed queries (`glGetIntegeri_v`, `glGetInteger64i_v`).
// ---------------------------------------------------------------------------

/// Indexed integer query: port of `glGetIntegeri_v`.
///
/// `target` is a binding point such as `GL_TRANSFORM_FEEDBACK_BUFFER_BINDING`
/// or `GL_UNIFORM_BUFFER_BINDING`; `index` selects the indexed binding point.
pub fn getIndexedInteger(target: BufferTarget, index: u32) i32 {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getIntegerI(@backingInt(target), index, &storage);
    return storage[0];
}

/// Indexed 64-bit integer query: port of `glGetInteger64i_v`.
pub fn getIndexedInteger64(target: BufferTarget, index: u32) i64 {
    var storage: [4]i64 = .{ 0, 0, 0, 0 };
    state.getInteger64I(@backingInt(target), index, &storage);
    return storage[0];
}

/// Indexed uniform buffer binding at the given binding point.
pub fn getIndexedUniformBufferBinding(index: u32) u32 {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getIntegerI(@backingInt(BufferTarget.uniform_buffer), index, &storage);
    return @bitCast(storage[0]);
}

/// Indexed transform feedback buffer binding at the given binding point.
pub fn getIndexedTransformFeedbackBufferBinding(index: u32) u32 {
    var storage: [4]i32 = .{ 0, 0, 0, 0 };
    state.getIntegerI(@backingInt(BufferTarget.transform_feedback_buffer), index, &storage);
    return @bitCast(storage[0]);
}
