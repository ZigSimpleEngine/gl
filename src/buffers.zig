//! Buffer objects: GPU-stored vertex data, indices and generic data.
//!
//! Buffers are untyped byte arrays on the GPU. This namespace covers their
//! creation, deletion, binding, data upload and direct (mapped) access.

const loader = @import("loader.zig");
const types = @import("types.zig");

/// A binding point (target) that a buffer can be bound to
/// (`GL_ARRAY_BUFFER`, `GL_ELEMENT_ARRAY_BUFFER`, ...).
pub const BufferTarget = enum(u32) {
    /// Vertex attribute data (`GL_ARRAY_BUFFER`).
    array_buffer = 0x8892,

    /// Vertex indices for indexed drawing (`GL_ELEMENT_ARRAY_BUFFER`).
    element_array_buffer = 0x8893,

    /// Source of [`copySubData`](copySubData) (`GL_COPY_READ_BUFFER`).
    copy_read_buffer = 0x8F36,

    /// Destination of [`copySubData`](copySubData)
    /// (`GL_COPY_WRITE_BUFFER`).
    copy_write_buffer = 0x8F37,

    /// Destination of pixel readback (`GL_PIXEL_PACK_BUFFER`).
    pixel_pack_buffer = 0x88EB,

    /// Source of pixel uploads (`GL_PIXEL_UNPACK_BUFFER`).
    pixel_unpack_buffer = 0x88EC,

    /// Captures transform feedback output (`GL_TRANSFORM_FEEDBACK_BUFFER`).
    transform_feedback_buffer = 0x8C8E,

    /// Backing store of uniform blocks (`GL_UNIFORM_BUFFER`).
    uniform_buffer = 0x8A11,
};

/// Expected usage pattern of a buffer, used by the driver to optimize
/// storage (`GL_STATIC_DRAW`, `GL_DYNAMIC_DRAW`, ...).
pub const BufferUsage = enum(u32) {
    /// Data is written once per frame and used for drawing
    /// (`GL_STREAM_DRAW`).
    stream_draw = 0x88E0,

    /// Data is written once per frame and read back by the application
    /// (`GL_STREAM_READ`).
    stream_read = 0x88E1,

    /// Data is written once per frame and copied within GL (`GL_STREAM_COPY`).
    stream_copy = 0x88E2,

    /// Data is written once and used many times (`GL_STATIC_DRAW`).
    static_draw = 0x88E4,

    /// Data is written once and read back by the application
    /// (`GL_STATIC_READ`).
    static_read = 0x88E5,

    /// Data is written once and copied within GL (`GL_STATIC_COPY`).
    static_copy = 0x88E6,

    /// Data is modified frequently and used many times (`GL_DYNAMIC_DRAW`).
    dynamic_draw = 0x88E8,

    /// Data is modified frequently and read back by the application
    /// (`GL_DYNAMIC_READ`).
    dynamic_read = 0x88E9,

    /// Data is modified frequently and copied within GL (`GL_DYNAMIC_COPY`).
    dynamic_copy = 0x88EA,
};

/// A buffer parameter read via [`getParameter`](getParameter) and
/// [`getParameter64`](getParameter64).
pub const BufferParameter = enum(u32) {
    /// Size of the buffer in bytes (`GL_BUFFER_SIZE`).
    buffer_size = 0x8764,

    /// Usage pattern of the buffer ([`BufferUsage`](BufferUsage),
    /// `GL_BUFFER_USAGE`).
    buffer_usage = 0x8765,

    /// Whether the buffer is currently mapped ([`boolean`],
    /// `GL_BUFFER_MAPPED`).
    buffer_mapped = 0x88BC,

    /// Length of the mapped range in bytes (`GL_BUFFER_MAP_LENGTH`).
    buffer_map_length = 0x9120,

    /// Offset of the mapped range in bytes (`GL_BUFFER_MAP_OFFSET`).
    buffer_map_offset = 0x9121,

    /// Access flags of the current mapping ([`MapAccess`](MapAccess),
    /// `GL_BUFFER_ACCESS_FLAGS`).
    buffer_access_flags = 0x911F,
};

/// Access flags for [`map`](map): how the mapped region may be used
/// (`GL_MAP_READ_BIT`, `GL_MAP_WRITE_BIT`, ...).
///
/// Use [`bits`](MapAccess.bits) to obtain the native `GLbitfield` value.
pub const MapAccess = packed struct {
    /// The mapped region may be read by the application (`GL_MAP_READ_BIT`).
    read: bool = false,

    /// The mapped region may be written by the application (`GL_MAP_WRITE_BIT`).
    write: bool = false,

    /// Discard the previous contents of the whole buffer before mapping
    /// (`GL_MAP_INVALIDATE_BUFFER_BIT`).
    invalidate_buffer: bool = false,

    /// Discard the previous contents of the mapped range before mapping
    /// (`GL_MAP_INVALIDATE_RANGE_BIT`).
    invalidate_range: bool = false,

    /// Write only the flushed subrange back to the buffer
    /// (`GL_MAP_FLUSH_EXPLICIT_BIT`).
    flush_explicit: bool = false,

    /// Skip synchronization with pending GL commands (`GL_MAP_UNSYNCHRONIZED_BIT`).
    unsynchronized: bool = false,

    /// Reserved bits; always zero.
    _reserved: u26 = 0,

    /// Returns the native 32-bit value of the flag bitmask.
    pub fn bits(access: MapAccess) u32 {
        return @as(u32, @bitCast(access));
    }
};

/// Generates `n` new buffer names (port of `glGenBuffers`).
///
/// The names are written into `buffers` (an array of at least `n` elements)
/// and do not become buffers until first bound.
///
/// ```
/// var vbo: u32 = 0;
/// gl.buffers.gen(1, &vbo);
/// ```
pub fn gen(n: i32, buffers: [*]u32) void {
    loader.context.gen_buffers(n, buffers);
}

/// Deletes the given buffers (port of `glDeleteBuffers`).
///
/// The names become available for reuse. Passing `null` as `buffers` is
/// allowed when `n` is zero.
pub fn delete(n: i32, buffers: [*]const u32) void {
    loader.context.delete_buffers(n, buffers);
}

/// Returns whether `buffer` is the name of an existing buffer
/// (port of `glIsBuffer`).
pub fn isBuffer(buffer: u32) bool {
    return loader.context.isBuffer(buffer) != 0;
}

/// Binds the buffer to the given target (port of `glBindBuffer`).
///
/// Binding a buffer to `GL_ARRAY_BUFFER` or `GL_ELEMENT_ARRAY_BUFFER`
/// associates its data with the current vertex array.
pub fn bind(target: BufferTarget, buffer: u32) void {
    loader.context.bind_buffer(@intFromEnum(target), buffer);
}

/// Binds the buffer to the given indexed binding point of the target
/// (port of `glBindBufferBase`).
///
/// Used for `GL_UNIFORM_BUFFER` and `GL_TRANSFORM_FEEDBACK_BUFFER` binding
/// points.
pub fn bindBase(target: BufferTarget, index: u32, buffer: u32) void {
    loader.context.bind_buffer_base(@intFromEnum(target), index, buffer);
}

/// Binds a subrange of the buffer to the given indexed binding point
/// (port of `glBindBufferRange`).
///
/// `offset` and `size` are in bytes; `offset` must be aligned according to
/// `GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT` for uniform buffers.
pub fn bindRange(target: BufferTarget, index: u32, buffer: u32, offset: types.Intptr, size: types.Sizeiptr) void {
    loader.context.bind_buffer_range(@intFromEnum(target), index, buffer, offset, size);
}

/// Uploads raw data into the buffer (port of `glBufferData`).
///
/// Reallocates the buffer storage; the previous contents are lost. Pass
/// `null` with `size` to reserve storage without uploading data.
pub fn bufferData(target: BufferTarget, size: usize, ptr: ?*const anyopaque, usage: BufferUsage) void {
    loader.context.bufferData(@intFromEnum(target), @intCast(size), ptr, @intFromEnum(usage));
}

/// Uploads a byte slice into the buffer (convenience wrapper over
/// [`bufferData`](bufferData)).
///
/// ```
/// gl.buffers.bufferDataSlice(.array_buffer, vertices[0..], .static_draw);
/// ```
pub fn bufferDataSlice(target: BufferTarget, bytes: []const u8, usage: BufferUsage) void {
    loader.context.bufferData(@intFromEnum(target), @intCast(bytes.len), bytes.ptr, @intFromEnum(usage));
}

/// Uploads raw data into a subrange of the buffer (port of `glBufferSubData`).
pub fn bufferSubData(target: BufferTarget, offset: usize, size: usize, ptr: ?*const anyopaque) void {
    loader.context.bufferSubData(@intFromEnum(target), @intCast(offset), @intCast(size), ptr);
}

/// Uploads a byte slice into a subrange of the buffer (convenience wrapper
/// over [`bufferSubData`](bufferSubData)).
pub fn bufferSubDataSlice(target: BufferTarget, offset: usize, bytes: []const u8) void {
    loader.context.bufferSubData(@intFromEnum(target), @intCast(offset), @intCast(bytes.len), bytes.ptr);
}

/// Copies `size` bytes between two buffers (port of `glCopyBufferSubData`).
pub fn copySubData(
    read_target: BufferTarget,
    write_target: BufferTarget,
    read_offset: usize,
    write_offset: usize,
    size: usize,
) void {
    loader.context.copy_buffer_sub_data(
        @intFromEnum(read_target),
        @intFromEnum(write_target),
        @intCast(read_offset),
        @intCast(write_offset),
        @intCast(size),
    );
}

/// Reads a parameter of the currently bound buffer (port of
/// `glGetBufferParameteriv`).
pub fn getParameter(target: BufferTarget, pname: BufferParameter, params: [*]i32) void {
    loader.context.get_buffer_parameter_iv(@intFromEnum(target), @intFromEnum(pname), params);
}

/// Reads a 64-bit parameter of the currently bound buffer (port of
/// `glGetBufferParameteri64v`).
pub fn getParameter64(target: BufferTarget, pname: BufferParameter, params: [*]i64) void {
    loader.context.get_buffer_parameter_i64_v(@intFromEnum(target), @intFromEnum(pname), params);
}

/// Maps the given range of the buffer for direct access (port of
/// `glMapBufferRange`).
///
/// Returns `null` if the mapping failed. The mapped pointer must be released
/// with [`unmap`](unmap) before drawing from the buffer.
///
/// ```
/// const ptr: ?[*]u8 = @ptrCast(gl.buffers.map(.array_buffer, 0, size, .{ .write = true }));
/// ```
pub fn map(target: BufferTarget, offset: usize, length: usize, access: MapAccess) ?*anyopaque {
    return loader.context.map_buffer_range(@intFromEnum(target), @intCast(offset), @intCast(length), access.bits());
}

/// Releases the mapping created by [`map`](map) (port of `glUnmapBuffer`).
///
/// Returns `true` if the data was successfully written to the buffer.
pub fn unmap(target: BufferTarget) bool {
    return loader.context.unmap_buffer(@intFromEnum(target)) != 0;
}

/// Flushes the modified subrange of a mapped range created with the
/// `GL_MAP_FLUSH_EXPLICIT_BIT` flag (port of `glFlushMappedBufferRange`).
pub fn flushMappedRange(target: BufferTarget, offset: usize, length: usize) void {
    loader.context.flush_mapped_buffer_range(@intFromEnum(target), @intCast(offset), @intCast(length));
}