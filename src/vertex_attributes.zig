//! Generic vertex attributes: per-vertex input data feeding the vertex shader.
//!
//! Each generic attribute (index 0..`GL_MAX_VERTEX_ATTRIBS-1`) can pull its
//! values from a bound `GL_ARRAY_BUFFER` through [`pointer`](pointer), or be
//! fed constant values via the `vertex_attrib_*f*` family. Combined with
//! [`vertex_arrays`](vertex_arrays) this state is captured per vertex array
//! object.

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// A parameter of a vertex attribute read via [`get`](get) and friends.
pub const VertexAttribParameter = enum(u32) {
    /// Whether the attribute array is enabled ([`boolean`],
    /// `GL_VERTEX_ATTRIB_ARRAY_ENABLED`).
    vertex_attrib_array_enabled = 0x8622,

    /// Components per vertex (`1..4`, `GL_VERTEX_ATTRIB_ARRAY_SIZE`).
    vertex_attrib_array_size = 0x8623,

    /// Byte stride between consecutive vertices (`GL_VERTEX_ATTRIB_ARRAY_STRIDE`).
    vertex_attrib_array_stride = 0x8624,

    /// Type of each component ([`enums.DataType`](enums.DataType),
    /// `GL_VERTEX_ATTRIB_ARRAY_TYPE`).
    vertex_attrib_array_type = 0x8625,

    /// Whether integer components are normalized to [0, 1]
    /// ([`boolean`], `GL_VERTEX_ATTRIB_ARRAY_NORMALIZED`).
    vertex_attrib_array_normalized = 0x886A,

    /// Name of the buffer providing the attribute data
    /// (`GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING`).
    vertex_attrib_array_buffer_binding = 0x889F,

    /// Whether the attribute is pure integer ([`boolean`],
    /// `GL_VERTEX_ATTRIB_ARRAY_INTEGER`; set implicitly by
    /// [`iPointer`](iPointer)).
    vertex_attrib_array_integer = 0x88FD,

    /// Instance divisor of the attribute (`GL_VERTEX_ATTRIB_ARRAY_DIVISOR`,
    /// see [`divisor`](divisor)).
    vertex_attrib_array_divisor = 0x88FE,

    /// Current constant values of the attribute ([`float`] ×4,
    /// `GL_CURRENT_VERTEX_ATTRIB`).
    current_vertex_attrib = 0x8626,
};

/// Enables the attribute array at `index` (port of
/// `glEnableVertexAttribArray`).
///
/// The attribute consumes data from the buffer configured with
/// [`pointer`](pointer) while enabled; while disabled it uses the constant
/// value set with [`vertexAttrib4f`](vertexAttrib4f) etc.
pub fn enable(index: u32) void {
    loader.context.enable_vertex_attrib_array(index);
}

/// Disables the attribute array at `index` (port of
/// `glDisableVertexAttribArray`).
pub fn disable(index: u32) void {
    loader.context.disable_vertex_attrib_array(index);
}

/// Configures how the attribute at `index` fetches its data from the buffer
/// bound to `GL_ARRAY_BUFFER` (port of `glVertexAttribPointer`).
///
/// - `size` — components per vertex, `1..4`;
/// - `kind` — component type (e.g. [`enums.DataType.unsigned_byte`](enums.DataType.unsigned_byte));
/// - `normalized` — normalize integer components to [0, 1] (for colors);
/// - `stride` — byte offset between consecutive vertices, `0` = tightly packed;
/// - `pointer` — byte offset of the first component in the buffer, or a CPU
///   pointer if no buffer is bound.
///
/// ```
/// gl.vertex_attributes.pointer(0, 3, .float, false, 0, null);
/// ```
pub fn pointer(
    index: u32,
    size: i32,
    kind: enums.DataType,
    normalized: bool,
    stride: i32,
    ptr: ?*const anyopaque,
) void {
    loader.context.vertex_attrib_pointer(index, size, @intFromEnum(kind), @intFromBool(normalized), stride, ptr);
}

/// Configures a pure-integer attribute (port of `glVertexAttribIPointer`).
///
/// Same as [`pointer`](pointer) but without normalization: the values are
/// passed to the shader as integers.
pub fn iPointer(index: u32, size: i32, kind: enums.DataType, stride: i32, ptr: ?*const anyopaque) void {
    loader.context.vertex_attrib_i_pointer(index, size, @intFromEnum(kind), stride, ptr);
}

/// Sets the instance divisor of the attribute (port of
/// `glVertexAttribDivisor`).
///
/// With `divisor > 0` the attribute advances once per `divisor`
/// instances; with `0` it advances per vertex. Required for instanced
/// drawing ([`drawing.drawArraysInstanced`](drawing.drawArraysInstanced)).
pub fn divisor(index: u32, value: u32) void {
    loader.context.vertex_attrib_divisor(index, value);
}

/// Sets the constant one-component float value of the attribute
/// (port of `glVertexAttrib1f`).
///
/// Used while the attribute array is disabled. Components not specified are
/// filled with `0.0` (or `1.0` for the fourth component).
pub fn vertexAttrib1f(index: u32, x: f32) void {
    loader.context.vertexAttrib1f(index, x);
}

/// Sets the constant two-component float value of the attribute
/// (port of `glVertexAttrib2f`).
pub fn vertexAttrib2f(index: u32, x: f32, y: f32) void {
    loader.context.vertexAttrib2f(index, x, y);
}

/// Sets the constant three-component float value of the attribute
/// (port of `glVertexAttrib3f`).
pub fn vertexAttrib3f(index: u32, x: f32, y: f32, z: f32) void {
    loader.context.vertexAttrib3f(index, x, y, z);
}

/// Sets the constant four-component float value of the attribute
/// (port of `glVertexAttrib4f`).
pub fn vertexAttrib4f(index: u32, x: f32, y: f32, z: f32, w: f32) void {
    loader.context.vertexAttrib4f(index, x, y, z, w);
}

/// Sets the constant float value of the attribute from an array
/// (port of `glVertexAttrib1fv`).
pub fn vertexAttrib1fv(index: u32, v: [*]const f32) void {
    loader.context.vertexAttrib1fv(index, v);
}

/// Sets the constant float value of the attribute from an array of two
/// components (port of `glVertexAttrib2fv`).
pub fn vertexAttrib2fv(index: u32, v: [*]const f32) void {
    loader.context.vertexAttrib2fv(index, v);
}

/// Sets the constant float value of the attribute from an array of three
/// components (port of `glVertexAttrib3fv`).
pub fn vertexAttrib3fv(index: u32, v: [*]const f32) void {
    loader.context.vertexAttrib3fv(index, v);
}

/// Sets the constant float value of the attribute from an array of four
/// components (port of `glVertexAttrib4fv`).
pub fn vertexAttrib4fv(index: u32, v: [*]const f32) void {
    loader.context.vertexAttrib4fv(index, v);
}

/// Sets the constant signed integer value of the attribute
/// (port of `glVertexAttribI4i`).
pub fn vertexAttribI4i(index: u32, x: i32, y: i32, z: i32, w: i32) void {
    loader.context.vertexAttribI4i(index, x, y, z, w);
}

/// Sets the constant unsigned integer value of the attribute
/// (port of `glVertexAttribI4ui`).
pub fn vertexAttribI4ui(index: u32, x: u32, y: u32, z: u32, w: u32) void {
    loader.context.vertexAttribI4ui(index, x, y, z, w);
}

/// Sets the constant signed integer value of the attribute from an array
/// (port of `glVertexAttribI4iv`).
pub fn vertexAttribI4iv(index: u32, v: [*]const i32) void {
    loader.context.vertexAttribI4iv(index, v);
}

/// Sets the constant unsigned integer value of the attribute from an array
/// (port of `glVertexAttribI4uiv`).
pub fn vertexAttribI4uiv(index: u32, v: [*]const u32) void {
    loader.context.vertexAttribI4uiv(index, v);
}

/// Reads a floating-point-valued parameter of the attribute (port of
/// `glGetVertexAttribfv`).
pub fn get(index: u32, pname: VertexAttribParameter, params: [*]f32) void {
    loader.context.get_vertex_attrib_fv(index, @intFromEnum(pname), params);
}

/// Reads an integer-valued parameter of the attribute (port of
/// `glGetVertexAttribiv`).
pub fn getI(index: u32, pname: VertexAttribParameter, params: [*]i32) void {
    loader.context.get_vertex_attrib_iv(index, @intFromEnum(pname), params);
}

/// Reads an unsigned integer-valued parameter of the attribute
/// (port of `glGetVertexAttribIuiv`).
pub fn getIU(index: u32, pname: VertexAttribParameter, params: [*]u32) void {
    loader.context.get_vertex_attrib_i_uiv(index, @intFromEnum(pname), params);
}

/// Reads a signed integer-valued parameter of a pure-integer attribute
/// (port of `glGetVertexAttribIiv`).
pub fn getIS(index: u32, pname: VertexAttribParameter, params: [*]i32) void {
    loader.context.get_vertex_attrib_i_iv(index, @intFromEnum(pname), params);
}

/// Reads the data pointer configured by [`pointer`](pointer) (port of
/// `glGetVertexAttribPointerv`).
pub fn getPointer(index: u32, pname: VertexAttribParameter, ptr: ?*?*anyopaque) void {
    loader.context.get_vertex_attrib_pointer_v(index, @intFromEnum(pname), ptr);
}