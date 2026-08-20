//! Viewport state: mapping of normalized device coordinates to framebuffer
//! pixels.
//!
//! The viewport defines the rectangular region of the framebuffer into which
//! the rendering output is written. The depth range is configured in the
//! [`depth`](depth) namespace.

const loader = @import("loader.zig");

/// Sets the viewport rectangle in framebuffer pixel coordinates
/// (port of `glViewport`).
///
/// `x` and `y` are the lower-left corner, `width` and `height` — the size of
/// the rectangle in pixels. Negative or zero sizes are treated as an error by
/// the driver.
///
/// A typical setup for a window-sized canvas:
///
/// ```
/// gl.viewport.viewport(0, 0, window_width, window_height);
/// ```
pub fn viewport(x: i32, y: i32, width: i32, height: i32) void {
    loader.context.viewport(x, y, width, height);
}