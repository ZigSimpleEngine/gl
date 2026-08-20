//! Depth buffer test: controlling which fragments pass the depth comparison.
//!
//! Enable the test with [`state.enable(.depth_test)`](state.enable), choose
//! the comparison function with [`depthFunc`](depthFunc) and control writes
//! with [`depthMask`](depthMask).

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// Sets the comparison function of the depth test (port of `glDepthFunc`).
///
/// The fragment passes the test if `fragment_depth <func> stored_depth`
/// evaluates to `true`. The default function is
/// [`Comparison.less`](enums.Comparison.less).
///
/// ```
/// gl.state.enable(.depth_test);
/// gl.depth.depthFunc(.lequal);
/// ```
pub fn depthFunc(func: enums.Comparison) void {
    loader.context.depthFunc(@intFromEnum(func));
}

/// Enables or disables writes to the depth buffer (port of `glDepthMask`).
///
/// When writes are disabled, the depth test still runs, but the stored depth
/// value is not modified. Useful for rendering overlays that must not change
/// the depth buffer.
pub fn depthMask(flag: bool) void {
    loader.context.depthMask(@intFromBool(flag));
}

/// Sets the mapping of normalized depth values to window depth values
/// (port of `glDepthRangef`).
///
/// Both values are clamped to the [0, 1] range by the driver; the default is
/// `(0.0, 1.0)`.
pub fn depthRange(n: f32, f: f32) void {
    loader.context.depth_rangef(n, f);
}