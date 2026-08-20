//! Error reporting: retrieving the driver error state.
//!
//! OpenGL reports errors asynchronously: invalid calls do not raise
//! exceptions but set a per-context error flag that must be polled with
//! [`getError`](getError).

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// Returns the current error code and clears the error flag (port of
/// `glGetError`).
///
/// Returns [`enums.ErrorCode.no_error`](enums.ErrorCode.no_error) if no
/// error has occurred since the last call. Errors occur in the order the
/// commands were issued, regardless of how quickly they are polled.
///
/// ```
/// const err = gl.errors.getError();
/// if (err != .no_error) { log("GL error: {s}", .{@tagName(err)}); }
/// ```
pub fn getError() enums.ErrorCode {
    return @enumFromInt(loader.context.getError());
}