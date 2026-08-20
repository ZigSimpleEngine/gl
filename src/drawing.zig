//! Drawing primitives: issuing draw calls from bound vertex attribute data
//! and index buffers.
//!
//! Before drawing, set up the vertex data with the
//! [`vertex_attributes`](vertex_attributes) namespace, bind the element
//! buffer with [`buffers.bind`](buffers.bind) and select the active program
//! with [`programs.use`](programs.use).

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// The primitive type assembled from the vertex stream
/// (`GL_TRIANGLES`, `GL_LINES`, ...).
pub const PrimitiveType = enum(u32) {
    /// Individual points (`GL_POINTS`).
    points = 0x0000,

    /// Individual line segments (`GL_LINES`).
    lines = 0x0001,

    /// A closed chain of line segments (`GL_LINE_LOOP`).
    line_loop = 0x0002,

    /// A connected chain of line segments (`GL_LINE_STRIP`).
    line_strip = 0x0003,

    /// Individual triangles (`GL_TRIANGLES`).
    triangles = 0x0004,

    /// A connected strip of triangles (`GL_TRIANGLE_STRIP`).
    triangle_strip = 0x0005,

    /// A fan of triangles sharing the first vertex (`GL_TRIANGLE_FAN`).
    triangle_fan = 0x0006,
};

/// Draws `count` primitives of the given type, reading vertices sequentially
/// from the bound attribute arrays (port of `glDrawArrays`).
pub fn drawArrays(mode: PrimitiveType, first: i32, count: i32) void {
    loader.context.drawArrays(@intFromEnum(mode), first, count);
}

/// Draws `count` primitives, repeated `instance_count` times (port of
/// `glDrawArraysInstanced`).
///
/// The per-instance attributes must be set up with
/// [`vertex_attributes.divisor`](vertex_attributes.divisor).
pub fn drawArraysInstanced(mode: PrimitiveType, first: i32, count: i32, instance_count: i32) void {
    loader.context.drawArraysInstanced(@intFromEnum(mode), first, count, instance_count);
}

/// Draws indexed primitives (port of `glDrawElements`).
///
/// `count` is the number of indices; `kind` is the type of each index
/// (typically [`enums.DataType.unsigned_short`](enums.DataType.unsigned_short)
/// or [`enums.DataType.unsigned_int`](enums.DataType.unsigned_int)).
/// `indices` is either a CPU pointer to the index array or a byte offset into
/// the bound `GL_ELEMENT_ARRAY_BUFFER`; pass `null` with a zero offset.
///
/// ```
/// gl.drawing.drawElements(.triangles, 6, .unsigned_short, null);
/// ```
pub fn drawElements(mode: PrimitiveType, count: i32, kind: enums.DataType, indices: ?*const anyopaque) void {
    loader.context.drawElements(@intFromEnum(mode), count, @intFromEnum(kind), indices);
}

/// Draws indexed primitives, repeated `instance_count` times (port of
/// `glDrawElementsInstanced`).
pub fn drawElementsInstanced(
    mode: PrimitiveType,
    count: i32,
    kind: enums.DataType,
    indices: ?*const anyopaque,
    instance_count: i32,
) void {
    loader.context.drawElementsInstanced(@intFromEnum(mode), count, @intFromEnum(kind), indices, instance_count);
}

/// Draws indexed primitives restricted to the index range `[start, end]`
/// (port of `glDrawRangeElements`).
///
/// The driver may use the hint to skip unneeded vertices; if the actual
/// indices fall outside the range, the behavior is undefined.
pub fn drawRangeElements(
    mode: PrimitiveType,
    start: u32,
    end: u32,
    count: i32,
    kind: enums.DataType,
    indices: ?*const anyopaque,
) void {
    loader.context.drawRangeElements(@intFromEnum(mode), start, end, count, @intFromEnum(kind), indices);
}