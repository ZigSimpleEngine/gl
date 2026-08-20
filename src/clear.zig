//! Clearing the framebuffer buffers: color, depth and stencil.
//!
//! The clear values are set once ([`clearColor`](clearColor),
//! [`clearDepth`](clearDepth), [`clearStencil`](clearStencil)) and then
//! reused by every subsequent [`clear`](clear) call. The buffers to clear are
//! selected with a [`enums.BufferMask`](enums.BufferMask) bitmask.

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// A buffer of the currently bound framebuffer, addressed by the
/// `glClearBuffer*`, `glDrawBuffers` and `glReadBuffer` commands.
pub const Buffer = enum(u32) {
    /// The color buffer (`GL_COLOR`).
    color = 0x1800,

    /// The depth buffer (`GL_DEPTH`).
    depth = 0x1801,

    /// The stencil buffer (`GL_STENCIL`).
    stencil = 0x1802,
};

/// Clears the selected buffers of the currently bound framebuffer
/// (port of `glClear`).
///
/// Only the buffers whose bit is set in `mask` are cleared, using the values
/// previously set with [`clearColor`](clearColor),
/// [`clearDepth`](clearDepth) and [`clearStencil`](clearStencil).
///
/// ```
/// gl.clear.clear(.{ .color = true, .depth = true });
/// ```
pub fn clear(mask: enums.BufferMask) void {
    loader.context.clear(mask.bits());
}

/// Sets the color used to clear the color buffer (port of `glClearColor`).
///
/// All components are clamped to the [0, 1] range by the driver.
pub fn clearColor(red: f32, green: f32, blue: f32, alpha: f32) void {
    loader.context.clearColor(red, green, blue, alpha);
}

/// Sets the value used to clear the depth buffer (port of `glClearDepthf`).
///
/// The value is clamped to the [0, 1] range by the driver.
pub fn clearDepth(value: f32) void {
    loader.context.clear_depthf(value);
}

/// Sets the value used to clear the stencil buffer (port of `glClearStencil`).
pub fn clearStencil(value: i32) void {
    loader.context.clearStencil(value);
}

/// Clears a single buffer at the given draw buffer index with a
/// floating-point value (port of `glClearBufferfv`).
///
/// `buffer` must be [`Buffer.color`](Buffer.color); `drawbuffer` selects the
/// color output (0 for the first). The value array contains the RGBA
/// components.
pub fn clearBufferFv(buffer: Buffer, drawbuffer: i32, value: [*]const f32) void {
    loader.context.clearBufferFv(@intFromEnum(buffer), drawbuffer, value);
}

/// Clears a single buffer at the given draw buffer index with an
/// integer value (port of `glClearBufferiv`).
///
/// `buffer` must be [`Buffer.color`](Buffer.color); `drawbuffer` selects the
/// color output (0 for the first). The value array contains the RGBA
/// components (signed).
pub fn clearBufferIv(buffer: Buffer, drawbuffer: i32, value: [*]const i32) void {
    loader.context.clearBufferIv(@intFromEnum(buffer), drawbuffer, value);
}

/// Clears a single buffer at the given draw buffer index with an
/// unsigned integer value (port of `glClearBufferuiv`).
///
/// `buffer` must be [`Buffer.color`](Buffer.color); `drawbuffer` selects the
/// color output (0 for the first). The value array contains the RGBA
/// components (unsigned).
pub fn clearBufferUiv(buffer: Buffer, drawbuffer: i32, value: [*]const u32) void {
    loader.context.clearBufferUiv(@intFromEnum(buffer), drawbuffer, value);
}

/// Clears the depth and stencil buffers at once (port of `glClearBufferfi`).
///
/// `buffer` must be [`Buffer.depth`](Buffer.depth) or
/// [`Buffer.stencil`](Buffer.stencil); `stencil` is only used when the depth
/// buffer is cleared.
pub fn clearBufferFi(buffer: Buffer, drawbuffer: i32, depth: f32, stencil: i32) void {
    loader.context.clearBufferFi(@intFromEnum(buffer), drawbuffer, depth, stencil);
}