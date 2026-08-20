//! Blending of the fragment color with the destination color.
//!
//! When [`state.enable(.blend)`](state.enable) is active, the color of each
//! fragment is combined with the color already present in the framebuffer
//! according to the equations and factors configured in this namespace.
//!
//! The classic alpha blending setup:
//!
//! ```
//! gl.state.enable(.blend);
//! gl.blending.blendFunc(.src_alpha, .one_minus_src_alpha);
//! ```

const loader = @import("loader.zig");

/// Blend factor used to scale the source and destination colors
/// (`GL_SRC_ALPHA`, `GL_ONE_MINUS_SRC_ALPHA`, ...).
pub const BlendFactor = enum(u32) {
    /// Scale by zero (`GL_ZERO`).
    zero = 0x0000,

    /// Scale by one (`GL_ONE`).
    one = 0x0001,

    /// Scale by the source color components (`GL_SRC_COLOR`).
    src_color = 0x0300,

    /// Scale by one minus the source color components (`GL_ONE_MINUS_SRC_COLOR`).
    one_minus_src_color = 0x0301,

    /// Scale by the source alpha component (`GL_SRC_ALPHA`).
    src_alpha = 0x0302,

    /// Scale by one minus the source alpha component (`GL_ONE_MINUS_SRC_ALPHA`).
    one_minus_src_alpha = 0x0303,

    /// Scale by the destination alpha component (`GL_DST_ALPHA`).
    dst_alpha = 0x0304,

    /// Scale by one minus the destination alpha component
    /// (`GL_ONE_MINUS_DST_ALPHA`).
    one_minus_dst_alpha = 0x0305,

    /// Scale by the destination color components (`GL_DST_COLOR`).
    dst_color = 0x0306,

    /// Scale by one minus the destination color components
    /// (`GL_ONE_MINUS_DST_COLOR`).
    one_minus_dst_color = 0x0307,

    /// Scale by the smaller of the source alpha and one minus the destination
    /// alpha (`GL_SRC_ALPHA_SATURATE`).
    src_alpha_saturate = 0x0308,

    /// Scale by the constant color components (`GL_CONSTANT_COLOR`, set with
    /// [`blendColor`](blendColor)).
    constant_color = 0x8001,

    /// Scale by one minus the constant color components
    /// (`GL_ONE_MINUS_CONSTANT_COLOR`).
    one_minus_constant_color = 0x8002,

    /// Scale by the constant alpha component (`GL_CONSTANT_ALPHA`).
    constant_alpha = 0x8003,

    /// Scale by one minus the constant alpha component
    /// (`GL_ONE_MINUS_CONSTANT_ALPHA`).
    one_minus_constant_alpha = 0x8004,
};

/// Arithmetic applied to the source and destination colors during blending
/// (`GL_FUNC_ADD`, `GL_FUNC_SUBTRACT`, ...).
pub const BlendEquation = enum(u32) {
    /// `source + destination` (`GL_FUNC_ADD`).
    func_add = 0x8006,

    /// The per-component minimum of source and destination (`GL_MIN`).
    min = 0x8007,

    /// The per-component maximum of source and destination (`GL_MAX`).
    max = 0x8008,

    /// `source - destination` (`GL_FUNC_SUBTRACT`).
    func_subtract = 0x800A,

    /// `destination - source` (`GL_FUNC_REVERSE_SUBTRACT`).
    func_reverse_subtract = 0x800B,
};

/// Sets the constant blend color used by `GL_CONSTANT_COLOR` and
/// `GL_CONSTANT_ALPHA` factors (port of `glBlendColor`).
///
/// All components are clamped to the [0, 1] range by the driver.
pub fn blendColor(red: f32, green: f32, blue: f32, alpha: f32) void {
    loader.context.blendColor(red, green, blue, alpha);
}

/// Sets the blend equation used for both RGB and alpha components
/// (port of `glBlendEquation`).
pub fn blendEquation(mode: BlendEquation) void {
    loader.context.blendEquation(@intFromEnum(mode));
}

/// Sets the blend equations for RGB and alpha components independently
/// (port of `glBlendEquationSeparate`).
pub fn blendEquationSeparate(mode_rgb: BlendEquation, mode_alpha: BlendEquation) void {
    loader.context.blendEquationSeparate(@intFromEnum(mode_rgb), @intFromEnum(mode_alpha));
}

/// Sets the blend factors used for both RGB and alpha components
/// (port of `glBlendFunc`).
pub fn blendFunc(sfactor: BlendFactor, dfactor: BlendFactor) void {
    loader.context.blendFunc(@intFromEnum(sfactor), @intFromEnum(dfactor));
}

/// Sets the blend factors for RGB and alpha components independently
/// (port of `glBlendFuncSeparate`).
pub fn blendFuncSeparate(
    sfactor_rgb: BlendFactor,
    dfactor_rgb: BlendFactor,
    sfactor_alpha: BlendFactor,
    dfactor_alpha: BlendFactor,
) void {
    loader.context.blendFuncSeparate(
        @intFromEnum(sfactor_rgb),
        @intFromEnum(dfactor_rgb),
        @intFromEnum(sfactor_alpha),
        @intFromEnum(dfactor_alpha),
    );
}