//! Stencil buffer test: comparing fragments against a stored value.
//!
//! Enable the test with [`state.enable(.stencil_test)`](state.enable), set
//! the comparison with [`stencilFunc`](stencilFunc) and define the actions
//! with [`stencilOp`](stencilOp). Separate settings for front and back
//! faces are provided by the `*_separate` variants.

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// Action performed on the stencil buffer when a fragment fails or passes a
/// test (`GL_KEEP`, `GL_REPLACE`, `GL_INCR`, ...).
pub const StencilOp = enum(u32) {
    /// Keep the current stencil value (`GL_KEEP`).
    keep = 0x1E00,

    /// Replace the stencil value with the reference value (`GL_REPLACE`).
    replace = 0x1E01,

    /// Increment the stencil value, clamping at the maximum (`GL_INCR`).
    incr = 0x1E02,

    /// Decrement the stencil value, clamping at zero (`GL_DECR`).
    decr = 0x1E03,

    /// Invert every bit of the stencil value (`GL_INVERT`).
    invert = 0x150A,

    /// Increment the stencil value, wrapping around at the maximum
    /// (`GL_INCR_WRAP`).
    incr_wrap = 0x8507,

    /// Decrement the stencil value, wrapping around at zero
    /// (`GL_DECR_WRAP`).
    decr_wrap = 0x8508,

    /// Set the stencil value to zero (`GL_ZERO`).
    zero = 0x0000,
};

/// Sets the comparison function, reference value and value mask for both
/// front and back faces (port of `glStencilFunc`).
///
/// The fragment passes the test if `(reference & mask) <func>
/// (stored_value & mask)` evaluates to `true`.
pub fn stencilFunc(func: enums.Comparison, reference: i32, mask: u32) void {
    loader.context.stencilFunc(@intFromEnum(func), reference, mask);
}

/// Sets the comparison function, reference value and value mask for the
/// given face only (port of `glStencilFuncSeparate`).
///
/// `face` can be [`enums.Face.front`](enums.Face.front),
/// [`enums.Face.back`](enums.Face.back) or
/// [`enums.Face.front_and_back`](enums.Face.front_and_back).
pub fn stencilFuncSeparate(face: enums.Face, func: enums.Comparison, reference: i32, mask: u32) void {
    loader.context.stencilFuncSeparate(@intFromEnum(face), @intFromEnum(func), reference, mask);
}

/// Sets the stencil write mask for both front and back faces
/// (port of `glStencilMask`).
pub fn stencilMask(mask: u32) void {
    loader.context.stencilMask(mask);
}

/// Sets the stencil write mask for the given face only
/// (port of `glStencilMaskSeparate`).
pub fn stencilMaskSeparate(face: enums.Face, mask: u32) void {
    loader.context.stencilMaskSeparate(@intFromEnum(face), mask);
}

/// Sets the actions for all three stencil test outcomes, applied to both
/// front and back faces (port of `glStencilOp`).
///
/// - `fail` — the fragment failed the stencil test;
/// - `z_fail` — the fragment passed the stencil test but failed the depth test;
/// - `z_pass` — the fragment passed both tests.
pub fn stencilOp(fail: StencilOp, z_fail: StencilOp, z_pass: StencilOp) void {
    loader.context.stencilOp(@intFromEnum(fail), @intFromEnum(z_fail), @intFromEnum(z_pass));
}

/// Sets the actions for all three stencil test outcomes for the given face
/// only (port of `glStencilOpSeparate`).
pub fn stencilOpSeparate(face: enums.Face, sfail: StencilOp, dpfail: StencilOp, dppass: StencilOp) void {
    loader.context.stencilOpSeparate(@intFromEnum(face), @intFromEnum(sfail), @intFromEnum(dpfail), @intFromEnum(dppass));
}