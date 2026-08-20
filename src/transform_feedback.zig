//! Transform feedback: capturing the vertex shader output into buffers.
//!
//! Client-side geometry processing (e.g. particle simulation) is performed
//! by capturing the varying outputs of a draw call directly into GPU
//! buffers instead of rasterizing them.

const loader = @import("loader.zig");
const drawing = @import("drawing.zig");
const programs = @import("programs.zig");

/// Layout of the captured varyings within the feedback buffers
/// (`GL_INTERLEAVED_ATTRIBS`, `GL_SEPARATE_ATTRIBS`).
pub const BufferMode = enum(u32) {
    /// All varyings are written into one interleaved buffer
    /// (`GL_INTERLEAVED_ATTRIBS`).
    interleaved_attribs = 0x8C8C,

    /// Each varying is written into its own buffer (`GL_SEPARATE_ATTRIBS`).
    separate_attribs = 0x8C8D,
};

/// Re-export of [`programs.ActiveInfo`](programs.ActiveInfo), used by
/// [`getVarying`](getVarying).
pub const ActiveInfo = programs.ActiveInfo;

/// Generates `n` new transform feedback names (port of
/// `glGenTransformFeedbacks`).
///
/// Names do not become transform feedback objects until first bound.
pub fn gen(n: i32, ids: [*]u32) void {
    loader.context.gen_transform_feedbacks(n, ids);
}

/// Deletes the given transform feedback objects (port of
/// `glDeleteTransformFeedbacks`).
pub fn delete(n: i32, ids: [*]const u32) void {
    loader.context.delete_transform_feedbacks(n, ids);
}

/// Returns whether `id` is the name of an existing transform feedback
/// object (port of `glIsTransformFeedback`).
pub fn isTransformFeedback(id: u32) bool {
    return loader.context.isTransformFeedback(id) != 0;
}

/// Binds the transform feedback object (port of `glBindTransformFeedback`).
///
/// While active, the feedback buffers captured by the current program are
/// recorded into the bound object. Binding name `0` restores the default.
pub fn bind(id: u32) void {
    loader.context.bind_transform_feedback(0x8E22, id);
}

/// Starts capturing the current transform feedback (port of
/// `glBeginTransformFeedback`).
///
/// `mode` must match the primitive type of the subsequent draw calls
/// (points, lines or triangles). The captured varyings are those declared
/// with [`varyings`](varyings) before linking.
///
/// ```
/// gl.transform_feedback.bind(tfo);
/// gl.transform_feedback.begin(.triangles);
/// gl.drawing.drawArrays(.triangles, 0, 36);
/// gl.transform_feedback.end();
/// ```
pub fn begin(mode: drawing.PrimitiveType) void {
    loader.context.begin_transform_feedback(@intFromEnum(mode));
}

/// Stops capturing transform feedback (port of `glEndTransformFeedback`).
pub fn end() void {
    loader.context.end_transform_feedback();
}

/// Pauses capture without ending it (port of `glPauseTransformFeedback`).
///
/// Rendering can continue while paused; [`resumeCapture`](resumeCapture)
/// continues the capture.
pub fn pause() void {
    loader.context.pause_transform_feedback();
}

/// Resumes a paused transform feedback capture (port of
/// `glResumeTransformFeedback`).
pub fn resumeCapture() void {
    loader.context.resume_transform_feedback();
}

/// Declares which varyings are captured and how, before linking (port of
/// `glTransformFeedbackVaryings`).
///
/// `names` lists varying names from the linked shaders; the layout is
/// determined by `mode`. Must be called before
/// [`programs.link`](programs.link).
pub fn varyings(program: u32, names: []const [*:0]const u8, mode: BufferMode) void {
    loader.context.transform_feedback_varyings(program, @intCast(names.len), names.ptr, @intFromEnum(mode));
}

/// Queries the info of the captured varying at `index` (port of
/// `glGetTransformFeedbackVarying`).
///
/// The varying name (excluding the NUL terminator) is written into
/// `name_buf`; if the buffer is too small, the name is truncated.
pub fn getVarying(program: u32, index: u32, name_buf: []u8) ActiveInfo {
    var size: i32 = 0;
    var kind: u32 = 0;
    var length: i32 = 0;
    loader.context.get_transform_feedback_varying(
        program,
        index,
        @intCast(name_buf.len),
        &length,
        &size,
        &kind,
        name_buf.ptr,
    );
    return .{ .size = size, .kind = kind, .name_length = @intCast(@max(length, 0)) };
}