//! Loader for native OpenGL ES 3.0 functions.
//!
//! A direct Zig port of the `glad` loader logic (file `glad/gles2.c`): the
//! library is not tied to a specific platform, but receives function
//! addresses from a user-provided loader function
//! ([`types.LoadFn`](types.LoadFn)), e.g. `eglGetProcAddress`.
//!
//! Typical usage:
//!
//! ```
//! const gl = @import("gl");
//!
//! fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
//!     return platform.get_proc_address(name);
//! }
//!
//! pub fn init() !void {
//!     try gl.loader.load(getProcAddress);
//! }
//! ```
//!
//! After a successful [`load`](load), all namespaces are available:
//! [`buffers`](buffers), [`textures`](textures), [`shaders`](shaders), etc.
//! All library functions require the context to be loaded first.

const std = @import("std");
const types = @import("types.zig");

/// Error that can occur while loading the OpenGL context.
pub const LoadError = error{
    /// The loader function could not provide `glGetString`.
    GetStringUnavailable,

    /// The version string has an unexpected format, or the context is not an
    /// OpenGL ES context.
    InvalidVersion,

    /// The context reported support for a version but did not provide a
    /// required function of that version.
    MissingFunction,
};

/// Error that can occur while working with extensions before the context has
/// been initialized.
pub const ExtensionError = error{
    /// The context is not loaded yet ([`load`](load) has not been called).
    NotLoaded,

    /// The context does not support the `glGetStringi` interface (ES 2.0),
    /// and `glGetString` is unavailable.
    GetStringUnavailable,
};

/// OpenGL ES context: the set of loaded native pointers plus version
/// information.
///
/// The user usually works with the global context
/// [`loader.context`](context), which is filled by [`loader.load`](load).
/// The context fields are "raw" native pointers; typed and documented
/// wrappers are provided by the library namespaces (`gl.buffers.bind`,
/// `gl.textures.image2d`, etc.).
pub const Context = struct {
    /// Whether the context supports OpenGL ES 2.0.
    es_2_0: bool = false,

    /// Whether the context supports OpenGL ES 3.0.
    es_3_0: bool = false,

    /// Major context version (e.g. `3` for OpenGL ES 3.2).
    major: u32 = 0,

    /// Minor context version (e.g. `2` for OpenGL ES 3.2).
    minor: u32 = 0,

    // ------ OpenGL ES 2.0 and 3.0 functions ----------------------------

    /// Pointer to the native `glActiveTexture`.
    activeTexture: *const fn (texture: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glAttachShader`.
    attach_shader: *const fn (program: u32, shader: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBeginQuery`.
    begin_query: *const fn (target: u32, id: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBeginTransformFeedback`.
    begin_transform_feedback: *const fn (primitive_mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindAttribLocation`.
    bindAttribLocation: *const fn (program: u32, index: u32, name: [*:0]const u8) callconv(.c) void = undefined,

    /// Pointer to the native `glBindBuffer`.
    bind_buffer: *const fn (target: u32, buffer: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindBufferBase`.
    bind_buffer_base: *const fn (target: u32, index: u32, buffer: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindBufferRange`.
    bind_buffer_range: *const fn (target: u32, index: u32, buffer: u32, offset: isize, size: isize) callconv(.c) void = undefined,

    /// Pointer to the native `glBindFramebuffer`.
    bind_framebuffer: *const fn (target: u32, framebuffer: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindRenderbuffer`.
    bind_renderbuffer: *const fn (target: u32, renderbuffer: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindSampler`.
    bind_sampler: *const fn (unit: u32, sampler: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindTexture`.
    bind_texture: *const fn (target: u32, texture: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindTransformFeedback`.
    bind_transform_feedback: *const fn (target: u32, id: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBindVertexArray`.
    bind_vertex_array: *const fn (array: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlendColor`.
    blendColor: *const fn (red: f32, green: f32, blue: f32, alpha: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlendEquation`.
    blendEquation: *const fn (mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlendEquationSeparate`.
    blendEquationSeparate: *const fn (mode_rgb: u32, mode_alpha: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlendFunc`.
    blendFunc: *const fn (sfactor: u32, dfactor: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlendFuncSeparate`.
    blendFuncSeparate: *const fn (sfactor_rgb: u32, dfactor_rgb: u32, sfactor_alpha: u32, dfactor_alpha: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBlitFramebuffer`.
    blit_framebuffer: *const fn (src_x0: i32, src_y0: i32, src_x1: i32, src_y1: i32, dst_x0: i32, dst_y0: i32, dst_x1: i32, dst_y1: i32, mask: u32, filter: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBufferData`.
    bufferData: *const fn (target: u32, size: isize, data: ?*const anyopaque, usage: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glBufferSubData`.
    bufferSubData: *const fn (target: u32, offset: isize, size: isize, data: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glCheckFramebufferStatus`.
    check_framebuffer_status: *const fn (target: u32) callconv(.c) u32 = undefined,

    /// Pointer to the native `glClear`.
    clear: *const fn (mask: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearBufferfi`.
    clearBufferFi: *const fn (buffer: u32, drawbuffer: i32, depth: f32, stencil: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearBufferfv`.
    clearBufferFv: *const fn (buffer: u32, drawbuffer: i32, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearBufferiv`.
    clearBufferIv: *const fn (buffer: u32, drawbuffer: i32, value: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearBufferuiv`.
    clearBufferUiv: *const fn (buffer: u32, drawbuffer: i32, value: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearColor`.
    clearColor: *const fn (red: f32, green: f32, blue: f32, alpha: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearDepthf`.
    clear_depthf: *const fn (d: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glClearStencil`.
    clearStencil: *const fn (s: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glClientWaitSync`.
    client_wait_sync: *const fn (sync: types.Sync, flags: u32, timeout: u64) callconv(.c) u32 = undefined,

    /// Pointer to the native `glColorMask`.
    color_mask: *const fn (red: u8, green: u8, blue: u8, alpha: u8) callconv(.c) void = undefined,

    /// Pointer to the native `glCompileShader`.
    compile_shader: *const fn (shader: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glCompressedTexImage2D`.
    compressed_tex_image_2d: *const fn (target: u32, level: i32, internalformat: u32, width: i32, height: i32, border: i32, image_size: i32, data: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glCompressedTexImage3D`.
    compressed_tex_image_3d: *const fn (target: u32, level: i32, internalformat: u32, width: i32, height: i32, depth: i32, border: i32, image_size: i32, data: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glCompressedTexSubImage2D`.
    compressed_tex_sub_image_2d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, image_size: i32, data: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glCompressedTexSubImage3D`.
    compressed_tex_sub_image_3d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, image_size: i32, data: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glCopyBufferSubData`.
    copy_buffer_sub_data: *const fn (read_target: u32, write_target: u32, read_offset: isize, write_offset: isize, size: isize) callconv(.c) void = undefined,

    /// Pointer to the native `glCopyTexImage2D`.
    copy_tex_image_2d: *const fn (target: u32, level: i32, internalformat: u32, x: i32, y: i32, width: i32, height: i32, border: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glCopyTexSubImage2D`.
    copy_tex_sub_image_2d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, x: i32, y: i32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glCopyTexSubImage3D`.
    copy_tex_sub_image_3d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, x: i32, y: i32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glCreateProgram`.
    create_program: *const fn () callconv(.c) u32 = undefined,

    /// Pointer to the native `glCreateShader`.
    create_shader: *const fn (kind: u32) callconv(.c) u32 = undefined,

    /// Pointer to the native `glCullFace`.
    cullFace: *const fn (mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteBuffers`.
    delete_buffers: *const fn (n: i32, buffers: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteFramebuffers`.
    delete_framebuffers: *const fn (n: i32, framebuffers: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteProgram`.
    delete_program: *const fn (program: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteQueries`.
    delete_queries: *const fn (n: i32, ids: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteRenderbuffers`.
    delete_renderbuffers: *const fn (n: i32, renderbuffers: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteSamplers`.
    delete_samplers: *const fn (count: i32, samplers: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteShader`.
    delete_shader: *const fn (shader: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteSync`.
    delete_sync: *const fn (sync: types.Sync) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteTextures`.
    delete_textures: *const fn (n: i32, textures: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteTransformFeedbacks`.
    delete_transform_feedbacks: *const fn (n: i32, ids: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDeleteVertexArrays`.
    delete_vertex_arrays: *const fn (n: i32, arrays: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDepthFunc`.
    depthFunc: *const fn (func: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDepthMask`.
    depthMask: *const fn (flag: u8) callconv(.c) void = undefined,

    /// Pointer to the native `glDepthRangef`.
    depth_rangef: *const fn (n: f32, f: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glDetachShader`.
    detach_shader: *const fn (program: u32, shader: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDisable`.
    disable: *const fn (cap: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDisableVertexAttribArray`.
    disable_vertex_attrib_array: *const fn (index: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawArrays`.
    drawArrays: *const fn (mode: u32, first: i32, count: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawArraysInstanced`.
    drawArraysInstanced: *const fn (mode: u32, first: i32, count: i32, instance_count: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawBuffers`.
    drawBuffers: *const fn (n: i32, bufs: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawElements`.
    drawElements: *const fn (mode: u32, count: i32, kind: u32, indices: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawElementsInstanced`.
    drawElementsInstanced: *const fn (mode: u32, count: i32, kind: u32, indices: ?*const anyopaque, instance_count: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glDrawRangeElements`.
    drawRangeElements: *const fn (mode: u32, start: u32, end: u32, count: i32, kind: u32, indices: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glEnable`.
    enable: *const fn (cap: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glEnableVertexAttribArray`.
    enable_vertex_attrib_array: *const fn (index: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glEndQuery`.
    end_query: *const fn (target: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glEndTransformFeedback`.
    end_transform_feedback: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glFenceSync`.
    fence_sync: *const fn (condition: u32, flags: u32) callconv(.c) types.Sync = undefined,

    /// Pointer to the native `glFinish`.
    finish: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glFlush`.
    flush: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glFlushMappedBufferRange`.
    flush_mapped_buffer_range: *const fn (target: u32, offset: isize, length: isize) callconv(.c) void = undefined,

    /// Pointer to the native `glFramebufferRenderbuffer`.
    framebuffer_renderbuffer: *const fn (target: u32, attachment: u32, renderbuffer_target: u32, renderbuffer: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glFramebufferTexture2D`.
    framebuffer_texture_2d: *const fn (target: u32, attachment: u32, textarget: u32, texture: u32, level: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glFramebufferTextureLayer`.
    framebuffer_texture_layer: *const fn (target: u32, attachment: u32, texture: u32, level: i32, layer: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glFrontFace`.
    frontFace: *const fn (mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenBuffers`.
    gen_buffers: *const fn (n: i32, buffers: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenFramebuffers`.
    gen_framebuffers: *const fn (n: i32, framebuffers: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenQueries`.
    gen_queries: *const fn (n: i32, ids: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenRenderbuffers`.
    gen_renderbuffers: *const fn (n: i32, renderbuffers: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenSamplers`.
    gen_samplers: *const fn (count: i32, samplers: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenTextures`.
    gen_textures: *const fn (n: i32, textures: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenTransformFeedbacks`.
    gen_transform_feedbacks: *const fn (n: i32, ids: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenVertexArrays`.
    gen_vertex_arrays: *const fn (n: i32, arrays: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGenerateMipmap`.
    generateMipmap: *const fn (target: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetActiveAttrib`.
    getActiveAttrib: *const fn (program: u32, index: u32, buf_size: i32, length: ?*i32, size: ?*i32, kind: ?*u32, name: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetActiveUniform`.
    getActiveUniform: *const fn (program: u32, index: u32, buf_size: i32, length: ?*i32, size: ?*i32, kind: ?*u32, name: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetActiveUniformBlockName`.
    getActiveUniformBlockName: *const fn (program: u32, uniform_block_index: u32, buf_size: i32, length: ?*i32, uniform_block_name: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetActiveUniformBlockiv`.
    get_active_uniform_block_iv: *const fn (program: u32, uniform_block_index: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetActiveUniformsiv`.
    get_active_uniforms_iv: *const fn (program: u32, uniform_count: i32, uniform_indices: [*]const u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetAttachedShaders`.
    getAttachedShaders: *const fn (program: u32, max_count: i32, count: ?*i32, shaders: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetAttribLocation`.
    getAttribLocation: *const fn (program: u32, name: [*:0]const u8) callconv(.c) i32 = undefined,

    /// Pointer to the native `glGetBooleanv`.
    get_boolean_v: *const fn (pname: u32, data: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetBufferParameteri64v`.
    get_buffer_parameter_i64_v: *const fn (target: u32, pname: u32, params: [*]i64) callconv(.c) void = undefined,

    /// Pointer to the native `glGetBufferParameteriv`.
    get_buffer_parameter_iv: *const fn (target: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetBufferPointerv`.
    get_buffer_pointer_v: *const fn (target: u32, pname: u32, params: ?*?*anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glGetError`.
    getError: *const fn () callconv(.c) u32 = undefined,

    /// Pointer to the native `glGetFloatv`.
    get_float_v: *const fn (pname: u32, data: [*]f32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetFragDataLocation`.
    getFragDataLocation: *const fn (program: u32, name: [*:0]const u8) callconv(.c) i32 = undefined,

    /// Pointer to the native `glGetFramebufferAttachmentParameteriv`.
    get_framebuffer_attachment_parameter_iv: *const fn (target: u32, attachment: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetInteger64i_v`.
    get_integer64_i_v: *const fn (target: u32, index: u32, data: [*]i64) callconv(.c) void = undefined,

    /// Pointer to the native `glGetInteger64v`.
    get_integer64_v: *const fn (pname: u32, data: [*]i64) callconv(.c) void = undefined,

    /// Pointer to the native `glGetIntegeri_v`.
    get_integer_i_v: *const fn (target: u32, index: u32, data: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetIntegerv`.
    get_integer_v: *const fn (pname: u32, data: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetInternalformativ`.
    get_internalformat_iv: *const fn (target: u32, internalformat: u32, pname: u32, count: i32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetProgramBinary`.
    get_program_binary: *const fn (program: u32, buf_size: i32, length: ?*i32, binary_format: ?*u32, binary: ?*anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glGetProgramInfoLog`.
    get_program_info_log: *const fn (program: u32, buf_size: i32, length: ?*i32, info_log: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetProgramiv`.
    get_program_iv: *const fn (program: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetQueryObjectuiv`.
    get_query_object_uiv: *const fn (id: u32, pname: u32, params: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetQueryiv`.
    get_query_iv: *const fn (target: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetRenderbufferParameteriv`.
    get_renderbuffer_parameter_iv: *const fn (target: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetSamplerParameterfv`.
    get_sampler_parameter_fv: *const fn (sampler: u32, pname: u32, params: [*]f32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetSamplerParameteriv`.
    get_sampler_parameter_iv: *const fn (sampler: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetShaderInfoLog`.
    get_shader_info_log: *const fn (shader: u32, buf_size: i32, length: ?*i32, info_log: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetShaderPrecisionFormat`.
    get_shader_precision_format: *const fn (shader_type: u32, precision_type: u32, range: [*]i32, precision: ?*i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetShaderSource`.
    get_shader_source: *const fn (shader: u32, buf_size: i32, length: ?*i32, source: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetShaderiv`.
    get_shader_iv: *const fn (shader: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetString`.
    getString: *const fn (name: u32) callconv(.c) ?[*:0]const u8 = undefined,

    /// Pointer to the native `glGetStringi`.
    getStringI: *const fn (name: u32, index: u32) callconv(.c) ?[*:0]const u8 = undefined,

    /// Pointer to the native `glGetSynciv`.
    get_sync_iv: *const fn (sync: types.Sync, pname: u32, count: i32, length: ?*i32, values: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetTexParameterfv`.
    get_tex_parameter_fv: *const fn (target: u32, pname: u32, params: [*]f32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetTexParameteriv`.
    get_tex_parameter_iv: *const fn (target: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetTransformFeedbackVarying`.
    get_transform_feedback_varying: *const fn (program: u32, index: u32, buf_size: i32, length: ?*i32, size: ?*i32, kind: ?*u32, name: [*]u8) callconv(.c) void = undefined,

    /// Pointer to the native `glGetUniformBlockIndex`.
    get_uniform_block_index: *const fn (program: u32, uniform_block_name: [*:0]const u8) callconv(.c) u32 = undefined,

    /// Pointer to the native `glGetUniformIndices`.
    get_uniform_indices: *const fn (program: u32, uniform_count: i32, uniform_names: [*]const [*:0]const u8, uniform_indices: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetUniformLocation`.
    get_uniform_location: *const fn (program: u32, name: [*:0]const u8) callconv(.c) i32 = undefined,

    /// Pointer to the native `glGetUniformfv`.
    get_uniform_fv: *const fn (program: u32, location: i32, params: [*]f32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetUniformiv`.
    get_uniform_iv: *const fn (program: u32, location: i32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetUniformuiv`.
    get_uniform_uiv: *const fn (program: u32, location: i32, params: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetVertexAttribIiv`.
    get_vertex_attrib_i_iv: *const fn (index: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetVertexAttribIuiv`.
    get_vertex_attrib_i_uiv: *const fn (index: u32, pname: u32, params: [*]u32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetVertexAttribPointerv`.
    get_vertex_attrib_pointer_v: *const fn (index: u32, pname: u32, pointer: ?*?*anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glGetVertexAttribfv`.
    get_vertex_attrib_fv: *const fn (index: u32, pname: u32, params: [*]f32) callconv(.c) void = undefined,

    /// Pointer to the native `glGetVertexAttribiv`.
    get_vertex_attrib_iv: *const fn (index: u32, pname: u32, params: [*]i32) callconv(.c) void = undefined,

    /// Pointer to the native `glHint`.
    hint: *const fn (target: u32, mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glInvalidateFramebuffer`.
    invalidate_framebuffer: *const fn (target: u32, num_attachments: i32, attachments: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glInvalidateSubFramebuffer`.
    invalidate_sub_framebuffer: *const fn (target: u32, num_attachments: i32, attachments: [*]const u32, x: i32, y: i32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glIsBuffer`.
    isBuffer: *const fn (buffer: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsEnabled`.
    isEnabled: *const fn (cap: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsFramebuffer`.
    isFramebuffer: *const fn (framebuffer: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsProgram`.
    isProgram: *const fn (program: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsQuery`.
    isQuery: *const fn (id: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsRenderbuffer`.
    isRenderbuffer: *const fn (renderbuffer: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsSampler`.
    isSampler: *const fn (sampler: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsShader`.
    isShader: *const fn (shader: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsSync`.
    isSync: *const fn (sync: types.Sync) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsTexture`.
    isTexture: *const fn (texture: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsTransformFeedback`.
    isTransformFeedback: *const fn (id: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glIsVertexArray`.
    isVertexArray: *const fn (array: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glLineWidth`.
    lineWidth: *const fn (width: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glLinkProgram`.
    link_program: *const fn (program: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glMapBufferRange`.
    map_buffer_range: *const fn (target: u32, offset: isize, length: isize, access: u32) callconv(.c) ?*anyopaque = undefined,

    /// Pointer to the native `glPauseTransformFeedback`.
    pause_transform_feedback: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glPixelStorei`.
    pixel_store_i: *const fn (pname: u32, param: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glPolygonOffset`.
    polygonOffset: *const fn (factor: f32, units: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glProgramBinary`.
    programBinary: *const fn (program: u32, binary_format: u32, binary: ?*const anyopaque, length: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glProgramParameteri`.
    programParameterI: *const fn (program: u32, pname: u32, value: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glReadBuffer`.
    readBuffer: *const fn (src: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glReadPixels`.
    readPixels: *const fn (x: i32, y: i32, width: i32, height: i32, format: u32, kind: u32, pixels: ?*anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glReleaseShaderCompiler`.
    release_shader_compiler: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glRenderbufferStorage`.
    renderbuffer_storage: *const fn (target: u32, internalformat: u32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glRenderbufferStorageMultisample`.
    renderbuffer_storage_multisample: *const fn (target: u32, samples: i32, internalformat: u32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glResumeTransformFeedback`.
    resume_transform_feedback: *const fn () callconv(.c) void = undefined,

    /// Pointer to the native `glSampleCoverage`.
    sampleCoverage: *const fn (value: f32, invert: u8) callconv(.c) void = undefined,

    /// Pointer to the native `glSamplerParameterf`.
    sampler_parameter_f: *const fn (sampler: u32, pname: u32, param: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glSamplerParameterfv`.
    sampler_parameter_fv: *const fn (sampler: u32, pname: u32, param: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glSamplerParameteri`.
    sampler_parameter_i: *const fn (sampler: u32, pname: u32, param: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glSamplerParameteriv`.
    sampler_parameter_iv: *const fn (sampler: u32, pname: u32, param: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glScissor`.
    scissor: *const fn (x: i32, y: i32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glShaderBinary`.
    shader_binary: *const fn (count: i32, shaders: [*]const u32, binary_format: u32, binary: ?*const anyopaque, length: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glShaderSource`.
    shader_source: *const fn (shader: u32, count: i32, string: [*]const [*:0]const u8, length: ?[*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilFunc`.
    stencilFunc: *const fn (func: u32, reference: i32, mask: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilFuncSeparate`.
    stencilFuncSeparate: *const fn (face: u32, func: u32, reference: i32, mask: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilMask`.
    stencilMask: *const fn (mask: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilMaskSeparate`.
    stencilMaskSeparate: *const fn (face: u32, mask: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilOp`.
    stencilOp: *const fn (fail: u32, z_fail: u32, z_pass: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glStencilOpSeparate`.
    stencilOpSeparate: *const fn (face: u32, sfail: u32, dpfail: u32, dppass: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexImage2D`.
    tex_image_2d: *const fn (target: u32, level: i32, internalformat: i32, width: i32, height: i32, border: i32, format: u32, kind: u32, pixels: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glTexImage3D`.
    tex_image_3d: *const fn (target: u32, level: i32, internalformat: i32, width: i32, height: i32, depth: i32, border: i32, format: u32, kind: u32, pixels: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glTexParameterf`.
    tex_parameter_f: *const fn (target: u32, pname: u32, param: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexParameterfv`.
    tex_parameter_fv: *const fn (target: u32, pname: u32, params: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexParameteri`.
    tex_parameter_i: *const fn (target: u32, pname: u32, param: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexParameteriv`.
    tex_parameter_iv: *const fn (target: u32, pname: u32, params: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexStorage2D`.
    tex_storage_2d: *const fn (target: u32, levels: i32, internalformat: u32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexStorage3D`.
    tex_storage_3d: *const fn (target: u32, levels: i32, internalformat: u32, width: i32, height: i32, depth: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glTexSubImage2D`.
    tex_sub_image_2d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, kind: u32, pixels: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glTexSubImage3D`.
    tex_sub_image_3d: *const fn (target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, kind: u32, pixels: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glTransformFeedbackVaryings`.
    transform_feedback_varyings: *const fn (program: u32, count: i32, varyings: [*]const [*:0]const u8, buffer_mode: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1f`.
    uniform1f: *const fn (location: i32, v0: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1fv`.
    uniform1fv: *const fn (location: i32, count: i32, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1i`.
    uniform1i: *const fn (location: i32, v0: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1iv`.
    uniform1iv: *const fn (location: i32, count: i32, value: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1ui`.
    uniform1ui: *const fn (location: i32, v0: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform1uiv`.
    uniform1uiv: *const fn (location: i32, count: i32, value: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2f`.
    uniform2f: *const fn (location: i32, v0: f32, v1: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2fv`.
    uniform2fv: *const fn (location: i32, count: i32, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2i`.
    uniform2i: *const fn (location: i32, v0: i32, v1: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2iv`.
    uniform2iv: *const fn (location: i32, count: i32, value: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2ui`.
    uniform2ui: *const fn (location: i32, v0: u32, v1: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform2uiv`.
    uniform2uiv: *const fn (location: i32, count: i32, value: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3f`.
    uniform3f: *const fn (location: i32, v0: f32, v1: f32, v2: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3fv`.
    uniform3fv: *const fn (location: i32, count: i32, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3i`.
    uniform3i: *const fn (location: i32, v0: i32, v1: i32, v2: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3iv`.
    uniform3iv: *const fn (location: i32, count: i32, value: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3ui`.
    uniform3ui: *const fn (location: i32, v0: u32, v1: u32, v2: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform3uiv`.
    uniform3uiv: *const fn (location: i32, count: i32, value: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4f`.
    uniform4f: *const fn (location: i32, v0: f32, v1: f32, v2: f32, v3: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4fv`.
    uniform4fv: *const fn (location: i32, count: i32, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4i`.
    uniform4i: *const fn (location: i32, v0: i32, v1: i32, v2: i32, v3: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4iv`.
    uniform4iv: *const fn (location: i32, count: i32, value: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4ui`.
    uniform4ui: *const fn (location: i32, v0: u32, v1: u32, v2: u32, v3: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniform4uiv`.
    uniform4uiv: *const fn (location: i32, count: i32, value: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformBlockBinding`.
    uniform_block_binding: *const fn (program: u32, uniform_block_index: u32, uniform_block_binding: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix2fv`.
    uniformMatrix2fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix2x3fv`.
    uniformMatrix2x3fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix2x4fv`.
    uniformMatrix2x4fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix3fv`.
    uniformMatrix3fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix3x2fv`.
    uniformMatrix3x2fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix3x4fv`.
    uniformMatrix3x4fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix4fv`.
    uniformMatrix4fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix4x2fv`.
    uniformMatrix4x2fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUniformMatrix4x3fv`.
    uniformMatrix4x3fv: *const fn (location: i32, count: i32, transpose: u8, value: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glUnmapBuffer`.
    unmap_buffer: *const fn (target: u32) callconv(.c) u8 = undefined,

    /// Pointer to the native `glUseProgram`.
    use_program: *const fn (program: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glValidateProgram`.
    validate_program: *const fn (program: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib1f`.
    vertexAttrib1f: *const fn (index: u32, x: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib1fv`.
    vertexAttrib1fv: *const fn (index: u32, v: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib2f`.
    vertexAttrib2f: *const fn (index: u32, x: f32, y: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib2fv`.
    vertexAttrib2fv: *const fn (index: u32, v: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib3f`.
    vertexAttrib3f: *const fn (index: u32, x: f32, y: f32, z: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib3fv`.
    vertexAttrib3fv: *const fn (index: u32, v: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib4f`.
    vertexAttrib4f: *const fn (index: u32, x: f32, y: f32, z: f32, w: f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttrib4fv`.
    vertexAttrib4fv: *const fn (index: u32, v: [*]const f32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribDivisor`.
    vertex_attrib_divisor: *const fn (index: u32, divisor: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribI4i`.
    vertexAttribI4i: *const fn (index: u32, x: i32, y: i32, z: i32, w: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribI4iv`.
    vertexAttribI4iv: *const fn (index: u32, v: [*]const i32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribI4ui`.
    vertexAttribI4ui: *const fn (index: u32, x: u32, y: u32, z: u32, w: u32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribI4uiv`.
    vertexAttribI4uiv: *const fn (index: u32, v: [*]const u32) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribIPointer`.
    vertex_attrib_i_pointer: *const fn (index: u32, size: i32, kind: u32, stride: i32, pointer: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glVertexAttribPointer`.
    vertex_attrib_pointer: *const fn (index: u32, size: i32, kind: u32, normalized: u8, stride: i32, pointer: ?*const anyopaque) callconv(.c) void = undefined,

    /// Pointer to the native `glViewport`.
    viewport: *const fn (x: i32, y: i32, width: i32, height: i32) callconv(.c) void = undefined,

    /// Pointer to the native `glWaitSync`.
    wait_sync: *const fn (sync: types.Sync, flags: u32, timeout: u64) callconv(.c) void = undefined,
};

/// Global OpenGL ES context instance.
///
/// Filled by [`load`](load) and used by all library namespaces
/// (`gl.buffers`, `gl.textures`, etc.).
pub var context: Context = .{};

/// `GL_VERSION` parameter code for `glGetString` (value from
/// [`state.StringName`](state.StringName)).
const gl_version_string: u32 = 0x1F02;

/// `GL_EXTENSIONS` parameter code for `glGetString`/`glGetStringi`.
const gl_extensions_string: u32 = 0x1F03;

/// `GL_NUM_EXTENSIONS` parameter code for `glGetIntegerv`.
const gl_num_extensions: u32 = 0x821D;

/// Loads the OpenGL ES context: determines the version via `glGetString` and
/// fetches the addresses of all functions of the reported version.
///
/// The loader function `load_fn` is called with the name of the requested
/// function (e.g. `"glBindBuffer"`) and must return its address or `null`.
/// Version detection replicates the `gladLoadGLES2` logic: the prefixes
/// `OpenGL ES-CM `, `OpenGL ES-CL `, `OpenGL ES ` and `OpenGL SC ` are
/// stripped from the `glGetString(GL_VERSION)` string, and then a `major.minor`
/// version number is parsed.
///
/// After a successful load the result (major/minor and the
/// [`es_2_0`](Context.es_2_0), [`es_3_0`](Context.es_3_0) flags) is available
/// in [`context`](context).
pub fn load(load_fn: types.LoadFn) LoadError!void {
    var ctx: Context = .{};

    // 1. First obtain glGetString — the version cannot be determined without it.
    ctx.getString = @ptrCast(load_fn("glGetString") orelse return error.GetStringUnavailable);

    // 2. Determine the context version.
    const version_ptr = ctx.getString(gl_version_string);
    if (version_ptr == null) return error.InvalidVersion;
    const major_minor = try parseVersion(version_ptr.?);
    ctx.major = major_minor.major;
    ctx.minor = major_minor.minor;

    // Exact replica of the glad logic: ES 2.0 is supported when major >= 2,
    // ES 3.0 when major >= 3.
    ctx.es_2_0 = ctx.major >= 2;
    ctx.es_3_0 = ctx.major >= 3;

    // 3. Load functions according to the version.
    if (ctx.es_2_0) try loadEs2(&ctx, load_fn);
    if (ctx.es_3_0) try loadEs3(&ctx, load_fn);

    context = ctx;
}

/// Checks whether the context supports the given extension (port of
/// `glad_gl_find_extensions_gles2`).
///
/// On ES 3.0 contexts the extension list is read through `glGetStringi` by
/// index (`GL_NUM_EXTENSIONS` entries); on ES 2.0 contexts — by searching the
/// `glGetString(GL_EXTENSIONS)` string with word-boundary checks.
///
/// ```
/// if (try gl.loader.hasExtension("GL_KHR_debug")) { ... }
/// ```
pub fn hasExtension(name: [:0]const u8) ExtensionError!bool {
    if (!loaded()) return error.NotLoaded;
    if (context.es_3_0) {
        var num_extensions: types.Int = 0;
        context.get_integer_v(gl_num_extensions, @ptrCast(&num_extensions));
        var index: types.UInt = 0;
        while (index < @as(types.UInt, @intCast(num_extensions))) : (index += 1) {
            const ext_ptr = context.getStringI(gl_extensions_string, index);
            if (ext_ptr == null) continue;
            if (std.mem.eql(u8, std.mem.sliceTo(ext_ptr.?, 0), name)) return true;
        }
        return false;
    }

    // ES 2.0: search for the name in the extension string with word-boundary checks.
    const exts_ptr = context.getString(gl_extensions_string);
    if (exts_ptr == null) return error.GetStringUnavailable;
    return tokenInString(std.mem.sliceTo(exts_ptr.?, 0), name);
}

/// Whether the context has been loaded.
pub fn loaded() bool {
    return context.major != 0 or context.minor != 0;
}

/// Searches for the word `needle` in a space-separated string with boundary
/// checks.
fn tokenInString(haystack: []const u8, needle: []const u8) bool {
    var offset: usize = 0;
    while (std.mem.findPosLinear(u8, haystack, offset, needle)) |pos| {
        const before_ok = pos == 0 or haystack[pos - 1] == ' ';
        const end = pos + needle.len;
        const after_ok = end == haystack.len or haystack[end] == ' ';
        if (before_ok and after_ok) return true;
        offset = end;
    }
    return false;
}

/// Result of parsing a version string.
const Version = struct {
    /// Major version number.
    major: u32 = 0,

    /// Minor version number.
    minor: u32 = 0,
};

/// Parses the version string returned by `glGetString(GL_VERSION)`.
///
/// The prefixes `OpenGL ES-CM `, `OpenGL ES-CL `, `OpenGL ES ` and `OpenGL SC `
/// are stripped; the remaining `major.minor` number is then parsed. Any other
/// prefix is rejected with [`error.InvalidVersion`](LoadError.InvalidVersion).
fn parseVersion(version: [*:0]const u8) LoadError!Version {
    const es_cm = "OpenGL ES-CM ";
    if (std.mem.startsWith(u8, std.mem.sliceTo(version, 0), es_cm)) {
        return parseVersionNumbers(std.mem.sliceTo(version, 0)[es_cm.len..]);
    }
    const es_cl = "OpenGL ES-CL ";
    if (std.mem.startsWith(u8, std.mem.sliceTo(version, 0), es_cl)) {
        return parseVersionNumbers(std.mem.sliceTo(version, 0)[es_cl.len..]);
    }
    const es = "OpenGL ES ";
    if (std.mem.startsWith(u8, std.mem.sliceTo(version, 0), es)) {
        return parseVersionNumbers(std.mem.sliceTo(version, 0)[es.len..]);
    }
    const sc = "OpenGL SC ";
    if (std.mem.startsWith(u8, std.mem.sliceTo(version, 0), sc)) {
        return parseVersionNumbers(std.mem.sliceTo(version, 0)[sc.len..]);
    }
    return error.InvalidVersion;
}

/// Parses a `major.minor` version number from the beginning of `s`.
fn parseVersionNumbers(s: []const u8) LoadError!Version {
    var ver: Version = .{};
    var pos: usize = 0;
    var major_done = false;
    var minor_done = false;

    while (pos < s.len) : (pos += 1) {
        const c = s[pos];
        if (c >= '0' and c <= '9') {
            if (!major_done) {
                ver.major = ver.major * 10 + (c - '0');
            } else {
                ver.minor = ver.minor * 10 + (c - '0');
            }
        } else if (c == '.' and !major_done) {
            major_done = true;
        } else if (c == '.' and !minor_done) {
            minor_done = true;
        } else {
            break; // stop at e.g. a space or other non-digit character
        }
    }
    if (ver.major == 0 and ver.minor == 0) return error.InvalidVersion;
    return ver;
}

/// Loads a single function pointer by name.
///
/// Requests the address of the native function `name` from `load_fn` and
/// reinterpret-casts it to the typed function pointer `T`. Fails with
/// [`error.MissingFunction`](LoadError.MissingFunction) if the loader returns
/// `null`.
fn loadProc(comptime T: type, load_fn: types.LoadFn, name: [:0]const u8) LoadError!T {
    const loaded_fn = load_fn(name) orelse return error.MissingFunction;
    return @ptrCast(loaded_fn);
}

/// Loads all OpenGL ES 2.0 functions into `ctx`.
fn loadEs2(ctx: *Context, load_fn: types.LoadFn) LoadError!void {
    ctx.activeTexture = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glActiveTexture");
    ctx.attach_shader = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glAttachShader");
    ctx.bindAttribLocation = try loadProc(*const fn (u32, u32, [*:0]const u8) callconv(.c) void, load_fn, "glBindAttribLocation");
    ctx.bind_buffer = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindBuffer");
    ctx.bind_framebuffer = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindFramebuffer");
    ctx.bind_renderbuffer = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindRenderbuffer");
    ctx.bind_texture = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindTexture");
    ctx.blendColor = try loadProc(*const fn (f32, f32, f32, f32) callconv(.c) void, load_fn, "glBlendColor");
    ctx.blendEquation = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glBlendEquation");
    ctx.blendEquationSeparate = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBlendEquationSeparate");
    ctx.blendFunc = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBlendFunc");
    ctx.blendFuncSeparate = try loadProc(*const fn (u32, u32, u32, u32) callconv(.c) void, load_fn, "glBlendFuncSeparate");
    ctx.bufferData = try loadProc(*const fn (u32, isize, ?*const anyopaque, u32) callconv(.c) void, load_fn, "glBufferData");
    ctx.bufferSubData = try loadProc(*const fn (u32, isize, isize, ?*const anyopaque) callconv(.c) void, load_fn, "glBufferSubData");
    ctx.check_framebuffer_status = try loadProc(*const fn (u32) callconv(.c) u32, load_fn, "glCheckFramebufferStatus");
    ctx.clear = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glClear");
    ctx.clearColor = try loadProc(*const fn (f32, f32, f32, f32) callconv(.c) void, load_fn, "glClearColor");
    ctx.clear_depthf = try loadProc(*const fn (f32) callconv(.c) void, load_fn, "glClearDepthf");
    ctx.clearStencil = try loadProc(*const fn (i32) callconv(.c) void, load_fn, "glClearStencil");
    ctx.color_mask = try loadProc(*const fn (u8, u8, u8, u8) callconv(.c) void, load_fn, "glColorMask");
    ctx.compile_shader = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glCompileShader");
    ctx.compressed_tex_image_2d = try loadProc(*const fn (u32, i32, u32, i32, i32, i32, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glCompressedTexImage2D");
    ctx.compressed_tex_sub_image_2d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glCompressedTexSubImage2D");
    ctx.copy_tex_image_2d = try loadProc(*const fn (u32, i32, u32, i32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glCopyTexImage2D");
    ctx.copy_tex_sub_image_2d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glCopyTexSubImage2D");
    ctx.create_program = try loadProc(*const fn () callconv(.c) u32, load_fn, "glCreateProgram");
    ctx.create_shader = try loadProc(*const fn (u32) callconv(.c) u32, load_fn, "glCreateShader");
    ctx.cullFace = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glCullFace");
    ctx.delete_buffers = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteBuffers");
    ctx.delete_framebuffers = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteFramebuffers");
    ctx.delete_program = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glDeleteProgram");
    ctx.delete_renderbuffers = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteRenderbuffers");
    ctx.delete_shader = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glDeleteShader");
    ctx.delete_textures = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteTextures");
    ctx.depthFunc = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glDepthFunc");
    ctx.depthMask = try loadProc(*const fn (u8) callconv(.c) void, load_fn, "glDepthMask");
    ctx.depth_rangef = try loadProc(*const fn (f32, f32) callconv(.c) void, load_fn, "glDepthRangef");
    ctx.detach_shader = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glDetachShader");
    ctx.disable = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glDisable");
    ctx.disable_vertex_attrib_array = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glDisableVertexAttribArray");
    ctx.drawArrays = try loadProc(*const fn (u32, i32, i32) callconv(.c) void, load_fn, "glDrawArrays");
    ctx.drawElements = try loadProc(*const fn (u32, i32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glDrawElements");
    ctx.enable = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glEnable");
    ctx.enable_vertex_attrib_array = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glEnableVertexAttribArray");
    ctx.finish = try loadProc(*const fn () callconv(.c) void, load_fn, "glFinish");
    ctx.flush = try loadProc(*const fn () callconv(.c) void, load_fn, "glFlush");
    ctx.framebuffer_renderbuffer = try loadProc(*const fn (u32, u32, u32, u32) callconv(.c) void, load_fn, "glFramebufferRenderbuffer");
    ctx.framebuffer_texture_2d = try loadProc(*const fn (u32, u32, u32, u32, i32) callconv(.c) void, load_fn, "glFramebufferTexture2D");
    ctx.frontFace = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glFrontFace");
    ctx.gen_buffers = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenBuffers");
    ctx.generateMipmap = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glGenerateMipmap");
    ctx.gen_framebuffers = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenFramebuffers");
    ctx.gen_renderbuffers = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenRenderbuffers");
    ctx.gen_textures = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenTextures");
    ctx.getActiveAttrib = try loadProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, load_fn, "glGetActiveAttrib");
    ctx.getActiveUniform = try loadProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, load_fn, "glGetActiveUniform");
    ctx.getAttachedShaders = try loadProc(*const fn (u32, i32, ?*i32, [*]u32) callconv(.c) void, load_fn, "glGetAttachedShaders");
    ctx.getAttribLocation = try loadProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, load_fn, "glGetAttribLocation");
    ctx.get_boolean_v = try loadProc(*const fn (u32, [*]u8) callconv(.c) void, load_fn, "glGetBooleanv");
    ctx.get_buffer_parameter_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetBufferParameteriv");
    ctx.getError = try loadProc(*const fn () callconv(.c) u32, load_fn, "glGetError");
    ctx.get_float_v = try loadProc(*const fn (u32, [*]f32) callconv(.c) void, load_fn, "glGetFloatv");
    ctx.get_framebuffer_attachment_parameter_iv = try loadProc(*const fn (u32, u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetFramebufferAttachmentParameteriv");
    ctx.get_integer_v = try loadProc(*const fn (u32, [*]i32) callconv(.c) void, load_fn, "glGetIntegerv");
    ctx.get_program_info_log = try loadProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, load_fn, "glGetProgramInfoLog");
    ctx.get_program_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetProgramiv");
    ctx.get_renderbuffer_parameter_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetRenderbufferParameteriv");
    ctx.renderbuffer_storage = try loadProc(*const fn (u32, u32, i32, i32) callconv(.c) void, load_fn, "glRenderbufferStorage");
    ctx.get_shader_info_log = try loadProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, load_fn, "glGetShaderInfoLog");
    ctx.get_shader_precision_format = try loadProc(*const fn (u32, u32, [*]i32, ?*i32) callconv(.c) void, load_fn, "glGetShaderPrecisionFormat");
    ctx.get_shader_source = try loadProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, load_fn, "glGetShaderSource");
    ctx.get_shader_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetShaderiv");
    ctx.getString = try loadProc(*const fn (u32) callconv(.c) ?[*:0]const u8, load_fn, "glGetString");
    ctx.get_tex_parameter_fv = try loadProc(*const fn (u32, u32, [*]f32) callconv(.c) void, load_fn, "glGetTexParameterfv");
    ctx.get_tex_parameter_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetTexParameteriv");
    ctx.get_uniform_fv = try loadProc(*const fn (u32, i32, [*]f32) callconv(.c) void, load_fn, "glGetUniformfv");
    ctx.get_uniform_iv = try loadProc(*const fn (u32, i32, [*]i32) callconv(.c) void, load_fn, "glGetUniformiv");
    ctx.get_uniform_location = try loadProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, load_fn, "glGetUniformLocation");
    ctx.get_vertex_attrib_fv = try loadProc(*const fn (u32, u32, [*]f32) callconv(.c) void, load_fn, "glGetVertexAttribfv");
    ctx.get_vertex_attrib_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetVertexAttribiv");
    ctx.get_vertex_attrib_pointer_v = try loadProc(*const fn (u32, u32, ?*?*anyopaque) callconv(.c) void, load_fn, "glGetVertexAttribPointerv");
    ctx.hint = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glHint");
    ctx.isBuffer = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsBuffer");
    ctx.isEnabled = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsEnabled");
    ctx.isFramebuffer = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsFramebuffer");
    ctx.isProgram = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsProgram");
    ctx.isRenderbuffer = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsRenderbuffer");
    ctx.isShader = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsShader");
    ctx.isTexture = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsTexture");
    ctx.lineWidth = try loadProc(*const fn (f32) callconv(.c) void, load_fn, "glLineWidth");
    ctx.link_program = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glLinkProgram");
    ctx.pixel_store_i = try loadProc(*const fn (u32, i32) callconv(.c) void, load_fn, "glPixelStorei");
    ctx.polygonOffset = try loadProc(*const fn (f32, f32) callconv(.c) void, load_fn, "glPolygonOffset");
    ctx.readPixels = try loadProc(*const fn (i32, i32, i32, i32, u32, u32, ?*anyopaque) callconv(.c) void, load_fn, "glReadPixels");
    ctx.release_shader_compiler = try loadProc(*const fn () callconv(.c) void, load_fn, "glReleaseShaderCompiler");
    ctx.sampleCoverage = try loadProc(*const fn (f32, u8) callconv(.c) void, load_fn, "glSampleCoverage");
    ctx.scissor = try loadProc(*const fn (i32, i32, i32, i32) callconv(.c) void, load_fn, "glScissor");
    ctx.shader_binary = try loadProc(*const fn (i32, [*]const u32, u32, ?*const anyopaque, i32) callconv(.c) void, load_fn, "glShaderBinary");
    ctx.shader_source = try loadProc(*const fn (u32, i32, [*]const [*:0]const u8, ?[*]const i32) callconv(.c) void, load_fn, "glShaderSource");
    ctx.stencilFunc = try loadProc(*const fn (u32, i32, u32) callconv(.c) void, load_fn, "glStencilFunc");
    ctx.stencilFuncSeparate = try loadProc(*const fn (u32, u32, i32, u32) callconv(.c) void, load_fn, "glStencilFuncSeparate");
    ctx.stencilMask = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glStencilMask");
    ctx.stencilMaskSeparate = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glStencilMaskSeparate");
    ctx.stencilOp = try loadProc(*const fn (u32, u32, u32) callconv(.c) void, load_fn, "glStencilOp");
    ctx.stencilOpSeparate = try loadProc(*const fn (u32, u32, u32, u32) callconv(.c) void, load_fn, "glStencilOpSeparate");
    ctx.tex_image_2d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glTexImage2D");
    ctx.tex_parameter_f = try loadProc(*const fn (u32, u32, f32) callconv(.c) void, load_fn, "glTexParameterf");
    ctx.tex_parameter_fv = try loadProc(*const fn (u32, u32, [*]const f32) callconv(.c) void, load_fn, "glTexParameterfv");
    ctx.tex_parameter_i = try loadProc(*const fn (u32, u32, i32) callconv(.c) void, load_fn, "glTexParameteri");
    ctx.tex_parameter_iv = try loadProc(*const fn (u32, u32, [*]const i32) callconv(.c) void, load_fn, "glTexParameteriv");
    ctx.tex_sub_image_2d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glTexSubImage2D");
    ctx.uniform1f = try loadProc(*const fn (i32, f32) callconv(.c) void, load_fn, "glUniform1f");
    ctx.uniform1fv = try loadProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, load_fn, "glUniform1fv");
    ctx.uniform1i = try loadProc(*const fn (i32, i32) callconv(.c) void, load_fn, "glUniform1i");
    ctx.uniform1iv = try loadProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, load_fn, "glUniform1iv");
    ctx.uniform2f = try loadProc(*const fn (i32, f32, f32) callconv(.c) void, load_fn, "glUniform2f");
    ctx.uniform2fv = try loadProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, load_fn, "glUniform2fv");
    ctx.uniform2i = try loadProc(*const fn (i32, i32, i32) callconv(.c) void, load_fn, "glUniform2i");
    ctx.uniform2iv = try loadProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, load_fn, "glUniform2iv");
    ctx.uniform3f = try loadProc(*const fn (i32, f32, f32, f32) callconv(.c) void, load_fn, "glUniform3f");
    ctx.uniform3fv = try loadProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, load_fn, "glUniform3fv");
    ctx.uniform3i = try loadProc(*const fn (i32, i32, i32, i32) callconv(.c) void, load_fn, "glUniform3i");
    ctx.uniform3iv = try loadProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, load_fn, "glUniform3iv");
    ctx.uniform4f = try loadProc(*const fn (i32, f32, f32, f32, f32) callconv(.c) void, load_fn, "glUniform4f");
    ctx.uniform4fv = try loadProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, load_fn, "glUniform4fv");
    ctx.uniform4i = try loadProc(*const fn (i32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glUniform4i");
    ctx.uniform4iv = try loadProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, load_fn, "glUniform4iv");
    ctx.uniformMatrix2fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix2fv");
    ctx.uniformMatrix3fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix3fv");
    ctx.uniformMatrix4fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix4fv");
    ctx.use_program = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glUseProgram");
    ctx.validate_program = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glValidateProgram");
    ctx.vertexAttrib1f = try loadProc(*const fn (u32, f32) callconv(.c) void, load_fn, "glVertexAttrib1f");
    ctx.vertexAttrib1fv = try loadProc(*const fn (u32, [*]const f32) callconv(.c) void, load_fn, "glVertexAttrib1fv");
    ctx.vertexAttrib2f = try loadProc(*const fn (u32, f32, f32) callconv(.c) void, load_fn, "glVertexAttrib2f");
    ctx.vertexAttrib2fv = try loadProc(*const fn (u32, [*]const f32) callconv(.c) void, load_fn, "glVertexAttrib2fv");
    ctx.vertexAttrib3f = try loadProc(*const fn (u32, f32, f32, f32) callconv(.c) void, load_fn, "glVertexAttrib3f");
    ctx.vertexAttrib3fv = try loadProc(*const fn (u32, [*]const f32) callconv(.c) void, load_fn, "glVertexAttrib3fv");
    ctx.vertexAttrib4f = try loadProc(*const fn (u32, f32, f32, f32, f32) callconv(.c) void, load_fn, "glVertexAttrib4f");
    ctx.vertexAttrib4fv = try loadProc(*const fn (u32, [*]const f32) callconv(.c) void, load_fn, "glVertexAttrib4fv");
    ctx.vertex_attrib_pointer = try loadProc(*const fn (u32, i32, u32, u8, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glVertexAttribPointer");
    ctx.viewport = try loadProc(*const fn (i32, i32, i32, i32) callconv(.c) void, load_fn, "glViewport");
}

/// Loads all OpenGL ES 3.0 functions into `ctx`.
fn loadEs3(ctx: *Context, load_fn: types.LoadFn) LoadError!void {
    ctx.begin_query = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBeginQuery");
    ctx.begin_transform_feedback = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glBeginTransformFeedback");
    ctx.bind_buffer_base = try loadProc(*const fn (u32, u32, u32) callconv(.c) void, load_fn, "glBindBufferBase");
    ctx.bind_buffer_range = try loadProc(*const fn (u32, u32, u32, isize, isize) callconv(.c) void, load_fn, "glBindBufferRange");
    ctx.bind_sampler = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindSampler");
    ctx.bind_transform_feedback = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glBindTransformFeedback");
    ctx.bind_vertex_array = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glBindVertexArray");
    ctx.blit_framebuffer = try loadProc(*const fn (i32, i32, i32, i32, i32, i32, i32, i32, u32, u32) callconv(.c) void, load_fn, "glBlitFramebuffer");
    ctx.clearBufferFi = try loadProc(*const fn (u32, i32, f32, i32) callconv(.c) void, load_fn, "glClearBufferfi");
    ctx.clearBufferFv = try loadProc(*const fn (u32, i32, [*]const f32) callconv(.c) void, load_fn, "glClearBufferfv");
    ctx.clearBufferIv = try loadProc(*const fn (u32, i32, [*]const i32) callconv(.c) void, load_fn, "glClearBufferiv");
    ctx.clearBufferUiv = try loadProc(*const fn (u32, i32, [*]const u32) callconv(.c) void, load_fn, "glClearBufferuiv");
    ctx.client_wait_sync = try loadProc(*const fn (types.Sync, u32, u64) callconv(.c) u32, load_fn, "glClientWaitSync");
    ctx.compressed_tex_image_3d = try loadProc(*const fn (u32, i32, u32, i32, i32, i32, i32, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glCompressedTexImage3D");
    ctx.compressed_tex_sub_image_3d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glCompressedTexSubImage3D");
    ctx.copy_buffer_sub_data = try loadProc(*const fn (u32, u32, isize, isize, isize) callconv(.c) void, load_fn, "glCopyBufferSubData");
    ctx.copy_tex_sub_image_3d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glCopyTexSubImage3D");
    ctx.delete_queries = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteQueries");
    ctx.delete_samplers = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteSamplers");
    ctx.delete_sync = try loadProc(*const fn (types.Sync) callconv(.c) void, load_fn, "glDeleteSync");
    ctx.delete_transform_feedbacks = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteTransformFeedbacks");
    ctx.delete_vertex_arrays = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDeleteVertexArrays");
    ctx.drawArraysInstanced = try loadProc(*const fn (u32, i32, i32, i32) callconv(.c) void, load_fn, "glDrawArraysInstanced");
    ctx.drawBuffers = try loadProc(*const fn (i32, [*]const u32) callconv(.c) void, load_fn, "glDrawBuffers");
    ctx.drawElementsInstanced = try loadProc(*const fn (u32, i32, u32, ?*const anyopaque, i32) callconv(.c) void, load_fn, "glDrawElementsInstanced");
    ctx.drawRangeElements = try loadProc(*const fn (u32, u32, u32, i32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glDrawRangeElements");
    ctx.end_query = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glEndQuery");
    ctx.end_transform_feedback = try loadProc(*const fn () callconv(.c) void, load_fn, "glEndTransformFeedback");
    ctx.fence_sync = try loadProc(*const fn (u32, u32) callconv(.c) types.Sync, load_fn, "glFenceSync");
    ctx.flush_mapped_buffer_range = try loadProc(*const fn (u32, isize, isize) callconv(.c) void, load_fn, "glFlushMappedBufferRange");
    ctx.framebuffer_texture_layer = try loadProc(*const fn (u32, u32, u32, i32, i32) callconv(.c) void, load_fn, "glFramebufferTextureLayer");
    ctx.gen_queries = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenQueries");
    ctx.gen_samplers = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenSamplers");
    ctx.gen_transform_feedbacks = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenTransformFeedbacks");
    ctx.gen_vertex_arrays = try loadProc(*const fn (i32, [*]u32) callconv(.c) void, load_fn, "glGenVertexArrays");
    ctx.getActiveUniformBlockName = try loadProc(*const fn (u32, u32, i32, ?*i32, [*]u8) callconv(.c) void, load_fn, "glGetActiveUniformBlockName");
    ctx.get_active_uniform_block_iv = try loadProc(*const fn (u32, u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetActiveUniformBlockiv");
    ctx.get_active_uniforms_iv = try loadProc(*const fn (u32, i32, [*]const u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetActiveUniformsiv");
    ctx.get_buffer_parameter_i64_v = try loadProc(*const fn (u32, u32, [*]i64) callconv(.c) void, load_fn, "glGetBufferParameteri64v");
    ctx.get_buffer_pointer_v = try loadProc(*const fn (u32, u32, ?*?*anyopaque) callconv(.c) void, load_fn, "glGetBufferPointerv");
    ctx.getFragDataLocation = try loadProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, load_fn, "glGetFragDataLocation");
    ctx.get_integer64_i_v = try loadProc(*const fn (u32, u32, [*]i64) callconv(.c) void, load_fn, "glGetInteger64i_v");
    ctx.get_integer64_v = try loadProc(*const fn (u32, [*]i64) callconv(.c) void, load_fn, "glGetInteger64v");
    ctx.get_integer_i_v = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetIntegeri_v");
    ctx.get_internalformat_iv = try loadProc(*const fn (u32, u32, u32, i32, [*]i32) callconv(.c) void, load_fn, "glGetInternalformativ");
    ctx.get_program_binary = try loadProc(*const fn (u32, i32, ?*i32, ?*u32, ?*anyopaque) callconv(.c) void, load_fn, "glGetProgramBinary");
    ctx.get_query_object_uiv = try loadProc(*const fn (u32, u32, [*]u32) callconv(.c) void, load_fn, "glGetQueryObjectuiv");
    ctx.get_query_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetQueryiv");
    ctx.get_sampler_parameter_fv = try loadProc(*const fn (u32, u32, [*]f32) callconv(.c) void, load_fn, "glGetSamplerParameterfv");
    ctx.get_sampler_parameter_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetSamplerParameteriv");
    ctx.getStringI = try loadProc(*const fn (u32, u32) callconv(.c) ?[*:0]const u8, load_fn, "glGetStringi");
    ctx.get_sync_iv = try loadProc(*const fn (types.Sync, u32, i32, ?*i32, [*]i32) callconv(.c) void, load_fn, "glGetSynciv");
    ctx.get_transform_feedback_varying = try loadProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, load_fn, "glGetTransformFeedbackVarying");
    ctx.get_uniform_block_index = try loadProc(*const fn (u32, [*:0]const u8) callconv(.c) u32, load_fn, "glGetUniformBlockIndex");
    ctx.get_uniform_indices = try loadProc(*const fn (u32, i32, [*]const [*:0]const u8, [*]u32) callconv(.c) void, load_fn, "glGetUniformIndices");
    ctx.get_uniform_uiv = try loadProc(*const fn (u32, i32, [*]u32) callconv(.c) void, load_fn, "glGetUniformuiv");
    ctx.get_vertex_attrib_i_iv = try loadProc(*const fn (u32, u32, [*]i32) callconv(.c) void, load_fn, "glGetVertexAttribIiv");
    ctx.get_vertex_attrib_i_uiv = try loadProc(*const fn (u32, u32, [*]u32) callconv(.c) void, load_fn, "glGetVertexAttribIuiv");
    ctx.invalidate_framebuffer = try loadProc(*const fn (u32, i32, [*]const u32) callconv(.c) void, load_fn, "glInvalidateFramebuffer");
    ctx.invalidate_sub_framebuffer = try loadProc(*const fn (u32, i32, [*]const u32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glInvalidateSubFramebuffer");
    ctx.isQuery = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsQuery");
    ctx.isSampler = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsSampler");
    ctx.isSync = try loadProc(*const fn (types.Sync) callconv(.c) u8, load_fn, "glIsSync");
    ctx.isTransformFeedback = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsTransformFeedback");
    ctx.isVertexArray = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glIsVertexArray");
    ctx.map_buffer_range = try loadProc(*const fn (u32, isize, isize, u32) callconv(.c) ?*anyopaque, load_fn, "glMapBufferRange");
    ctx.pause_transform_feedback = try loadProc(*const fn () callconv(.c) void, load_fn, "glPauseTransformFeedback");
    ctx.programBinary = try loadProc(*const fn (u32, u32, ?*const anyopaque, i32) callconv(.c) void, load_fn, "glProgramBinary");
    ctx.programParameterI = try loadProc(*const fn (u32, u32, i32) callconv(.c) void, load_fn, "glProgramParameteri");
    ctx.readBuffer = try loadProc(*const fn (u32) callconv(.c) void, load_fn, "glReadBuffer");
    ctx.renderbuffer_storage_multisample = try loadProc(*const fn (u32, i32, u32, i32, i32) callconv(.c) void, load_fn, "glRenderbufferStorageMultisample");
    ctx.resume_transform_feedback = try loadProc(*const fn () callconv(.c) void, load_fn, "glResumeTransformFeedback");
    ctx.sampler_parameter_f = try loadProc(*const fn (u32, u32, f32) callconv(.c) void, load_fn, "glSamplerParameterf");
    ctx.sampler_parameter_fv = try loadProc(*const fn (u32, u32, [*]const f32) callconv(.c) void, load_fn, "glSamplerParameterfv");
    ctx.sampler_parameter_i = try loadProc(*const fn (u32, u32, i32) callconv(.c) void, load_fn, "glSamplerParameteri");
    ctx.sampler_parameter_iv = try loadProc(*const fn (u32, u32, [*]const i32) callconv(.c) void, load_fn, "glSamplerParameteriv");
    ctx.tex_image_3d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glTexImage3D");
    ctx.tex_storage_2d = try loadProc(*const fn (u32, i32, u32, i32, i32) callconv(.c) void, load_fn, "glTexStorage2D");
    ctx.tex_storage_3d = try loadProc(*const fn (u32, i32, u32, i32, i32, i32) callconv(.c) void, load_fn, "glTexStorage3D");
    ctx.tex_sub_image_3d = try loadProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, load_fn, "glTexSubImage3D");
    ctx.transform_feedback_varyings = try loadProc(*const fn (u32, i32, [*]const [*:0]const u8, u32) callconv(.c) void, load_fn, "glTransformFeedbackVaryings");
    ctx.uniform1ui = try loadProc(*const fn (i32, u32) callconv(.c) void, load_fn, "glUniform1ui");
    ctx.uniform1uiv = try loadProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, load_fn, "glUniform1uiv");
    ctx.uniform2ui = try loadProc(*const fn (i32, u32, u32) callconv(.c) void, load_fn, "glUniform2ui");
    ctx.uniform2uiv = try loadProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, load_fn, "glUniform2uiv");
    ctx.uniform3ui = try loadProc(*const fn (i32, u32, u32, u32) callconv(.c) void, load_fn, "glUniform3ui");
    ctx.uniform3uiv = try loadProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, load_fn, "glUniform3uiv");
    ctx.uniform4ui = try loadProc(*const fn (i32, u32, u32, u32, u32) callconv(.c) void, load_fn, "glUniform4ui");
    ctx.uniform4uiv = try loadProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, load_fn, "glUniform4uiv");
    ctx.uniform_block_binding = try loadProc(*const fn (u32, u32, u32) callconv(.c) void, load_fn, "glUniformBlockBinding");
    ctx.uniformMatrix2x3fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix2x3fv");
    ctx.uniformMatrix2x4fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix2x4fv");
    ctx.uniformMatrix3x2fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix3x2fv");
    ctx.uniformMatrix3x4fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix3x4fv");
    ctx.uniformMatrix4x2fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix4x2fv");
    ctx.uniformMatrix4x3fv = try loadProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, load_fn, "glUniformMatrix4x3fv");
    ctx.unmap_buffer = try loadProc(*const fn (u32) callconv(.c) u8, load_fn, "glUnmapBuffer");
    ctx.vertex_attrib_divisor = try loadProc(*const fn (u32, u32) callconv(.c) void, load_fn, "glVertexAttribDivisor");
    ctx.vertexAttribI4i = try loadProc(*const fn (u32, i32, i32, i32, i32) callconv(.c) void, load_fn, "glVertexAttribI4i");
    ctx.vertexAttribI4iv = try loadProc(*const fn (u32, [*]const i32) callconv(.c) void, load_fn, "glVertexAttribI4iv");
    ctx.vertexAttribI4ui = try loadProc(*const fn (u32, u32, u32, u32, u32) callconv(.c) void, load_fn, "glVertexAttribI4ui");
    ctx.vertexAttribI4uiv = try loadProc(*const fn (u32, [*]const u32) callconv(.c) void, load_fn, "glVertexAttribI4uiv");
    ctx.vertex_attrib_i_pointer = try loadProc(*const fn (u32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, load_fn, "glVertexAttribIPointer");
    ctx.wait_sync = try loadProc(*const fn (types.Sync, u32, u64) callconv(.c) void, load_fn, "glWaitSync");
}