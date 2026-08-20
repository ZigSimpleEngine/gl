//! Program objects: linked shader pipelines.
//!
//! A program links the attached vertex and fragment shaders into a single
//! object that can be activated with [`use`](use) for rendering. This
//! namespace covers the program lifecycle, linking, attribute binding and
//! binary interchange.

const loader = @import("loader.zig");

/// A parameter of a program read via [`getParameter`](getParameter).
pub const ProgramParameter = enum(u32) {
    /// Whether the program is flagged for deletion (`GL_DELETE_STATUS`).
    delete_status = 0x8B80,

    /// Whether the last link succeeded ([`boolean`], `GL_LINK_STATUS`).
    link_status = 0x8B82,

    /// Whether the last validation succeeded ([`boolean`],
    /// `GL_VALIDATE_STATUS`).
    validate_status = 0x8B83,

    /// Length of the info log including the NUL terminator
    /// (`GL_INFO_LOG_LENGTH`).
    info_log_length = 0x8B84,

    /// Number of attached shaders (`GL_ATTACHED_SHADERS`).
    attached_shaders = 0x8B85,

    /// Number of active vertex attributes (`GL_ACTIVE_ATTRIBUTES`).
    active_attributes = 0x8B89,

    /// Maximum name length of active attributes including the NUL terminator
    /// (`GL_ACTIVE_ATTRIBUTE_MAX_LENGTH`).
    active_attribute_max_length = 0x8B8A,

    /// Number of active uniforms (`GL_ACTIVE_UNIFORMS`).
    active_uniforms = 0x8B86,

    /// Maximum name length of active uniforms including the NUL terminator
    /// (`GL_ACTIVE_UNIFORM_MAX_LENGTH`).
    active_uniform_max_length = 0x8B87,

    /// Buffer mode of transform feedback
    /// ([`transform_feedback.BufferMode`](transform_feedback.BufferMode),
    /// `GL_TRANSFORM_FEEDBACK_BUFFER_MODE`).
    transform_feedback_buffer_mode = 0x8C2F,

    /// Number of recorded transform feedback varyings
    /// (`GL_TRANSFORM_FEEDBACK_VARYINGS`).
    transform_feedback_varyings = 0x8C30,

    /// Maximum name length of transform feedback varyings including the NUL
    /// terminator (`GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH`).
    transform_feedback_varying_max_length = 0x8C76,

    /// Number of active uniform blocks (`GL_ACTIVE_UNIFORM_BLOCKS`).
    active_uniform_blocks = 0x8A36,

    /// Maximum name length of active uniform blocks including the NUL
    /// terminator (`GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH`).
    active_uniform_block_max_name_length = 0x8A35,

    /// Size of the program binary in bytes (`GL_PROGRAM_BINARY_LENGTH`).
    program_binary_length = 0x8741,

    /// Hint that the program binary should be retrievable
    /// ([`boolean`], `GL_PROGRAM_BINARY_RETRIEVABLE_HINT`).
    program_binary_retrievable_hint = 0x8257,
};

/// Info about an active attribute or uniform, obtained from
/// [`getActiveAttrib`](getActiveAttrib) or
/// [`uniforms.getActiveUniform`](uniforms.getActiveUniform).
pub const ActiveInfo = struct {
    /// Number of elements of the attribute/uniform (e.g. `4` for a mat4
    /// viewed as a column-major array of 4 vec4s).
    size: i32 = 0,

    /// Native `GLenum` data type of the attribute/uniform (see
    /// [`enums.DataType`](enums.DataType)).
    kind: u32 = 0,

    /// Number of characters of the name written into the buffer (excluding
    /// the NUL terminator).
    name_length: usize = 0,
};

/// Creates a new empty program object (port of `glCreateProgram`).
///
/// Shaders must be attached and the program linked before it can be used.
/// Returns a non-zero name, or `0` on failure.
///
/// ```
/// const program = gl.programs.create();
/// defer gl.programs.delete(program);
/// ```
pub fn create() u32 {
    return loader.context.create_program();
}

/// Deletes the program (port of `glDeleteProgram`).
///
/// If the program is currently in use, deletion is deferred until it is
/// replaced by [`use`](use).
pub fn delete(program: u32) void {
    loader.context.delete_program(program);
}

/// Returns whether `program` is the name of an existing program
/// (port of `glIsProgram`).
pub fn isProgram(program: u32) bool {
    return loader.context.isProgram(program) != 0;
}

/// Attaches a compiled shader to the program (port of `glAttachShader`).
///
/// At least one vertex shader and one fragment shader must be attached for a
/// usable pipeline.
pub fn attach(program: u32, shader: u32) void {
    loader.context.attach_shader(program, shader);
}

/// Detaches a shader from the program (port of `glDetachShader`).
pub fn detach(program: u32, shader: u32) void {
    loader.context.detach_shader(program, shader);
}

/// Links the attached shaders into an executable program (port of
/// `glLinkProgram`).
///
/// The result is reported through the `GL_LINK_STATUS` parameter
/// ([`getParameter`](getParameter)); diagnostics are available via
/// [`getInfoLog`](getInfoLog).
///
/// ```
/// gl.programs.link(program);
/// if (gl.programs.getParameter(program, .link_status, &ok) != 0) { ... }
/// ```
pub fn link(program: u32) void {
    loader.context.link_program(program);
}

/// Validates the program against the current context state (port of
/// `glValidateProgram`).
///
/// Checks that the program can be executed with the currently bound
/// framebuffer, textures and enabled attributes.
pub fn validate(program: u32) void {
    loader.context.validate_program(program);
}

/// Activates the program for rendering (port of `glUseProgram`).
///
/// Passing `0` deactivates programs. The same program can be used after
/// re-linking without re-calling this function.
pub fn use(program: u32) void {
    loader.context.use_program(program);
}

/// Predetermines the location of a vertex attribute (port of
/// `glBindAttribLocation`).
///
/// Must be called before linking; after linking the location can be obtained
/// with [`getAttribLocation`](getAttribLocation).
pub fn bindAttribLocation(program: u32, index: u32, name: [:0]const u8) void {
    loader.context.bindAttribLocation(program, index, name);
}

/// Returns the location of the vertex attribute `name` in the linked program
/// (port of `glGetAttribLocation`).
///
/// Returns `-1` if the attribute is inactive or does not exist.
pub fn getAttribLocation(program: u32, name: [:0]const u8) i32 {
    return loader.context.getAttribLocation(program, name);
}

/// Returns the output location of the fragment shader output `name` for the
/// given program (port of `glGetFragDataLocation`).
///
/// Returns `-1` if the output is inactive or does not exist.
pub fn getFragDataLocation(program: u32, name: [:0]const u8) i32 {
    return loader.context.getFragDataLocation(program, name);
}

/// Reads a parameter of the program (port of `glGetProgramiv`).
pub fn getParameter(program: u32, pname: ProgramParameter, params: [*]i32) void {
    loader.context.get_program_iv(program, @intFromEnum(pname), params);
}

/// Retrieves the link log of the program into `buf` (port of
/// `glGetProgramInfoLog`).
///
/// Returns the number of characters written (excluding the NUL terminator).
///
/// ```
/// var log: [512]u8 = undefined;
/// const len = gl.programs.getInfoLog(program, &log);
/// ```
pub fn getInfoLog(program: u32, buf: []u8) usize {
    var length: i32 = 0;
    loader.context.get_program_info_log(program, @intCast(buf.len), &length, buf.ptr);
    return @intCast(@max(length, 0));
}

/// Writes the names of the attached shaders into `shaders` (port of
/// `glGetAttachedShaders`).
///
/// Returns the number of shaders written.
pub fn getAttachedShaders(program: u32, shaders: []u32) usize {
    var count: i32 = 0;
    loader.context.getAttachedShaders(program, @intCast(shaders.len), &count, shaders.ptr);
    return @intCast(@max(count, 0));
}

/// Queries the info of the active attribute at `index` (port of
/// `glGetActiveAttrib`).
///
/// The attribute name (excluding the NUL terminator) is written into
/// `name_buf`; if the buffer is too small, the name is truncated.
pub fn getActiveAttrib(program: u32, index: u32, name_buf: []u8) ActiveInfo {
    var size: i32 = 0;
    var kind: u32 = 0;
    var length: i32 = 0;
    loader.context.getActiveAttrib(
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

/// Loads the program binary into `binary_buf` (port of `glGetProgramBinary`).
///
/// The format needed by [`programBinary`](programBinary) is written into
/// `binary_format` (may be `null`). Returns the number of bytes written.
/// The program must have been linked with the
/// [`ProgramParameter.program_binary_retrievable_hint`](ProgramParameter.program_binary_retrievable_hint)
/// set.
pub fn getBinary(program: u32, binary_buf: []u8, binary_format: ?*u32) usize {
    var length: i32 = 0;
    var format: u32 = 0;
    loader.context.get_program_binary(
        program,
        @intCast(binary_buf.len),
        &length,
        &format,
        binary_buf.ptr,
    );
    if (binary_format) |dst| dst.* = format;
    return @intCast(@max(length, 0));
}

/// Loads a binary into the program, replacing its compiled shaders (port of
/// `glProgramBinary`).
///
/// The binary must have been produced with [`getBinary`](getBinary) on a
/// compatible implementation, and `format` must match the reported format.
pub fn programBinary(program: u32, format: u32, binary: ?*const anyopaque, length: i32) void {
    loader.context.programBinary(program, format, binary, length);
}

/// Sets a program parameter such as the binary retrievability hint (port of
/// `glProgramParameteri`).
pub fn programParameterI(program: u32, pname: ProgramParameter, value: i32) void {
    loader.context.programParameterI(program, @intFromEnum(pname), value);
}