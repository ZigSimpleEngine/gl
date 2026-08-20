//! Shader objects: compilation units of GLSL source code.
//!
//! Shaders are created with [`create`](create), fed with source via
//! [`source`](source), compiled with [`compile`](compile) and attached to a
//! program ([`programs.attach`](programs.attach)).

const loader = @import("loader.zig");

/// Type (stage) of a shader (`GL_VERTEX_SHADER`, `GL_FRAGMENT_SHADER`).
pub const ShaderType = enum(u32) {
    /// Vertex shader, run once per vertex (`GL_VERTEX_SHADER`).
    vertex_shader = 0x8B31,

    /// Fragment shader, run once per fragment (`GL_FRAGMENT_SHADER`).
    fragment_shader = 0x8B30,
};

/// A parameter of a shader read via [`getParameter`](getParameter).
pub const ShaderParameter = enum(u32) {
    /// Type of the shader ([`ShaderType`](ShaderType), `GL_SHADER_TYPE`).
    shader_type = 0x8B4F,

    /// Whether the shader is flagged for deletion (`GL_DELETE_STATUS`).
    delete_status = 0x8B80,

    /// Whether the last compilation succeeded ([`boolean`],
    /// `GL_COMPILE_STATUS`).
    compile_status = 0x8B81,

    /// Length of the info log including the NUL terminator
    /// (`GL_INFO_LOG_LENGTH`).
    info_log_length = 0x8B84,

    /// Length of the shader source including the NUL terminator
    /// (`GL_SHADER_SOURCE_LENGTH`).
    shader_source_length = 0x8B88,
};

/// Precision class used by [`getPrecisionFormat`](getPrecisionFormat)
/// (`GL_LOW_FLOAT`, `GL_MEDIUM_INT`, ...).
pub const PrecisionType = enum(u32) {
    /// Low-precision floating point (`GL_LOW_FLOAT`).
    low_float = 0x8DF0,

    /// Medium-precision floating point (`GL_MEDIUM_FLOAT`).
    medium_float = 0x8DF1,

    /// High-precision floating point (`GL_HIGH_FLOAT`).
    high_float = 0x8DF2,

    /// Low-precision integer (`GL_LOW_INT`).
    low_int = 0x8DF3,

    /// Medium-precision integer (`GL_MEDIUM_INT`).
    medium_int = 0x8DF4,

    /// High-precision integer (`GL_HIGH_INT`).
    high_int = 0x8DF5,
};

/// Creates a new empty shader of the given type (port of `glCreateShader`).
///
/// The shader must be fed with source and compiled before it can be attached
/// to a program. Returns a non-zero name, or `0` on failure.
///
/// ```
/// const shader = gl.shaders.create(.vertex_shader);
/// defer gl.shaders.delete(shader);
/// ```
pub fn create(kind: ShaderType) u32 {
    return loader.context.create_shader(@intFromEnum(kind));
}

/// Deletes the shader (port of `glDeleteShader`).
///
/// If the shader is attached to a program, deletion is deferred until it is
/// detached.
pub fn delete(shader: u32) void {
    loader.context.delete_shader(shader);
}

/// Returns whether `shader` is the name of an existing shader
/// (port of `glIsShader`).
pub fn isShader(shader: u32) bool {
    return loader.context.isShader(shader) != 0;
}

/// Replaces the source code of the shader (port of `glShaderSource`).
///
/// The source is copied by the driver, so the slice may be reused after the
/// call. Multiple calls replace the previous source.
///
/// ```
/// gl.shaders.source(shader, vertex_source);
/// ```
pub fn source(shader: u32, text: []const u8) void {
    const z = text.ptr[0..text.len :0];
    loader.context.shader_source(shader, 1, @ptrCast(&z), null);
}

/// Compiles the shader (port of `glCompileShader`).
///
/// The result is reported through the `GL_COMPILE_STATUS` parameter; a
/// detailed diagnostic is available via [`getInfoLog`](getInfoLog).
///
/// ```
/// gl.shaders.compile(shader);
/// if (gl.shaders.getParameter(shader, .compile_status, &status) != 0) { ... }
/// ```
pub fn compile(shader: u32) void {
    loader.context.compile_shader(shader);
}

/// Reads a parameter of the shader (port of `glGetShaderiv`).
pub fn getParameter(shader: u32, pname: ShaderParameter, params: [*]i32) void {
    loader.context.get_shader_iv(shader, @intFromEnum(pname), params);
}

/// Retrieves the compilation log of the shader into `buf` (port of
/// `glGetShaderInfoLog`).
///
/// Returns the number of characters written (excluding the NUL terminator).
/// Empty on success, contains diagnostics after a failed compilation.
///
/// ```
/// var log: [512]u8 = undefined;
/// const len = gl.shaders.getInfoLog(shader, &log);
/// ```
pub fn getInfoLog(shader: u32, buf: []u8) usize {
    var length: i32 = 0;
    loader.context.get_shader_info_log(shader, @intCast(buf.len), &length, buf.ptr);
    return @intCast(@max(length, 0));
}

/// Retrieves the source code previously set with [`source`](source) into
/// `buf` (port of `glGetShaderSource`).
///
/// Returns the number of characters written (excluding the NUL terminator).
pub fn getSource(shader: u32, buf: []u8) usize {
    var length: i32 = 0;
    loader.context.get_shader_source(shader, @intCast(buf.len), &length, buf.ptr);
    return @intCast(@max(length, 0));
}

/// Queries the supported range and precision of the given precision class
/// for the given shader type (port of `glGetShaderPrecisionFormat`).
///
/// `range` receives two values: the base-2 exponent range of the mantissa
/// as `[min_exp, max_exp]`; `precision` receives the number of significant
/// mantissa bits (may be `null` for integer classes).
pub fn getPrecisionFormat(
    shader_type: ShaderType,
    precision_type: PrecisionType,
    range: [*]i32,
    precision: ?*i32,
) void {
    loader.context.get_shader_precision_format(
        @intFromEnum(shader_type),
        @intFromEnum(precision_type),
        range,
        precision,
    );
}

/// Signals that the shader compiler is not needed for a while, allowing the
/// driver to free associated resources (port of `glReleaseShaderCompiler`).
///
/// Subsequent shader creation may take longer until the compiler is loaded
/// again.
pub fn releaseCompiler() void {
    loader.context.release_shader_compiler();
}