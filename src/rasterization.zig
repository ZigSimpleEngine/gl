//! Rasterization control: face culling, winding order, line width, polygon
//! offset and the scissor rectangle.
//!
//! All operations of this namespace affect how primitives are converted into
//! fragments.

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// Winding order used to classify a face as front or back
/// (`GL_CW`, `GL_CCW`).
pub const FrontFaceDirection = enum(u32) {
    /// Clockwise winding (`GL_CW`).
    cw = 0x0900,

    /// Counter-clockwise winding (`GL_CCW`, the default).
    ccw = 0x0901,
};

/// Selects which faces are culled (discarded) before rasterization
/// (port of `glCullFace`).
///
/// The culling itself is only active when
/// [`state.enable(.cullFace)`](state.enable) is on.
///
/// ```
/// gl.state.enable(.cullFace);
/// gl.rasterization.cullFace(.back);
/// ```
pub fn cullFace(mode: enums.Face) void {
    loader.context.cullFace(@intFromEnum(mode));
}

/// Sets the winding order that classifies a polygon as front-facing
/// (port of `glFrontFace`).
pub fn frontFace(mode: FrontFaceDirection) void {
    loader.context.frontFace(@intFromEnum(mode));
}

/// Sets the width of rasterized lines in pixels (port of `glLineWidth`).
///
/// The value is clamped to the range reported by
/// `GL_ALIASED_LINE_WIDTH_RANGE` (typically [1, 1] in OpenGL ES, so wider
/// lines may require geometry with quads instead).
pub fn lineWidth(width: f32) void {
    loader.context.lineWidth(width);
}

/// Applies a depth offset to filled polygons (port of `glPolygonOffset`).
///
/// The offset depends on the polygon's depth slope and is useful to avoid
/// z-fighting when rendering decals or outlines on top of coplanar geometry.
/// Active only when [`state.enable(.polygon_offset_fill)`](state.enable)
/// is on.
///
/// ```
/// gl.state.enable(.polygon_offset_fill);
/// gl.rasterization.polygonOffset(1.0, 1.0);
/// ```
pub fn polygonOffset(factor: f32, units: f32) void {
    loader.context.polygonOffset(factor, units);
}

/// Sets the multisample coverage value and its inversion (port of
/// `glSampleCoverage`).
///
/// Only fragments whose coverage mask intersects the sample covered by
/// `value` are written; `invert` negates the coverage mask first. Active only
/// when [`state.enable(.sampleCoverage)`](state.enable) is on.
pub fn sampleCoverage(value: f32, invert: bool) void {
    loader.context.sampleCoverage(value, @intFromBool(invert));
}

/// Restricts all writes to the given pixel rectangle (port of `glScissor`).
///
/// The rectangle is given in framebuffer pixel coordinates with the
/// lower-left corner at (`x`, `y`). Active only when
/// [`state.enable(.scissor_test)`](state.enable) is on.
///
/// ```
/// gl.state.enable(.scissor_test);
/// gl.rasterization.scissor(0, 0, width, height);
/// ```
pub fn scissor(x: i32, y: i32, width: i32, height: i32) void {
    loader.context.scissor(x, y, width, height);
}