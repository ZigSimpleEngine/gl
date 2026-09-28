//! Shared real-GL setup for test binaries.
//!
//! This file contains no test blocks itself; it is imported by the test
//! roots (`test.zig`, `test_state_parameters.zig`) which only compile when
//! the optional local rgfw checkout is present (see `build.zig`).
//!
//! `ensureRealSetup` opens a hidden RGFW window (desktop GL 4.6 core with a
//! 3.3 core fallback), makes its context current, loads it with
//! `gl.loader.load`, and leaves minimal valid state bound: a vertex array
//! with a triangle (positions + indices) and a linked shader program in use.
//! Everything is process-lifetime on purpose: the hidden window is never
//! shown and the operating system reclaims it on exit.
//!
//! Silent by design: test binaries must not write to stderr under
//! `zig build test` (Zig 0.16 `--listen` IPC quirk on Windows turns any
//! child output into a spurious `failed command` line). Failures surface as
//! returned errors, which the runner reports against the calling test.

const std = @import("std");
const gl = @import("gl");
const rgfw = @import("rgfw");

/// Setup completed successfully at least once in this process.
var setupCompleted = false;

/// Name of the shared vertex array created by the setup.
var sharedVertexArray: u32 = 0;

/// Name of the shared array buffer holding triangle positions.
var sharedArrayBuffer: u32 = 0;

/// Name of the shared fallback shader program, left in use.
var sharedProgram: u32 = 0;

/// Counter-clockwise triangle in normalized device coordinates.
const trianglePositions = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

/// Indices addressing every triangle vertex once.
const triangleIndices = [_]u16{ 0, 1, 2 };

/// Minimal vertex shader of the shared fallback program.
const sharedVertexSource =
    \\#version 330 core
    \\layout(location = 0) in vec3 position;
    \\void main() { gl_Position = vec4(position, 1.0); }
;

/// Minimal fragment shader of the shared fallback program.
const sharedFragmentSource =
    \\#version 330 core
    \\out vec4 fragColor;
    \\void main() { fragColor = vec4(1.0, 0.5, 0.0, 1.0); }
;

/// Opens a hidden RGFW window with the requested desktop GL version.
/// Returns null when no display or context creation is possible.
fn openHiddenWindow(major: i32, minor: i32) ?*rgfw.Window {
    var hints = rgfw.GlHints{
        .major = major,
        .minor = minor,
        .profile = .core,
        .depth = 24,
        .stencil = 8,
    };
    rgfw.opengl.setGlobalHints(&hints);
    return rgfw.createWindow(
        "gl-tests",
        .{ .x = 0, .y = 0 },
        .{ .w = 640, .h = 480 },
        .{ .openGl = true, .hide = true, .noResize = true },
    );
}

/// Compiles a shader of the given kind from source and asserts success.
fn compileChecked(kind: gl.shaders.ShaderType, source: []const u8) !u32 {
    const shader = gl.shaders.create(kind);
    gl.shaders.source(shader, source);
    gl.shaders.compile(shader);
    var status: [1]i32 = undefined;
    gl.shaders.getParameter(shader, .compile_status, &status);
    try std.testing.expectEqual(@as(i32, 1), status[0]);
    return shader;
}

/// Builds the shared fallback state: vertex array, buffers and program.
/// Assumes a current real GL context.
fn buildSharedState() !void {
    gl.vertex_arrays.gen(1, @ptrCast(&sharedVertexArray));
    gl.vertex_arrays.bind(sharedVertexArray);

    gl.buffers.gen(1, @ptrCast(&sharedArrayBuffer));
    gl.buffers.bind(.array_buffer, sharedArrayBuffer);
    gl.buffers.bufferDataSlice(.array_buffer, std.mem.sliceAsBytes(&trianglePositions), .static_draw);

    var indexBuffer: u32 = 0;
    gl.buffers.gen(1, @ptrCast(&indexBuffer));
    gl.buffers.bind(.element_array_buffer, indexBuffer);
    gl.buffers.bufferDataSlice(.element_array_buffer, std.mem.sliceAsBytes(&triangleIndices), .static_draw);

    gl.vertex_attributes.pointer(0, 3, .float, false, 0, null);
    gl.vertex_attributes.enable(0);

    const vertexShader = try compileChecked(.vertex_shader, sharedVertexSource);
    defer gl.shaders.delete(vertexShader);
    const fragmentShader = try compileChecked(.fragment_shader, sharedFragmentSource);
    defer gl.shaders.delete(fragmentShader);

    sharedProgram = gl.programs.create();
    gl.programs.attach(sharedProgram, vertexShader);
    gl.programs.attach(sharedProgram, fragmentShader);
    gl.programs.bindAttribLocation(sharedProgram, 0, "position");
    gl.programs.link(sharedProgram);
    var status: [1]i32 = undefined;
    gl.programs.getParameter(sharedProgram, .link_status, &status);
    try std.testing.expectEqual(@as(i32, 1), status[0]);
    gl.programs.use(sharedProgram);
}

/// Ensures a real GL context with fallback valid state, once per process.
///
/// Returns `error.RealGlContextUnavailable` when no display or GL context
/// can be obtained. Callers propagate it with `try`, so a headless run is
/// visibly red rather than silently green.
pub fn ensureRealSetup() !void {
    if (setupCompleted) return;
    if (rgfw.init("gl-tests", .{ .openGl = true }) < 0) {
        return error.RealGlContextUnavailable;
    }
    const window = openHiddenWindow(4, 6) orelse openHiddenWindow(3, 3) orelse {
        return error.RealGlContextUnavailable;
    };
    rgfw.opengl.makeCurrentContext(window);
    gl.loader.load(rgfw.opengl.getProcAddress) catch {
        return error.RealGlContextUnavailable;
    };
    try buildSharedState();
    setupCompleted = true;
}

/// Rebinds the shared fallback state (vertex array, buffers, program).
///
/// Call before any draw in tests that may run after other tests rebound or
/// deleted GL objects; the operation is idempotent.
pub fn useSharedProgram() void {
    gl.vertex_arrays.bind(sharedVertexArray);
    gl.buffers.bind(.array_buffer, sharedArrayBuffer);
    gl.vertex_attributes.pointer(0, 3, .float, false, 0, null);
    gl.vertex_attributes.enable(0);
    gl.programs.use(sharedProgram);
}
