//! Example application demonstrating the usage of the `gl` bindings.
//!
//! Real applications obtain the function addresses from their platform
//! loader (e.g. `eglGetProcAddress`); this example uses a stub loader to
//! show the error handling flow, and runs a few compile-time checks of the
//! API.

const std = @import("std");
const gl = @import("gl");

/// Stub loader for the example: always fails to resolve a function.
fn stubLoader(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    std.debug.print("  resolving '{s}' -> null\n", .{name});
    return null;
}

pub fn main() !void {
    // Loading the context requires a platform-specific loader function.
    // After a successful load, every namespace is ready to use:
    //
    //     gl.viewport.viewport(0, 0, width, height);
    //     gl.clear.clearColor(0.2, 0.3, 0.3, 1.0);
    //     gl.clear.clear(.{ .color = true });
    //     gl.state.enable(.depth_test);
    //     gl.drawing.drawArrays(.triangles, 0, 36);
    //
    gl.loader.load(stubLoader) catch |err| {
        // Without a real loader the first function lookup fails with
        // error.GetStringUnavailable; this is expected in this example.
        std.debug.print("loader.load failed: {s}\n", .{@errorName(err)});
    };

    // Extension queries are only valid after the context has been loaded.
    if (gl.loader.hasExtension("GL_KHR_debug")) |supported| {
        std.debug.print("extension supported: {}\n", .{supported});
    } else |err| {
        std.debug.print("extension check failed: {s}\n", .{@errorName(err)});
    }

    // Showcase of the typed enumerations — no GL calls are involved here.
    const mask = gl.enums.BufferMask{ .color = true, .depth = true };
    std.debug.print("clear mask bits: 0x{X:0>8}\n", .{mask.bits()});
    std.debug.print("GL_MAX_TEXTURE_SIZE = 0x{X}\n", .{@intFromEnum(gl.state.GetPName.max_texture_size)});
}

test "enum values match the OpenGL ES 3.0 specification" {
    try std.testing.expectEqual(@as(u32, 0x0500), @intFromEnum(gl.enums.ErrorCode.invalid_enum));
    try std.testing.expectEqual(@as(u32, 0x1406), @intFromEnum(gl.enums.DataType.float));
    try std.testing.expectEqual(@as(u32, 0x0201), @intFromEnum(gl.enums.Comparison.less));
    try std.testing.expectEqual(@as(u32, 0x0404), @intFromEnum(gl.enums.Face.front));
}

test "buffer mask bit values" {
    const mask = gl.enums.BufferMask{ .color = true, .depth = true, .stencil = true };
    try std.testing.expectEqual(@as(u32, 0x00004500), mask.bits());
}