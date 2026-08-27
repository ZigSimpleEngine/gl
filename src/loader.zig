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
const builtin = @import("builtin");
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

    /// Whether the context is a genuine OpenGL ES context. Desktop OpenGL
    /// contexts expose the same function set from version 3.0 upward (the
    /// full ES 3.0 entry points require desktop 4.2+), but expect desktop
    /// GLSL `#version 3x0` shaders instead of `#version 300 es`.
    is_es: bool = false,

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

    // 2. Determine the context version. Genuine ES contexts carry an
    //    "OpenGL ES" prefix; desktop OpenGL contexts start straight with
    //    the version number and are accepted as well.
    const version_ptr = ctx.getString(gl_version_string);
    if (version_ptr == null) return error.InvalidVersion;
    if (parseVersion(version_ptr.?)) |major_minor| {
        ctx.is_es = true;
        ctx.major = major_minor.major;
        ctx.minor = major_minor.minor;
    } else |_| {
        const major_minor = try parseDesktopVersion(version_ptr.?);
        ctx.major = major_minor.major;
        ctx.minor = major_minor.minor;
    }

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
    const slice = std.mem.sliceTo(version, 0);
    // WebGL version strings (used when GL_EMULATE_GLES_VERSION_STRING_FORMAT is off,
    // or on some browsers): "WebGL 1.0 ..." -> ES 2.0, "WebGL 2.0 ..." -> ES 3.0
    if (std.mem.startsWith(u8, slice, "WebGL ")) {
        const v = try parseVersionNumbers(slice["WebGL ".len..]);
        if (v.major == 1) return .{ .major = 2, .minor = 0 };
        if (v.major == 2) return .{ .major = 3, .minor = 0 };
        return v;
    }
    const es_cm = "OpenGL ES-CM ";
    if (std.mem.startsWith(u8, slice, es_cm)) {
        return parseVersionNumbers(slice[es_cm.len..]);
    }
    const es_cl = "OpenGL ES-CL ";
    if (std.mem.startsWith(u8, slice, es_cl)) {
        return parseVersionNumbers(slice[es_cl.len..]);
    }
    const es = "OpenGL ES ";
    if (std.mem.startsWith(u8, slice, es)) {
        return parseVersionNumbers(slice[es.len..]);
    }
    const sc = "OpenGL SC ";
    if (std.mem.startsWith(u8, slice, sc)) {
        return parseVersionNumbers(slice[sc.len..]);
    }
    return error.InvalidVersion;
}

/// Parses a desktop OpenGL version string: the leading `major.minor`
/// number, optionally followed by a release number and vendor info.
fn parseDesktopVersion(version: [*:0]const u8) LoadError!Version {
    return parseVersionNumbers(std.mem.sliceTo(version, 0));
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

/// Try to load a proc, returning null if unavailable (used for tolerant WebGL loading).
fn loadProcOpt(comptime T: type, load_fn: types.LoadFn, name: [:0]const u8) ?T {
    if (load_fn(name)) |ptr| return @ptrCast(ptr);
    return null;
}

/// Assigns `field` if proc is available; on emscripten missing procs are tolerated
/// (left as undefined — callers must not call unavailable entry points), on native
/// a missing proc is an error.
fn assignProc(comptime T: type, field: *T, load_fn: types.LoadFn, name: [:0]const u8) LoadError!void {
    if (loadProcOpt(T, load_fn, name)) |proc| {
        field.* = proc;
    } else if (builtin.target.os.tag != .emscripten) {
        return error.MissingFunction;
    }
    // on emscripten: tolerate missing — leave field undefined
}

/// Loads all OpenGL ES 2.0 functions into `ctx`.
fn loadEs2(ctx: *Context, load_fn: types.LoadFn) LoadError!void {
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.activeTexture, load_fn, "glActiveTexture");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.attach_shader, load_fn, "glAttachShader");
    try assignProc(*const fn (u32, u32, [*:0]const u8) callconv(.c) void, &ctx.bindAttribLocation, load_fn, "glBindAttribLocation");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_buffer, load_fn, "glBindBuffer");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_framebuffer, load_fn, "glBindFramebuffer");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_renderbuffer, load_fn, "glBindRenderbuffer");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_texture, load_fn, "glBindTexture");
    try assignProc(*const fn (f32, f32, f32, f32) callconv(.c) void, &ctx.blendColor, load_fn, "glBlendColor");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.blendEquation, load_fn, "glBlendEquation");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.blendEquationSeparate, load_fn, "glBlendEquationSeparate");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.blendFunc, load_fn, "glBlendFunc");
    try assignProc(*const fn (u32, u32, u32, u32) callconv(.c) void, &ctx.blendFuncSeparate, load_fn, "glBlendFuncSeparate");
    try assignProc(*const fn (u32, isize, ?*const anyopaque, u32) callconv(.c) void, &ctx.bufferData, load_fn, "glBufferData");
    try assignProc(*const fn (u32, isize, isize, ?*const anyopaque) callconv(.c) void, &ctx.bufferSubData, load_fn, "glBufferSubData");
    try assignProc(*const fn (u32) callconv(.c) u32, &ctx.check_framebuffer_status, load_fn, "glCheckFramebufferStatus");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.clear, load_fn, "glClear");
    try assignProc(*const fn (f32, f32, f32, f32) callconv(.c) void, &ctx.clearColor, load_fn, "glClearColor");
    try assignProc(*const fn (f32) callconv(.c) void, &ctx.clear_depthf, load_fn, "glClearDepthf");
    try assignProc(*const fn (i32) callconv(.c) void, &ctx.clearStencil, load_fn, "glClearStencil");
    try assignProc(*const fn (u8, u8, u8, u8) callconv(.c) void, &ctx.color_mask, load_fn, "glColorMask");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.compile_shader, load_fn, "glCompileShader");
    try assignProc(*const fn (u32, i32, u32, i32, i32, i32, i32, ?*const anyopaque) callconv(.c) void, &ctx.compressed_tex_image_2d, load_fn, "glCompressedTexImage2D");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, &ctx.compressed_tex_sub_image_2d, load_fn, "glCompressedTexSubImage2D");
    try assignProc(*const fn (u32, i32, u32, i32, i32, i32, i32, i32) callconv(.c) void, &ctx.copy_tex_image_2d, load_fn, "glCopyTexImage2D");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) void, &ctx.copy_tex_sub_image_2d, load_fn, "glCopyTexSubImage2D");
    try assignProc(*const fn () callconv(.c) u32, &ctx.create_program, load_fn, "glCreateProgram");
    try assignProc(*const fn (u32) callconv(.c) u32, &ctx.create_shader, load_fn, "glCreateShader");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.cullFace, load_fn, "glCullFace");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_buffers, load_fn, "glDeleteBuffers");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_framebuffers, load_fn, "glDeleteFramebuffers");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.delete_program, load_fn, "glDeleteProgram");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_renderbuffers, load_fn, "glDeleteRenderbuffers");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.delete_shader, load_fn, "glDeleteShader");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_textures, load_fn, "glDeleteTextures");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.depthFunc, load_fn, "glDepthFunc");
    try assignProc(*const fn (u8) callconv(.c) void, &ctx.depthMask, load_fn, "glDepthMask");
    try assignProc(*const fn (f32, f32) callconv(.c) void, &ctx.depth_rangef, load_fn, "glDepthRangef");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.detach_shader, load_fn, "glDetachShader");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.disable, load_fn, "glDisable");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.disable_vertex_attrib_array, load_fn, "glDisableVertexAttribArray");
    try assignProc(*const fn (u32, i32, i32) callconv(.c) void, &ctx.drawArrays, load_fn, "glDrawArrays");
    try assignProc(*const fn (u32, i32, u32, ?*const anyopaque) callconv(.c) void, &ctx.drawElements, load_fn, "glDrawElements");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.enable, load_fn, "glEnable");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.enable_vertex_attrib_array, load_fn, "glEnableVertexAttribArray");
    try assignProc(*const fn () callconv(.c) void, &ctx.finish, load_fn, "glFinish");
    try assignProc(*const fn () callconv(.c) void, &ctx.flush, load_fn, "glFlush");
    try assignProc(*const fn (u32, u32, u32, u32) callconv(.c) void, &ctx.framebuffer_renderbuffer, load_fn, "glFramebufferRenderbuffer");
    try assignProc(*const fn (u32, u32, u32, u32, i32) callconv(.c) void, &ctx.framebuffer_texture_2d, load_fn, "glFramebufferTexture2D");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.frontFace, load_fn, "glFrontFace");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_buffers, load_fn, "glGenBuffers");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.generateMipmap, load_fn, "glGenerateMipmap");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_framebuffers, load_fn, "glGenFramebuffers");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_renderbuffers, load_fn, "glGenRenderbuffers");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_textures, load_fn, "glGenTextures");
    try assignProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, &ctx.getActiveAttrib, load_fn, "glGetActiveAttrib");
    try assignProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, &ctx.getActiveUniform, load_fn, "glGetActiveUniform");
    try assignProc(*const fn (u32, i32, ?*i32, [*]u32) callconv(.c) void, &ctx.getAttachedShaders, load_fn, "glGetAttachedShaders");
    try assignProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, &ctx.getAttribLocation, load_fn, "glGetAttribLocation");
    try assignProc(*const fn (u32, [*]u8) callconv(.c) void, &ctx.get_boolean_v, load_fn, "glGetBooleanv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_buffer_parameter_iv, load_fn, "glGetBufferParameteriv");
    try assignProc(*const fn () callconv(.c) u32, &ctx.getError, load_fn, "glGetError");
    try assignProc(*const fn (u32, [*]f32) callconv(.c) void, &ctx.get_float_v, load_fn, "glGetFloatv");
    try assignProc(*const fn (u32, u32, u32, [*]i32) callconv(.c) void, &ctx.get_framebuffer_attachment_parameter_iv, load_fn, "glGetFramebufferAttachmentParameteriv");
    try assignProc(*const fn (u32, [*]i32) callconv(.c) void, &ctx.get_integer_v, load_fn, "glGetIntegerv");
    try assignProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, &ctx.get_program_info_log, load_fn, "glGetProgramInfoLog");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_program_iv, load_fn, "glGetProgramiv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_renderbuffer_parameter_iv, load_fn, "glGetRenderbufferParameteriv");
    try assignProc(*const fn (u32, u32, i32, i32) callconv(.c) void, &ctx.renderbuffer_storage, load_fn, "glRenderbufferStorage");
    try assignProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, &ctx.get_shader_info_log, load_fn, "glGetShaderInfoLog");
    try assignProc(*const fn (u32, u32, [*]i32, ?*i32) callconv(.c) void, &ctx.get_shader_precision_format, load_fn, "glGetShaderPrecisionFormat");
    try assignProc(*const fn (u32, i32, ?*i32, [*]u8) callconv(.c) void, &ctx.get_shader_source, load_fn, "glGetShaderSource");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_shader_iv, load_fn, "glGetShaderiv");
    try assignProc(*const fn (u32) callconv(.c) ?[*:0]const u8, &ctx.getString, load_fn, "glGetString");
    try assignProc(*const fn (u32, u32, [*]f32) callconv(.c) void, &ctx.get_tex_parameter_fv, load_fn, "glGetTexParameterfv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_tex_parameter_iv, load_fn, "glGetTexParameteriv");
    try assignProc(*const fn (u32, i32, [*]f32) callconv(.c) void, &ctx.get_uniform_fv, load_fn, "glGetUniformfv");
    try assignProc(*const fn (u32, i32, [*]i32) callconv(.c) void, &ctx.get_uniform_iv, load_fn, "glGetUniformiv");
    try assignProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, &ctx.get_uniform_location, load_fn, "glGetUniformLocation");
    try assignProc(*const fn (u32, u32, [*]f32) callconv(.c) void, &ctx.get_vertex_attrib_fv, load_fn, "glGetVertexAttribfv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_vertex_attrib_iv, load_fn, "glGetVertexAttribiv");
    try assignProc(*const fn (u32, u32, ?*?*anyopaque) callconv(.c) void, &ctx.get_vertex_attrib_pointer_v, load_fn, "glGetVertexAttribPointerv");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.hint, load_fn, "glHint");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isBuffer, load_fn, "glIsBuffer");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isEnabled, load_fn, "glIsEnabled");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isFramebuffer, load_fn, "glIsFramebuffer");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isProgram, load_fn, "glIsProgram");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isRenderbuffer, load_fn, "glIsRenderbuffer");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isShader, load_fn, "glIsShader");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isTexture, load_fn, "glIsTexture");
    try assignProc(*const fn (f32) callconv(.c) void, &ctx.lineWidth, load_fn, "glLineWidth");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.link_program, load_fn, "glLinkProgram");
    try assignProc(*const fn (u32, i32) callconv(.c) void, &ctx.pixel_store_i, load_fn, "glPixelStorei");
    try assignProc(*const fn (f32, f32) callconv(.c) void, &ctx.polygonOffset, load_fn, "glPolygonOffset");
    try assignProc(*const fn (i32, i32, i32, i32, u32, u32, ?*anyopaque) callconv(.c) void, &ctx.readPixels, load_fn, "glReadPixels");
    try assignProc(*const fn () callconv(.c) void, &ctx.release_shader_compiler, load_fn, "glReleaseShaderCompiler");
    try assignProc(*const fn (f32, u8) callconv(.c) void, &ctx.sampleCoverage, load_fn, "glSampleCoverage");
    try assignProc(*const fn (i32, i32, i32, i32) callconv(.c) void, &ctx.scissor, load_fn, "glScissor");
    try assignProc(*const fn (i32, [*]const u32, u32, ?*const anyopaque, i32) callconv(.c) void, &ctx.shader_binary, load_fn, "glShaderBinary");
    try assignProc(*const fn (u32, i32, [*]const [*:0]const u8, ?[*]const i32) callconv(.c) void, &ctx.shader_source, load_fn, "glShaderSource");
    try assignProc(*const fn (u32, i32, u32) callconv(.c) void, &ctx.stencilFunc, load_fn, "glStencilFunc");
    try assignProc(*const fn (u32, u32, i32, u32) callconv(.c) void, &ctx.stencilFuncSeparate, load_fn, "glStencilFuncSeparate");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.stencilMask, load_fn, "glStencilMask");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.stencilMaskSeparate, load_fn, "glStencilMaskSeparate");
    try assignProc(*const fn (u32, u32, u32) callconv(.c) void, &ctx.stencilOp, load_fn, "glStencilOp");
    try assignProc(*const fn (u32, u32, u32, u32) callconv(.c) void, &ctx.stencilOpSeparate, load_fn, "glStencilOpSeparate");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, &ctx.tex_image_2d, load_fn, "glTexImage2D");
    try assignProc(*const fn (u32, u32, f32) callconv(.c) void, &ctx.tex_parameter_f, load_fn, "glTexParameterf");
    try assignProc(*const fn (u32, u32, [*]const f32) callconv(.c) void, &ctx.tex_parameter_fv, load_fn, "glTexParameterfv");
    try assignProc(*const fn (u32, u32, i32) callconv(.c) void, &ctx.tex_parameter_i, load_fn, "glTexParameteri");
    try assignProc(*const fn (u32, u32, [*]const i32) callconv(.c) void, &ctx.tex_parameter_iv, load_fn, "glTexParameteriv");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, &ctx.tex_sub_image_2d, load_fn, "glTexSubImage2D");
    try assignProc(*const fn (i32, f32) callconv(.c) void, &ctx.uniform1f, load_fn, "glUniform1f");
    try assignProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, &ctx.uniform1fv, load_fn, "glUniform1fv");
    try assignProc(*const fn (i32, i32) callconv(.c) void, &ctx.uniform1i, load_fn, "glUniform1i");
    try assignProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, &ctx.uniform1iv, load_fn, "glUniform1iv");
    try assignProc(*const fn (i32, f32, f32) callconv(.c) void, &ctx.uniform2f, load_fn, "glUniform2f");
    try assignProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, &ctx.uniform2fv, load_fn, "glUniform2fv");
    try assignProc(*const fn (i32, i32, i32) callconv(.c) void, &ctx.uniform2i, load_fn, "glUniform2i");
    try assignProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, &ctx.uniform2iv, load_fn, "glUniform2iv");
    try assignProc(*const fn (i32, f32, f32, f32) callconv(.c) void, &ctx.uniform3f, load_fn, "glUniform3f");
    try assignProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, &ctx.uniform3fv, load_fn, "glUniform3fv");
    try assignProc(*const fn (i32, i32, i32, i32) callconv(.c) void, &ctx.uniform3i, load_fn, "glUniform3i");
    try assignProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, &ctx.uniform3iv, load_fn, "glUniform3iv");
    try assignProc(*const fn (i32, f32, f32, f32, f32) callconv(.c) void, &ctx.uniform4f, load_fn, "glUniform4f");
    try assignProc(*const fn (i32, i32, [*]const f32) callconv(.c) void, &ctx.uniform4fv, load_fn, "glUniform4fv");
    try assignProc(*const fn (i32, i32, i32, i32, i32) callconv(.c) void, &ctx.uniform4i, load_fn, "glUniform4i");
    try assignProc(*const fn (i32, i32, [*]const i32) callconv(.c) void, &ctx.uniform4iv, load_fn, "glUniform4iv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix2fv, load_fn, "glUniformMatrix2fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix3fv, load_fn, "glUniformMatrix3fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix4fv, load_fn, "glUniformMatrix4fv");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.use_program, load_fn, "glUseProgram");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.validate_program, load_fn, "glValidateProgram");
    try assignProc(*const fn (u32, f32) callconv(.c) void, &ctx.vertexAttrib1f, load_fn, "glVertexAttrib1f");
    try assignProc(*const fn (u32, [*]const f32) callconv(.c) void, &ctx.vertexAttrib1fv, load_fn, "glVertexAttrib1fv");
    try assignProc(*const fn (u32, f32, f32) callconv(.c) void, &ctx.vertexAttrib2f, load_fn, "glVertexAttrib2f");
    try assignProc(*const fn (u32, [*]const f32) callconv(.c) void, &ctx.vertexAttrib2fv, load_fn, "glVertexAttrib2fv");
    try assignProc(*const fn (u32, f32, f32, f32) callconv(.c) void, &ctx.vertexAttrib3f, load_fn, "glVertexAttrib3f");
    try assignProc(*const fn (u32, [*]const f32) callconv(.c) void, &ctx.vertexAttrib3fv, load_fn, "glVertexAttrib3fv");
    try assignProc(*const fn (u32, f32, f32, f32, f32) callconv(.c) void, &ctx.vertexAttrib4f, load_fn, "glVertexAttrib4f");
    try assignProc(*const fn (u32, [*]const f32) callconv(.c) void, &ctx.vertexAttrib4fv, load_fn, "glVertexAttrib4fv");
    try assignProc(*const fn (u32, i32, u32, u8, i32, ?*const anyopaque) callconv(.c) void, &ctx.vertex_attrib_pointer, load_fn, "glVertexAttribPointer");
    try assignProc(*const fn (i32, i32, i32, i32) callconv(.c) void, &ctx.viewport, load_fn, "glViewport");
}

/// Loads all OpenGL ES 3.0 functions into `ctx`.
fn loadEs3(ctx: *Context, load_fn: types.LoadFn) LoadError!void {
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.begin_query, load_fn, "glBeginQuery");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.begin_transform_feedback, load_fn, "glBeginTransformFeedback");
    try assignProc(*const fn (u32, u32, u32) callconv(.c) void, &ctx.bind_buffer_base, load_fn, "glBindBufferBase");
    try assignProc(*const fn (u32, u32, u32, isize, isize) callconv(.c) void, &ctx.bind_buffer_range, load_fn, "glBindBufferRange");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_sampler, load_fn, "glBindSampler");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.bind_transform_feedback, load_fn, "glBindTransformFeedback");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.bind_vertex_array, load_fn, "glBindVertexArray");
    try assignProc(*const fn (i32, i32, i32, i32, i32, i32, i32, i32, u32, u32) callconv(.c) void, &ctx.blit_framebuffer, load_fn, "glBlitFramebuffer");
    try assignProc(*const fn (u32, i32, f32, i32) callconv(.c) void, &ctx.clearBufferFi, load_fn, "glClearBufferfi");
    try assignProc(*const fn (u32, i32, [*]const f32) callconv(.c) void, &ctx.clearBufferFv, load_fn, "glClearBufferfv");
    try assignProc(*const fn (u32, i32, [*]const i32) callconv(.c) void, &ctx.clearBufferIv, load_fn, "glClearBufferiv");
    try assignProc(*const fn (u32, i32, [*]const u32) callconv(.c) void, &ctx.clearBufferUiv, load_fn, "glClearBufferuiv");
    try assignProc(*const fn (types.Sync, u32, u64) callconv(.c) u32, &ctx.client_wait_sync, load_fn, "glClientWaitSync");
    try assignProc(*const fn (u32, i32, u32, i32, i32, i32, i32, i32, ?*const anyopaque) callconv(.c) void, &ctx.compressed_tex_image_3d, load_fn, "glCompressedTexImage3D");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, &ctx.compressed_tex_sub_image_3d, load_fn, "glCompressedTexSubImage3D");
    try assignProc(*const fn (u32, u32, isize, isize, isize) callconv(.c) void, &ctx.copy_buffer_sub_data, load_fn, "glCopyBufferSubData");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, i32) callconv(.c) void, &ctx.copy_tex_sub_image_3d, load_fn, "glCopyTexSubImage3D");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_queries, load_fn, "glDeleteQueries");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_samplers, load_fn, "glDeleteSamplers");
    try assignProc(*const fn (types.Sync) callconv(.c) void, &ctx.delete_sync, load_fn, "glDeleteSync");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_transform_feedbacks, load_fn, "glDeleteTransformFeedbacks");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.delete_vertex_arrays, load_fn, "glDeleteVertexArrays");
    try assignProc(*const fn (u32, i32, i32, i32) callconv(.c) void, &ctx.drawArraysInstanced, load_fn, "glDrawArraysInstanced");
    try assignProc(*const fn (i32, [*]const u32) callconv(.c) void, &ctx.drawBuffers, load_fn, "glDrawBuffers");
    try assignProc(*const fn (u32, i32, u32, ?*const anyopaque, i32) callconv(.c) void, &ctx.drawElementsInstanced, load_fn, "glDrawElementsInstanced");
    try assignProc(*const fn (u32, u32, u32, i32, u32, ?*const anyopaque) callconv(.c) void, &ctx.drawRangeElements, load_fn, "glDrawRangeElements");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.end_query, load_fn, "glEndQuery");
    try assignProc(*const fn () callconv(.c) void, &ctx.end_transform_feedback, load_fn, "glEndTransformFeedback");
    try assignProc(*const fn (u32, u32) callconv(.c) types.Sync, &ctx.fence_sync, load_fn, "glFenceSync");
    try assignProc(*const fn (u32, isize, isize) callconv(.c) void, &ctx.flush_mapped_buffer_range, load_fn, "glFlushMappedBufferRange");
    try assignProc(*const fn (u32, u32, u32, i32, i32) callconv(.c) void, &ctx.framebuffer_texture_layer, load_fn, "glFramebufferTextureLayer");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_queries, load_fn, "glGenQueries");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_samplers, load_fn, "glGenSamplers");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_transform_feedbacks, load_fn, "glGenTransformFeedbacks");
    try assignProc(*const fn (i32, [*]u32) callconv(.c) void, &ctx.gen_vertex_arrays, load_fn, "glGenVertexArrays");
    try assignProc(*const fn (u32, u32, i32, ?*i32, [*]u8) callconv(.c) void, &ctx.getActiveUniformBlockName, load_fn, "glGetActiveUniformBlockName");
    try assignProc(*const fn (u32, u32, u32, [*]i32) callconv(.c) void, &ctx.get_active_uniform_block_iv, load_fn, "glGetActiveUniformBlockiv");
    try assignProc(*const fn (u32, i32, [*]const u32, u32, [*]i32) callconv(.c) void, &ctx.get_active_uniforms_iv, load_fn, "glGetActiveUniformsiv");
    try assignProc(*const fn (u32, u32, [*]i64) callconv(.c) void, &ctx.get_buffer_parameter_i64_v, load_fn, "glGetBufferParameteri64v");
    try assignProc(*const fn (u32, u32, ?*?*anyopaque) callconv(.c) void, &ctx.get_buffer_pointer_v, load_fn, "glGetBufferPointerv");
    try assignProc(*const fn (u32, [*:0]const u8) callconv(.c) i32, &ctx.getFragDataLocation, load_fn, "glGetFragDataLocation");
    try assignProc(*const fn (u32, u32, [*]i64) callconv(.c) void, &ctx.get_integer64_i_v, load_fn, "glGetInteger64i_v");
    try assignProc(*const fn (u32, [*]i64) callconv(.c) void, &ctx.get_integer64_v, load_fn, "glGetInteger64v");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_integer_i_v, load_fn, "glGetIntegeri_v");
    try assignProc(*const fn (u32, u32, u32, i32, [*]i32) callconv(.c) void, &ctx.get_internalformat_iv, load_fn, "glGetInternalformativ");
    try assignProc(*const fn (u32, i32, ?*i32, ?*u32, ?*anyopaque) callconv(.c) void, &ctx.get_program_binary, load_fn, "glGetProgramBinary");
    try assignProc(*const fn (u32, u32, [*]u32) callconv(.c) void, &ctx.get_query_object_uiv, load_fn, "glGetQueryObjectuiv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_query_iv, load_fn, "glGetQueryiv");
    try assignProc(*const fn (u32, u32, [*]f32) callconv(.c) void, &ctx.get_sampler_parameter_fv, load_fn, "glGetSamplerParameterfv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_sampler_parameter_iv, load_fn, "glGetSamplerParameteriv");
    try assignProc(*const fn (u32, u32) callconv(.c) ?[*:0]const u8, &ctx.getStringI, load_fn, "glGetStringi");
    try assignProc(*const fn (types.Sync, u32, i32, ?*i32, [*]i32) callconv(.c) void, &ctx.get_sync_iv, load_fn, "glGetSynciv");
    try assignProc(*const fn (u32, u32, i32, ?*i32, ?*i32, ?*u32, [*]u8) callconv(.c) void, &ctx.get_transform_feedback_varying, load_fn, "glGetTransformFeedbackVarying");
    try assignProc(*const fn (u32, [*:0]const u8) callconv(.c) u32, &ctx.get_uniform_block_index, load_fn, "glGetUniformBlockIndex");
    try assignProc(*const fn (u32, i32, [*]const [*:0]const u8, [*]u32) callconv(.c) void, &ctx.get_uniform_indices, load_fn, "glGetUniformIndices");
    try assignProc(*const fn (u32, i32, [*]u32) callconv(.c) void, &ctx.get_uniform_uiv, load_fn, "glGetUniformuiv");
    try assignProc(*const fn (u32, u32, [*]i32) callconv(.c) void, &ctx.get_vertex_attrib_i_iv, load_fn, "glGetVertexAttribIiv");
    try assignProc(*const fn (u32, u32, [*]u32) callconv(.c) void, &ctx.get_vertex_attrib_i_uiv, load_fn, "glGetVertexAttribIuiv");
    try assignProc(*const fn (u32, i32, [*]const u32) callconv(.c) void, &ctx.invalidate_framebuffer, load_fn, "glInvalidateFramebuffer");
    try assignProc(*const fn (u32, i32, [*]const u32, i32, i32, i32, i32) callconv(.c) void, &ctx.invalidate_sub_framebuffer, load_fn, "glInvalidateSubFramebuffer");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isQuery, load_fn, "glIsQuery");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isSampler, load_fn, "glIsSampler");
    try assignProc(*const fn (types.Sync) callconv(.c) u8, &ctx.isSync, load_fn, "glIsSync");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isTransformFeedback, load_fn, "glIsTransformFeedback");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.isVertexArray, load_fn, "glIsVertexArray");
    try assignProc(*const fn (u32, isize, isize, u32) callconv(.c) ?*anyopaque, &ctx.map_buffer_range, load_fn, "glMapBufferRange");
    try assignProc(*const fn () callconv(.c) void, &ctx.pause_transform_feedback, load_fn, "glPauseTransformFeedback");
    try assignProc(*const fn (u32, u32, ?*const anyopaque, i32) callconv(.c) void, &ctx.programBinary, load_fn, "glProgramBinary");
    try assignProc(*const fn (u32, u32, i32) callconv(.c) void, &ctx.programParameterI, load_fn, "glProgramParameteri");
    try assignProc(*const fn (u32) callconv(.c) void, &ctx.readBuffer, load_fn, "glReadBuffer");
    try assignProc(*const fn (u32, i32, u32, i32, i32) callconv(.c) void, &ctx.renderbuffer_storage_multisample, load_fn, "glRenderbufferStorageMultisample");
    try assignProc(*const fn () callconv(.c) void, &ctx.resume_transform_feedback, load_fn, "glResumeTransformFeedback");
    try assignProc(*const fn (u32, u32, f32) callconv(.c) void, &ctx.sampler_parameter_f, load_fn, "glSamplerParameterf");
    try assignProc(*const fn (u32, u32, [*]const f32) callconv(.c) void, &ctx.sampler_parameter_fv, load_fn, "glSamplerParameterfv");
    try assignProc(*const fn (u32, u32, i32) callconv(.c) void, &ctx.sampler_parameter_i, load_fn, "glSamplerParameteri");
    try assignProc(*const fn (u32, u32, [*]const i32) callconv(.c) void, &ctx.sampler_parameter_iv, load_fn, "glSamplerParameteriv");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, &ctx.tex_image_3d, load_fn, "glTexImage3D");
    try assignProc(*const fn (u32, i32, u32, i32, i32) callconv(.c) void, &ctx.tex_storage_2d, load_fn, "glTexStorage2D");
    try assignProc(*const fn (u32, i32, u32, i32, i32, i32) callconv(.c) void, &ctx.tex_storage_3d, load_fn, "glTexStorage3D");
    try assignProc(*const fn (u32, i32, i32, i32, i32, i32, i32, i32, u32, u32, ?*const anyopaque) callconv(.c) void, &ctx.tex_sub_image_3d, load_fn, "glTexSubImage3D");
    try assignProc(*const fn (u32, i32, [*]const [*:0]const u8, u32) callconv(.c) void, &ctx.transform_feedback_varyings, load_fn, "glTransformFeedbackVaryings");
    try assignProc(*const fn (i32, u32) callconv(.c) void, &ctx.uniform1ui, load_fn, "glUniform1ui");
    try assignProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, &ctx.uniform1uiv, load_fn, "glUniform1uiv");
    try assignProc(*const fn (i32, u32, u32) callconv(.c) void, &ctx.uniform2ui, load_fn, "glUniform2ui");
    try assignProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, &ctx.uniform2uiv, load_fn, "glUniform2uiv");
    try assignProc(*const fn (i32, u32, u32, u32) callconv(.c) void, &ctx.uniform3ui, load_fn, "glUniform3ui");
    try assignProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, &ctx.uniform3uiv, load_fn, "glUniform3uiv");
    try assignProc(*const fn (i32, u32, u32, u32, u32) callconv(.c) void, &ctx.uniform4ui, load_fn, "glUniform4ui");
    try assignProc(*const fn (i32, i32, [*]const u32) callconv(.c) void, &ctx.uniform4uiv, load_fn, "glUniform4uiv");
    try assignProc(*const fn (u32, u32, u32) callconv(.c) void, &ctx.uniform_block_binding, load_fn, "glUniformBlockBinding");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix2x3fv, load_fn, "glUniformMatrix2x3fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix2x4fv, load_fn, "glUniformMatrix2x4fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix3x2fv, load_fn, "glUniformMatrix3x2fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix3x4fv, load_fn, "glUniformMatrix3x4fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix4x2fv, load_fn, "glUniformMatrix4x2fv");
    try assignProc(*const fn (i32, i32, u8, [*]const f32) callconv(.c) void, &ctx.uniformMatrix4x3fv, load_fn, "glUniformMatrix4x3fv");
    try assignProc(*const fn (u32) callconv(.c) u8, &ctx.unmap_buffer, load_fn, "glUnmapBuffer");
    try assignProc(*const fn (u32, u32) callconv(.c) void, &ctx.vertex_attrib_divisor, load_fn, "glVertexAttribDivisor");
    try assignProc(*const fn (u32, i32, i32, i32, i32) callconv(.c) void, &ctx.vertexAttribI4i, load_fn, "glVertexAttribI4i");
    try assignProc(*const fn (u32, [*]const i32) callconv(.c) void, &ctx.vertexAttribI4iv, load_fn, "glVertexAttribI4iv");
    try assignProc(*const fn (u32, u32, u32, u32, u32) callconv(.c) void, &ctx.vertexAttribI4ui, load_fn, "glVertexAttribI4ui");
    try assignProc(*const fn (u32, [*]const u32) callconv(.c) void, &ctx.vertexAttribI4uiv, load_fn, "glVertexAttribI4uiv");
    try assignProc(*const fn (u32, i32, u32, i32, ?*const anyopaque) callconv(.c) void, &ctx.vertex_attrib_i_pointer, load_fn, "glVertexAttribIPointer");
    try assignProc(*const fn (types.Sync, u32, u64) callconv(.c) void, &ctx.wait_sync, load_fn, "glWaitSync");
}
