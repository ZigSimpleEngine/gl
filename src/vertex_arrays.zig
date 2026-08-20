//! Vertex array objects: capturing the vertex attribute configuration.
//!
//! A vertex array object bundles the state of all vertex attributes
//! ([`vertex_attributes`](vertex_attributes)) together with the binding of
//! `GL_ELEMENT_ARRAY_BUFFER`. Binding a vertex array restores this state in
//! one call.

const loader = @import("loader.zig");

/// Generates `n` new vertex array names (port of `glGenVertexArrays`).
///
/// Vertex array names do not become objects until first bound.
///
/// ```
/// var vao: u32 = 0;
/// gl.vertex_arrays.gen(1, &vao);
/// ```
pub fn gen(n: i32, arrays: [*]u32) void {
    loader.context.gen_vertex_arrays(n, arrays);
}

/// Deletes the given vertex arrays (port of `glDeleteVertexArrays`).
pub fn delete(n: i32, arrays: [*]const u32) void {
    loader.context.delete_vertex_arrays(n, arrays);
}

/// Returns whether `array` is the name of an existing vertex array
/// (port of `glIsVertexArray`).
pub fn isVertexArray(array: u32) bool {
    return loader.context.isVertexArray(array) != 0;
}

/// Binds the vertex array object (port of `glBindVertexArray`).
///
/// Afterwards, all [`vertex_attributes`](vertex_attributes) commands and the
/// `GL_ELEMENT_ARRAY_BUFFER` binding are recorded into this object. Binding
/// name `0` restores the default vertex array.
///
/// ```
/// gl.vertex_arrays.bind(vao);
/// gl.vertex_attributes.pointer(0, 3, .float, false, 12, null);
/// ```
pub fn bind(array: u32) void {
    loader.context.bind_vertex_array(array);
}