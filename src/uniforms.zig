//! Uniforms: input values of the shader pipeline.
//!
//! A program's uniforms are located once with [`location`](location) and
//! updated with the `uniform_*` setters. This namespace also covers uniform
//! introspection ([`getActiveUniform`](getActiveUniform)) and uniform
//! blocks ([`blockIndex`](blockIndex),
//! [`blockBinding`](blockBinding)).

const loader = @import("loader.zig");
const enums = @import("enums.zig");
const programs = @import("programs.zig");

/// Re-export of [`programs.ActiveInfo`](programs.ActiveInfo), used by
/// [`getActiveUniform`](getActiveUniform).
pub const ActiveInfo = programs.ActiveInfo;

/// A parameter of an active uniform read via
/// [`getActiveUniforms`](getActiveUniforms).
pub const UniformParameter = enum(u32) {
    /// Size of the uniform in elements (`GL_UNIFORM_SIZE`).
    uniform_size = 0x8A38,

    /// Data type of the uniform ([`enums.DataType`](enums.DataType),
    /// `GL_UNIFORM_TYPE`).
    uniform_type = 0x8A37,

    /// Length of the uniform name including the NUL terminator
    /// (`GL_UNIFORM_NAME_LENGTH`).
    uniform_name_length = 0x8A39,

    /// Index of the uniform block containing the uniform (`GL_UNIFORM_BLOCK_INDEX`).
    uniform_block_index = 0x8A3A,

    /// Byte offset of the uniform inside its block (`GL_UNIFORM_OFFSET`).
    uniform_offset = 0x8A3B,

    /// Byte stride between array elements of the uniform
    /// (`GL_UNIFORM_ARRAY_STRIDE`).
    uniform_array_stride = 0x8A3C,

    /// Byte stride between columns/rows of a matrix uniform
    /// (`GL_UNIFORM_MATRIX_STRIDE`).
    uniform_matrix_stride = 0x8A3D,

    /// Whether the matrix uniform is row-major ([`boolean`],
    /// `GL_UNIFORM_IS_ROW_MAJOR`).
    uniform_is_row_major = 0x8A3E,
};

/// A parameter of a uniform block read via
/// [`getActiveUniformBlock`](getActiveUniformBlock).
pub const UniformBlockParameter = enum(u32) {
    /// Index of the uniform buffer binding point last selected for the
    /// block, or zero if none (`GL_UNIFORM_BLOCK_BINDING`).
    uniform_block_binding = 0x8A3F,

    /// Size of the block data in bytes (`GL_UNIFORM_BLOCK_DATA_SIZE`).
    uniform_block_data_size = 0x8A40,

    /// Number of active uniforms in the block
    /// (`GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS`).
    uniform_block_active_uniforms = 0x8A42,

    /// Indices of the active uniforms in the block
    /// (`GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES`).
    uniform_block_active_uniform_indices = 0x8A43,

    /// Whether the block is referenced by the vertex shader
    /// ([`boolean`], `GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER`).
    uniform_block_referenced_by_vertex_shader = 0x8A44,

    /// Whether the block is referenced by the fragment shader
    /// ([`boolean`], `GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER`).
    uniform_block_referenced_by_fragment_shader = 0x8A45,

    /// Length of the block name including the NUL terminator
    /// (`GL_UNIFORM_BLOCK_NAME_LENGTH`).
    uniform_block_name_length = 0x8A41,
};

/// Returns the location of the uniform `name` in the linked program (port of
/// `glGetUniformLocation`).
///
/// Returns `-1` if the uniform is inactive or optimized away. Use the
/// returned location with the `uniform_*` setters of this namespace.
///
/// ```
/// const u_world = gl.uniforms.location(program, "uWorld");
/// ```
pub fn location(program: u32, name: [:0]const u8) i32 {
    return loader.context.get_uniform_location(program, name);
}

/// Returns the index of the uniform block `name` (port of
/// `glGetUniformBlockIndex`).
///
/// Returns `GL_INVALID_INDEX` (`0xFFFFFFFF`) if the block is not active.
pub fn blockIndex(program: u32, name: [:0]const u8) u32 {
    return loader.context.get_uniform_block_index(program, name);
}

/// Assigns the block to a binding point (port of `glUniformBlockBinding`).
///
/// The data of the block is taken from the buffer bound to the same binding
/// point with [`buffers.bindBase`](buffers.bindBase).
///
/// ```
/// gl.uniforms.blockBinding(program, blockIndex, 0);
/// gl.buffers.bindBase(.uniform_buffer, 0, ubo);
/// ```
pub fn blockBinding(program: u32, index: u32, binding_point: u32) void {
    loader.context.uniform_block_binding(program, index, binding_point);
}

/// Queries the info of the active uniform at `index` (port of
/// `glGetActiveUniform`).
///
/// The uniform name (excluding the NUL terminator) is written into
/// `name_buf`; if the buffer is too small, the name is truncated.
pub fn getActiveUniform(program: u32, index: u32, name_buf: []u8) ActiveInfo {
    var size: i32 = 0;
    var kind: u32 = 0;
    var length: i32 = 0;
    loader.context.getActiveUniform(
        program,
        index,
        @intCast(name_buf.len),
        &length,
        &size,
        &kind,
        name_buf.ptr,
    );
    return .{ .size = size, .kind = kind, .name_length = @intCast(@max(length, 0)) };
}

/// Resolves the indices of the uniforms named in `names` (port of
/// `glGetUniformIndices`).
///
/// The indices are written into `indices` (one per name); inactive uniforms
/// receive `GL_INVALID_INDEX`.
pub fn getIndices(program: u32, names: []const [*:0]const u8, indices: [*]u32) void {
    loader.context.get_uniform_indices(program, @intCast(names.len), names.ptr, indices);
}

/// Reads parameters of multiple uniform indices (port of
/// `glGetActiveUniformsiv`).
///
/// `indices` comes from [`getIndices`](getIndices) or
/// [`getActiveUniform`](getActiveUniform); the value of `pname` for each
/// index is written into `params`.
pub fn getActiveUniforms(program: u32, indices: []const u32, pname: UniformParameter, params: [*]i32) void {
    loader.context.get_active_uniforms_iv(program, @intCast(indices.len), indices.ptr, @intFromEnum(pname), params);
}

/// Returns the name of the uniform block `blockIndex` (port of
/// `glGetActiveUniformBlockName`).
///
/// Returns the number of characters written (excluding the NUL terminator).
pub fn getActiveUniformBlockName(program: u32, index: u32, name_buf: []u8) usize {
    var length: i32 = 0;
    loader.context.getActiveUniformBlockName(
        program,
        index,
        @intCast(name_buf.len),
        &length,
        name_buf.ptr,
    );
    return @intCast(@max(length, 0));
}

/// Reads a parameter of the uniform block `blockIndex` (port of
/// `glGetActiveUniformBlockiv`).
pub fn getActiveUniformBlock(program: u32, index: u32, pname: UniformBlockParameter, params: [*]i32) void {
    loader.context.get_active_uniform_block_iv(program, index, @intFromEnum(pname), params);
}

/// Reads the current values of the uniform at `location` as floats (port of
/// `glGetUniformfv`).
pub fn get(program: u32, loc: i32, params: [*]f32) void {
    loader.context.get_uniform_fv(program, loc, params);
}

/// Reads the current values of the uniform at `location` as integers (port
/// of `glGetUniformiv`).
pub fn getI(program: u32, loc: i32, params: [*]i32) void {
    loader.context.get_uniform_iv(program, loc, params);
}

/// Reads the current values of the uniform at `location` as unsigned
/// integers (port of `glGetUniformuiv`).
pub fn getU(program: u32, loc: i32, params: [*]u32) void {
    loader.context.get_uniform_uiv(program, loc, params);
}

/// Sets a single float uniform (port of `glUniform1f`).
pub fn uniform1f(loc: i32, v0: f32) void {
    loader.context.uniform1f(loc, v0);
}

/// Sets a two-component float uniform (port of `glUniform2f`).
pub fn uniform2f(loc: i32, v0: f32, v1: f32) void {
    loader.context.uniform2f(loc, v0, v1);
}

/// Sets a three-component float uniform (port of `glUniform3f`).
pub fn uniform3f(loc: i32, v0: f32, v1: f32, v2: f32) void {
    loader.context.uniform3f(loc, v0, v1, v2);
}

/// Sets a four-component float uniform (port of `glUniform4f`).
pub fn uniform4f(loc: i32, v0: f32, v1: f32, v2: f32, v3: f32) void {
    loader.context.uniform4f(loc, v0, v1, v2, v3);
}

/// Sets an array of float uniforms (port of `glUniform1fv`).
///
/// `values` holds `count` elements; `count` is inferred from the slice.
pub fn uniform1fv(loc: i32, values: []const f32) void {
    loader.context.uniform1fv(loc, @intCast(values.len), values.ptr);
}

/// Sets an array of two-component float uniforms (port of `glUniform2fv`).
pub fn uniform2fv(loc: i32, values: []const f32) void {
    loader.context.uniform2fv(loc, @intCast(values.len / 2), values.ptr);
}

/// Sets an array of three-component float uniforms (port of `glUniform3fv`).
pub fn uniform3fv(loc: i32, values: []const f32) void {
    loader.context.uniform3fv(loc, @intCast(values.len / 3), values.ptr);
}

/// Sets an array of four-component float uniforms (port of `glUniform4fv`).
pub fn uniform4fv(loc: i32, values: []const f32) void {
    loader.context.uniform4fv(loc, @intCast(values.len / 4), values.ptr);
}

/// Sets a single integer uniform (port of `glUniform1i`).
pub fn uniform1i(loc: i32, v0: i32) void {
    loader.context.uniform1i(loc, v0);
}

/// Sets a two-component integer uniform (port of `glUniform2i`).
pub fn uniform2i(loc: i32, v0: i32, v1: i32) void {
    loader.context.uniform2i(loc, v0, v1);
}

/// Sets a three-component integer uniform (port of `glUniform3i`).
pub fn uniform3i(loc: i32, v0: i32, v1: i32, v2: i32) void {
    loader.context.uniform3i(loc, v0, v1, v2);
}

/// Sets a four-component integer uniform (port of `glUniform4i`).
pub fn uniform4i(loc: i32, v0: i32, v1: i32, v2: i32, v3: i32) void {
    loader.context.uniform4i(loc, v0, v1, v2, v3);
}

/// Sets an array of integer uniforms (port of `glUniform1iv`).
pub fn uniform1iv(loc: i32, values: []const i32) void {
    loader.context.uniform1iv(loc, @intCast(values.len), values.ptr);
}

/// Sets an array of two-component integer uniforms (port of `glUniform2iv`).
pub fn uniform2iv(loc: i32, values: []const i32) void {
    loader.context.uniform2iv(loc, @intCast(values.len / 2), values.ptr);
}

/// Sets an array of three-component integer uniforms (port of `glUniform3iv`).
pub fn uniform3iv(loc: i32, values: []const i32) void {
    loader.context.uniform3iv(loc, @intCast(values.len / 3), values.ptr);
}

/// Sets an array of four-component integer uniforms (port of `glUniform4iv`).
pub fn uniform4iv(loc: i32, values: []const i32) void {
    loader.context.uniform4iv(loc, @intCast(values.len / 4), values.ptr);
}

/// Sets a single unsigned integer uniform (port of `glUniform1ui`).
pub fn uniform1ui(loc: i32, v0: u32) void {
    loader.context.uniform1ui(loc, v0);
}

/// Sets a two-component unsigned integer uniform (port of `glUniform2ui`).
pub fn uniform2ui(loc: i32, v0: u32, v1: u32) void {
    loader.context.uniform2ui(loc, v0, v1);
}

/// Sets a three-component unsigned integer uniform (port of `glUniform3ui`).
pub fn uniform3ui(loc: i32, v0: u32, v1: u32, v2: u32) void {
    loader.context.uniform3ui(loc, v0, v1, v2);
}

/// Sets a four-component unsigned integer uniform (port of `glUniform4ui`).
pub fn uniform4ui(loc: i32, v0: u32, v1: u32, v2: u32, v3: u32) void {
    loader.context.uniform4ui(loc, v0, v1, v2, v3);
}

/// Sets an array of unsigned integer uniforms (port of `glUniform1uiv`).
pub fn uniform1uiv(loc: i32, values: []const u32) void {
    loader.context.uniform1uiv(loc, @intCast(values.len), values.ptr);
}

/// Sets an array of two-component unsigned integer uniforms (port of
/// `glUniform2uiv`).
pub fn uniform2uiv(loc: i32, values: []const u32) void {
    loader.context.uniform2uiv(loc, @intCast(values.len / 2), values.ptr);
}

/// Sets an array of three-component unsigned integer uniforms (port of
/// `glUniform3uiv`).
pub fn uniform3uiv(loc: i32, values: []const u32) void {
    loader.context.uniform3uiv(loc, @intCast(values.len / 3), values.ptr);
}

/// Sets an array of four-component unsigned integer uniforms (port of
/// `glUniform4uiv`).
pub fn uniform4uiv(loc: i32, values: []const u32) void {
    loader.context.uniform4uiv(loc, @intCast(values.len / 4), values.ptr);
}

/// Sets a 2×2 matrix uniform (port of `glUniformMatrix2fv`).
///
/// `transpose` indicates whether `values` is row-major; OpenGL expects
/// column-major matrices, so pass `false` for standard math libraries.
pub fn uniformMatrix2fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix2fv(loc, @intCast(values.len / 4), @intFromBool(transpose), values.ptr);
}

/// Sets a 2×3 matrix uniform (port of `glUniformMatrix2x3fv`).
pub fn uniformMatrix2x3fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix2x3fv(loc, @intCast(values.len / 6), @intFromBool(transpose), values.ptr);
}

/// Sets a 2×4 matrix uniform (port of `glUniformMatrix2x4fv`).
pub fn uniformMatrix2x4fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix2x4fv(loc, @intCast(values.len / 8), @intFromBool(transpose), values.ptr);
}

/// Sets a 3×3 matrix uniform (port of `glUniformMatrix3fv`).
pub fn uniformMatrix3fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix3fv(loc, @intCast(values.len / 9), @intFromBool(transpose), values.ptr);
}

/// Sets a 3×2 matrix uniform (port of `glUniformMatrix3x2fv`).
pub fn uniformMatrix3x2fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix3x2fv(loc, @intCast(values.len / 6), @intFromBool(transpose), values.ptr);
}

/// Sets a 3×4 matrix uniform (port of `glUniformMatrix3x4fv`).
pub fn uniformMatrix3x4fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix3x4fv(loc, @intCast(values.len / 12), @intFromBool(transpose), values.ptr);
}

/// Sets a 4×4 matrix uniform (port of `glUniformMatrix4fv`).
///
/// ```
/// gl.uniforms.uniformMatrix4fv(u_world, false, &world_matrix);
/// ```
pub fn uniformMatrix4fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix4fv(loc, @intCast(values.len / 16), @intFromBool(transpose), values.ptr);
}

/// Sets a 4×2 matrix uniform (port of `glUniformMatrix4x2fv`).
pub fn uniformMatrix4x2fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix4x2fv(loc, @intCast(values.len / 8), @intFromBool(transpose), values.ptr);
}

/// Sets a 4×3 matrix uniform (port of `glUniformMatrix4x3fv`).
pub fn uniformMatrix4x3fv(loc: i32, transpose: bool, values: []const f32) void {
    loader.context.uniformMatrix4x3fv(loc, @intCast(values.len / 12), @intFromBool(transpose), values.ptr);
}