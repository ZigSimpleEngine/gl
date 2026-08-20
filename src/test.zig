//! API surface tests: every public function of every namespace is called at
//! least once through a mocked context so that the full call syntax is
//! type-checked. No real OpenGL context is required.
//!
//! The context is stubbed with native functions that write deterministic
//! results (zero lengths/counts, `GL_NO_ERROR`, `GL_FRAMEBUFFER_COMPLETE`,
//! `GL_WAIT_FAILED`) so that the wrappers never observe invalid values.

const std = @import("std");
const gl = @import("gl");

/// Returns a valid version string so that `loader.load` parses an ES 3.0
/// context.
fn stringStub(...) callconv(.c) ?[*:0]const u8 {
    return "OpenGL ES 3.0";
}

/// Reports `GL_NO_ERROR`.
fn errorStub(...) callconv(.c) u32 {
    return 0;
}

/// Reports `GL_FRAMEBUFFER_COMPLETE`.
fn statusStub(...) callconv(.c) u32 {
    return 0x8CD5;
}

/// Reports `GL_WAIT_FAILED` for `glClientWaitSync`.
fn waitStub(...) callconv(.c) u32 {
    return 0x911D;
}

/// Writes a zero length for info-log-style queries.
fn lengthStub(program: u32, max_length: i32, length: ?*i32, data: [*]u8) callconv(.c) void {
    _ = program;
    _ = max_length;
    _ = data;
    if (length) |ptr| ptr.* = 0;
}

/// Writes a zero count for `glGetAttachedShaders`.
fn attachedStub(program: u32, max_count: i32, count: ?*i32, shaders: [*]u32) callconv(.c) void {
    _ = program;
    _ = max_count;
    _ = shaders;
    if (count) |ptr| ptr.* = 0;
}

/// Writes zeroed info for `glGetActiveAttrib`-style queries.
fn activeStub(program: u32, index: u32, max_length: i32, length: ?*i32, size: ?*i32, kind: ?*u32, name: [*]u8) callconv(.c) void {
    _ = program;
    _ = index;
    _ = max_length;
    _ = name;
    if (length) |ptr| ptr.* = 0;
    if (size) |ptr| ptr.* = 0;
    if (kind) |ptr| ptr.* = 0;
}

/// Writes a zero length and format for `glGetProgramBinary`.
fn binaryStub(program: u32, max_length: i32, length: ?*i32, format: ?*u32, data: [*]u8) callconv(.c) void {
    _ = program;
    _ = max_length;
    _ = data;
    if (length) |ptr| ptr.* = 0;
    if (format) |ptr| ptr.* = 0;
}

/// Writes a zero length for `glGetActiveUniformBlockName`.
fn blockNameStub(program: u32, index: u32, max_length: i32, length: ?*i32, name: [*]u8) callconv(.c) void {
    _ = program;
    _ = index;
    _ = max_length;
    _ = name;
    if (length) |ptr| ptr.* = 0;
}

/// Ignored for every other native entry point.
fn voidStub(...) callconv(.c) void {}

/// Resolves every requested function name to a matching stub above.
fn provider(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    const resolved = std.mem.sliceTo(name, 0);
    if (std.mem.eql(u8, resolved, "glGetString") or std.mem.eql(u8, resolved, "glGetStringi")) {
        return @ptrCast(&stringStub);
    }
    if (std.mem.eql(u8, resolved, "glGetError")) return @ptrCast(&errorStub);
    if (std.mem.eql(u8, resolved, "glCheckFramebufferStatus")) return @ptrCast(&statusStub);
    if (std.mem.eql(u8, resolved, "glClientWaitSync")) return @ptrCast(&waitStub);
    if (std.mem.eql(u8, resolved, "glGetProgramInfoLog") or
        std.mem.eql(u8, resolved, "glGetShaderInfoLog") or
        std.mem.eql(u8, resolved, "glGetShaderSource"))
    {
        return @ptrCast(&lengthStub);
    }
    if (std.mem.eql(u8, resolved, "glGetActiveUniformBlockName")) return @ptrCast(&blockNameStub);
    if (std.mem.eql(u8, resolved, "glGetAttachedShaders")) return @ptrCast(&attachedStub);
    if (std.mem.eql(u8, resolved, "glGetActiveAttrib") or
        std.mem.eql(u8, resolved, "glGetActiveUniform") or
        std.mem.eql(u8, resolved, "glGetTransformFeedbackVarying"))
    {
        return @ptrCast(&activeStub);
    }
    if (std.mem.eql(u8, resolved, "glGetProgramBinary")) return @ptrCast(&binaryStub);
    return @ptrCast(&voidStub);
}

var context_ready = false;

/// Loads the mocked context once; all tests share it.
fn ensureLoaded() void {
    if (context_ready) return;
    gl.loader.load(provider) catch unreachable;
    context_ready = true;
}

test "state, viewport, clear, blending, depth, stencil, rasterization, drawing" {
    ensureLoaded();

    _ = (gl.enums.BufferMask{ .color = true, .depth = true }).bits();
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());

    gl.state.enable(gl.state.Capability.blend);
    gl.state.disable(gl.state.Capability.depth_test);
    _ = gl.state.isEnabled(gl.state.Capability.dither);
    var b: [4]u8 = undefined;
    gl.state.getBoolean(gl.state.GetPName.color_writemask, &b);
    var iv: [4]i32 = undefined;
    gl.state.getInteger(gl.state.GetPName.max_texture_size, &iv);
    var i64v: [4]i64 = undefined;
    gl.state.getInteger64(gl.state.GetPName.max_server_wait_timeout, &i64v);
    gl.state.getIntegerI(0x0DE1, 0, &iv);
    gl.state.getInteger64I(0x0DE1, 0, &i64v);
    var fv: [4]f32 = undefined;
    gl.state.getFloat(gl.state.GetPName.color_clear_value, &fv);
    _ = gl.state.getString(gl.state.StringName.version);
    _ = gl.state.getStringI(gl.state.StringName.extensions, 0);
    gl.state.hint(gl.state.HintTarget.generateMipmap, gl.state.HintMode.nicest);
    gl.state.finish();
    gl.state.flush();

    gl.viewport.viewport(0, 0, 640, 480);

    gl.clear.clear(.{ .color = true });
    gl.clear.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear.clearDepth(1.0);
    gl.clear.clearStencil(0);
    gl.clear.clearBufferFv(gl.clear.Buffer.color, 0, &.{ 0.0, 0.0, 0.0, 0.0 });
    gl.clear.clearBufferIv(gl.clear.Buffer.color, 0, &.{ 0, 0, 0, 0 });
    gl.clear.clearBufferUiv(gl.clear.Buffer.color, 0, &.{ 0, 0, 0, 0 });
    gl.clear.clearBufferFi(gl.clear.Buffer.depth, 0, 1.0, 0);

    gl.blending.blendColor(0.5, 0.5, 0.5, 0.5);
    gl.blending.blendEquation(gl.blending.BlendEquation.func_add);
    gl.blending.blendEquationSeparate(gl.blending.BlendEquation.func_add, gl.blending.BlendEquation.func_subtract);
    gl.blending.blendFunc(gl.blending.BlendFactor.src_alpha, gl.blending.BlendFactor.one_minus_src_alpha);
    gl.blending.blendFuncSeparate(
        gl.blending.BlendFactor.src_alpha,
        gl.blending.BlendFactor.one_minus_src_alpha,
        gl.blending.BlendFactor.one,
        gl.blending.BlendFactor.one,
    );

    gl.depth.depthFunc(gl.enums.Comparison.lequal);
    gl.depth.depthMask(true);
    gl.depth.depthRange(0.0, 1.0);

    gl.stencil.stencilFunc(gl.enums.Comparison.always, 0, 0xFF);
    gl.stencil.stencilFuncSeparate(gl.enums.Face.front, gl.enums.Comparison.always, 0, 0xFF);
    gl.stencil.stencilMask(0xFF);
    gl.stencil.stencilMaskSeparate(gl.enums.Face.back, 0xFF);
    gl.stencil.stencilOp(gl.stencil.StencilOp.keep, gl.stencil.StencilOp.keep, gl.stencil.StencilOp.replace);
    gl.stencil.stencilOpSeparate(
        gl.enums.Face.front,
        gl.stencil.StencilOp.keep,
        gl.stencil.StencilOp.keep,
        gl.stencil.StencilOp.replace,
    );

    gl.rasterization.cullFace(gl.enums.Face.back);
    gl.rasterization.frontFace(gl.rasterization.FrontFaceDirection.ccw);
    gl.rasterization.lineWidth(1.0);
    gl.rasterization.polygonOffset(1.0, 1.0);
    gl.rasterization.sampleCoverage(0.5, false);
    gl.rasterization.scissor(0, 0, 640, 480);

    gl.drawing.drawArrays(gl.drawing.PrimitiveType.triangles, 0, 3);
    gl.drawing.drawArraysInstanced(gl.drawing.PrimitiveType.triangles, 0, 3, 2);
    gl.drawing.drawElements(gl.drawing.PrimitiveType.triangles, 3, gl.enums.DataType.unsigned_short, null);
    gl.drawing.drawElementsInstanced(gl.drawing.PrimitiveType.triangles, 3, gl.enums.DataType.unsigned_short, null, 2);
    gl.drawing.drawRangeElements(gl.drawing.PrimitiveType.triangles, 0, 3, 3, gl.enums.DataType.unsigned_short, null);
}

test "buffers, textures, samplers, pixels" {
    ensureLoaded();

    var buf_ids: [2]u32 = undefined;
    gl.buffers.gen(2, &buf_ids);
    gl.buffers.delete(2, &buf_ids);
    _ = gl.buffers.isBuffer(0);
    gl.buffers.bind(gl.buffers.BufferTarget.array_buffer, 0);
    gl.buffers.bindBase(gl.buffers.BufferTarget.uniform_buffer, 0, 0);
    gl.buffers.bindRange(gl.buffers.BufferTarget.uniform_buffer, 0, 0, 0, 64);
    gl.buffers.bufferData(gl.buffers.BufferTarget.array_buffer, 64, null, gl.buffers.BufferUsage.static_draw);
    gl.buffers.bufferDataSlice(gl.buffers.BufferTarget.array_buffer, "data", gl.buffers.BufferUsage.static_draw);
    gl.buffers.bufferSubData(gl.buffers.BufferTarget.array_buffer, 0, 4, "data");
    gl.buffers.bufferSubDataSlice(gl.buffers.BufferTarget.array_buffer, 0, "data");
    gl.buffers.copySubData(
        gl.buffers.BufferTarget.copy_read_buffer,
        gl.buffers.BufferTarget.copy_write_buffer,
        0,
        0,
        4,
    );
    var iv: [4]i32 = undefined;
    gl.buffers.getParameter(gl.buffers.BufferTarget.array_buffer, gl.buffers.BufferParameter.buffer_size, &iv);
    var i64v: [4]i64 = undefined;
    gl.buffers.getParameter64(gl.buffers.BufferTarget.array_buffer, gl.buffers.BufferParameter.buffer_size, &i64v);
    _ = gl.buffers.map(gl.buffers.BufferTarget.array_buffer, 0, 64, .{ .read = true, .write = true });
    _ = gl.buffers.unmap(gl.buffers.BufferTarget.array_buffer);
    gl.buffers.flushMappedRange(gl.buffers.BufferTarget.array_buffer, 0, 64);
    _ = (gl.buffers.MapAccess{ .read = true }).bits();

    var tex_ids: [2]u32 = undefined;
    gl.textures.gen(2, &tex_ids);
    gl.textures.delete(2, &tex_ids);
    _ = gl.textures.isTexture(0);
    gl.textures.activeTexture(gl.textures.TextureUnit.texture0);
    gl.textures.bind(gl.textures.TextureTarget.texture_2d, 0);
    gl.textures.generateMipmap(gl.textures.TextureTarget.texture_2d);
    gl.textures.image2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        gl.textures.InternalFormat.rgba8,
        4,
        4,
        0,
        gl.textures.PixelFormat.rgba,
        gl.enums.DataType.unsigned_byte,
        null,
    );
    gl.textures.image3d(
        gl.textures.TextureTarget.texture_3d,
        0,
        gl.textures.InternalFormat.rgba8,
        4,
        4,
        4,
        0,
        gl.textures.PixelFormat.rgba,
        gl.enums.DataType.unsigned_byte,
        null,
    );
    gl.textures.subImage2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        0,
        0,
        4,
        4,
        gl.textures.PixelFormat.rgba,
        gl.enums.DataType.unsigned_byte,
        null,
    );
    gl.textures.subImage3d(
        gl.textures.TextureTarget.texture_3d,
        0,
        0,
        0,
        0,
        4,
        4,
        4,
        gl.textures.PixelFormat.rgba,
        gl.enums.DataType.unsigned_byte,
        null,
    );
    gl.textures.storage2d(gl.textures.TextureTarget.texture_2d, 1, gl.textures.InternalFormat.rgba8, 4, 4);
    gl.textures.storage3d(gl.textures.TextureTarget.texture_3d, 1, gl.textures.InternalFormat.rgba8, 4, 4, 4);
    gl.textures.copyImage2d(gl.textures.TextureTarget.texture_2d, 0, gl.textures.InternalFormat.rgba8, 0, 0, 4, 4, 0);
    gl.textures.copySubImage2d(gl.textures.TextureTarget.texture_2d, 0, 0, 0, 0, 0, 4, 4);
    gl.textures.copySubImage3d(gl.textures.TextureTarget.texture_3d, 0, 0, 0, 0, 0, 0, 4, 4);
    gl.textures.compressedImage2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        4,
        4,
        0,
        8,
        null,
    );
    gl.textures.compressedImage3d(
        gl.textures.TextureTarget.texture_2d_array,
        0,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        4,
        4,
        4,
        0,
        8,
        null,
    );
    gl.textures.compressedSubImage2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        0,
        0,
        4,
        4,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        8,
        null,
    );
    gl.textures.compressedSubImage3d(
        gl.textures.TextureTarget.texture_2d_array,
        0,
        0,
        0,
        0,
        4,
        4,
        4,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        8,
        null,
    );
    gl.textures.parameterI(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_min_filter, 0);
    gl.textures.parameterF(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, 0.0);
    gl.textures.parameterIv(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_min_filter, &.{ 0, 0 });
    gl.textures.parameterFv(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, &.{ 0.0, 0.0 });
    gl.textures.getParameterI(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_min_filter, &iv);
    var fv: [4]f32 = undefined;
    gl.textures.getParameterF(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, &fv);

    var samp_ids: [2]u32 = undefined;
    gl.samplers.gen(2, &samp_ids);
    gl.samplers.delete(2, &samp_ids);
    _ = gl.samplers.isSampler(0);
    gl.samplers.bind(0, 0);
    gl.samplers.parameterI(0, gl.samplers.SamplerParameter.texture_min_filter, 0);
    gl.samplers.parameterF(0, gl.samplers.SamplerParameter.texture_max_lod, 0.0);
    gl.samplers.parameterIv(0, gl.samplers.SamplerParameter.texture_min_filter, &.{ 0, 0 });
    gl.samplers.parameterFv(0, gl.samplers.SamplerParameter.texture_max_lod, &.{ 0.0, 0.0 });
    gl.samplers.getParameterI(0, gl.samplers.SamplerParameter.texture_min_filter, &iv);
    gl.samplers.getParameterF(0, gl.samplers.SamplerParameter.texture_max_lod, &fv);

    gl.pixels.storeI(gl.pixels.PixelStoreParameter.pack_alignment, 4);
    gl.pixels.readBuffer(gl.pixels.ReadBuffer.color);
    var px: [16]u8 = undefined;
    gl.pixels.readPixels(0, 0, 4, 4, gl.textures.PixelFormat.rgba, gl.enums.DataType.unsigned_byte, &px);
}

test "framebuffers, renderbuffers" {
    ensureLoaded();

    var fbo_ids: [2]u32 = undefined;
    gl.framebuffers.gen(2, &fbo_ids);
    gl.framebuffers.delete(2, &fbo_ids);
    _ = gl.framebuffers.isFramebuffer(0);
    gl.framebuffers.bind(gl.framebuffers.FramebufferTarget.framebuffer, 0);
    _ = gl.framebuffers.checkStatus(gl.framebuffers.FramebufferTarget.framebuffer);
    gl.framebuffers.attachRenderbuffer(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        0,
    );
    gl.framebuffers.attachTexture2d(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        gl.textures.TextureTarget.texture_2d,
        0,
        0,
    );
    gl.framebuffers.attachTextureLayer(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        0,
        0,
        0,
    );
    var iv: [4]i32 = undefined;
    gl.framebuffers.getAttachmentParameter(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        gl.framebuffers.AttachmentParameter.framebuffer_attachment_object_name,
        &iv,
    );
    gl.framebuffers.blit(
        0,
        0,
        4,
        4,
        0,
        0,
        4,
        4,
        .{ .color = true, .depth = true },
        gl.framebuffers.BlitFilter.nearest,
    );
    gl.framebuffers.drawBuffers(&.{ gl.framebuffers.DrawBuffer.color_attachment0 });
    gl.framebuffers.invalidate(gl.framebuffers.FramebufferTarget.framebuffer, &.{ 0x00004000, 0x00000100 });
    gl.framebuffers.invalidateSub(gl.framebuffers.FramebufferTarget.framebuffer, &.{ 0x00004000 }, 0, 0, 4, 4);
}

test "renderbuffers" {
    ensureLoaded();

    var iv: [4]i32 = undefined;
    var rbo_ids: [2]u32 = undefined;
    gl.renderbuffers.gen(2, &rbo_ids);
    gl.renderbuffers.delete(2, &rbo_ids);
    _ = gl.renderbuffers.isRenderbuffer(0);
    gl.renderbuffers.bind(gl.renderbuffers.RenderbufferTarget.renderbuffer, 0);
    gl.renderbuffers.storage(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        gl.textures.InternalFormat.depth24_stencil8,
        4,
        4,
    );
    gl.renderbuffers.storageMultisample(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        4,
        gl.textures.InternalFormat.depth24_stencil8,
        4,
        4,
    );
    gl.renderbuffers.getParameter(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        gl.renderbuffers.RenderbufferParameter.renderbuffer_width,
        &iv,
    );
}

test "vertex attributes, vertex arrays" {
    ensureLoaded();

    var iv: [4]i32 = undefined;
    var buf_ids: [2]u32 = undefined;
    gl.vertex_attributes.enable(0);
    gl.vertex_attributes.disable(0);
    gl.vertex_attributes.pointer(0, 3, gl.enums.DataType.float, false, 12, null);
    gl.vertex_attributes.iPointer(0, 3, gl.enums.DataType.float, 12, null);
    gl.vertex_attributes.divisor(0, 1);
    gl.vertex_attributes.vertexAttrib1f(0, 1.0);
    gl.vertex_attributes.vertexAttrib2f(0, 1.0, 2.0);
    gl.vertex_attributes.vertexAttrib3f(0, 1.0, 2.0, 3.0);
    gl.vertex_attributes.vertexAttrib4f(0, 1.0, 2.0, 3.0, 4.0);
    gl.vertex_attributes.vertexAttrib1fv(0, &.{1.0});
    gl.vertex_attributes.vertexAttrib2fv(0, &.{ 1.0, 2.0 });
    gl.vertex_attributes.vertexAttrib3fv(0, &.{ 1.0, 2.0, 3.0 });
    gl.vertex_attributes.vertexAttrib4fv(0, &.{ 1.0, 2.0, 3.0, 4.0 });
    gl.vertex_attributes.vertexAttribI4i(0, 1, 2, 3, 4);
    gl.vertex_attributes.vertexAttribI4ui(0, 1, 2, 3, 4);
    gl.vertex_attributes.vertexAttribI4iv(0, &.{ 1, 2, 3, 4 });
    gl.vertex_attributes.vertexAttribI4uiv(0, &.{ 1, 2, 3, 4 });
    var fv: [4]f32 = undefined;
    gl.vertex_attributes.get(0, gl.vertex_attributes.VertexAttribParameter.current_vertex_attrib, &fv);
    gl.vertex_attributes.getI(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_size, &iv);
    gl.vertex_attributes.getIU(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_divisor, &buf_ids);
    gl.vertex_attributes.getIS(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_enabled, &iv);
    var attr_ptr: ?*anyopaque = null;
    gl.vertex_attributes.getPointer(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_buffer_binding, &attr_ptr);

    var vao_ids: [2]u32 = undefined;
    gl.vertex_arrays.gen(2, &vao_ids);
    gl.vertex_arrays.delete(2, &vao_ids);
    _ = gl.vertex_arrays.isVertexArray(0);
    gl.vertex_arrays.bind(0);
}

test "shaders, programs, uniforms" {
    ensureLoaded();

    var iv: [4]i32 = undefined;
    const vs = gl.shaders.create(gl.shaders.ShaderType.vertex_shader);
    const fs = gl.shaders.create(gl.shaders.ShaderType.fragment_shader);
    _ = gl.shaders.isShader(vs);
    gl.shaders.source(vs, "void main() {}");
    gl.shaders.compile(vs);
    gl.shaders.getParameter(vs, gl.shaders.ShaderParameter.compile_status, &iv);
    var log_buf: [64]u8 = undefined;
    _ = gl.shaders.getInfoLog(vs, &log_buf);
    _ = gl.shaders.getSource(vs, &log_buf);
    var range: [2]i32 = undefined;
    gl.shaders.getPrecisionFormat(gl.shaders.ShaderType.vertex_shader, gl.shaders.PrecisionType.high_float, &range, &range[0]);
    gl.shaders.releaseCompiler();
    gl.shaders.delete(vs);
    gl.shaders.delete(fs);

    const program = gl.programs.create();
    _ = gl.programs.isProgram(program);
    gl.programs.attach(program, vs);
    gl.programs.detach(program, vs);
    gl.programs.bindAttribLocation(program, 0, "position");
    _ = gl.programs.getAttribLocation(program, "position");
    _ = gl.programs.getFragDataLocation(program, "fragColor");
    gl.programs.link(program);
    gl.programs.validate(program);
    gl.programs.use(program);
    gl.programs.getParameter(program, gl.programs.ProgramParameter.link_status, &iv);
    _ = gl.programs.getInfoLog(program, &log_buf);
    var shader_ids: [2]u32 = undefined;
    _ = gl.programs.getAttachedShaders(program, &shader_ids);
    _ = gl.programs.getActiveAttrib(program, 0, &log_buf);
    var bin_buf: [64]u8 = undefined;
    var bin_format: u32 = 0;
    _ = gl.programs.getBinary(program, &bin_buf, &bin_format);
    gl.programs.programBinary(program, bin_format, &bin_buf, 0);
    gl.programs.programParameterI(program, gl.programs.ProgramParameter.program_binary_retrievable_hint, 0);
    gl.programs.delete(program);

    const loc = gl.uniforms.location(program, "u_color");
    _ = gl.uniforms.blockIndex(program, "Uniforms");
    gl.uniforms.blockBinding(program, 0, 0);
    _ = gl.uniforms.getActiveUniform(program, 0, &log_buf);
    gl.uniforms.getIndices(program, &.{ "u_color", "u_offset" }, &shader_ids);
    gl.uniforms.getActiveUniforms(program, &.{ 0, 1 }, gl.uniforms.UniformParameter.uniform_type, &iv);
    _ = gl.uniforms.getActiveUniformBlockName(program, 0, &log_buf);
    gl.uniforms.getActiveUniformBlock(program, 0, gl.uniforms.UniformBlockParameter.uniform_block_binding, &iv);
    var uniforms_fv: [4]f32 = undefined;
    gl.uniforms.get(program, loc, &uniforms_fv);
    gl.uniforms.getI(program, loc, &iv);
    gl.uniforms.getU(program, loc, &shader_ids);
    gl.uniforms.uniform1f(loc, 1.0);
    gl.uniforms.uniform2f(loc, 1.0, 2.0);
    gl.uniforms.uniform3f(loc, 1.0, 2.0, 3.0);
    gl.uniforms.uniform4f(loc, 1.0, 2.0, 3.0, 4.0);
    gl.uniforms.uniform1fv(loc, &.{1.0});
    gl.uniforms.uniform2fv(loc, &.{ 1.0, 2.0 });
    gl.uniforms.uniform3fv(loc, &.{ 1.0, 2.0, 3.0 });
    gl.uniforms.uniform4fv(loc, &.{ 1.0, 2.0, 3.0, 4.0 });
    gl.uniforms.uniform1i(loc, 1);
    gl.uniforms.uniform2i(loc, 1, 2);
    gl.uniforms.uniform3i(loc, 1, 2, 3);
    gl.uniforms.uniform4i(loc, 1, 2, 3, 4);
    gl.uniforms.uniform1iv(loc, &.{1});
    gl.uniforms.uniform2iv(loc, &.{ 1, 2 });
    gl.uniforms.uniform3iv(loc, &.{ 1, 2, 3 });
    gl.uniforms.uniform4iv(loc, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniform1ui(loc, 1);
    gl.uniforms.uniform2ui(loc, 1, 2);
    gl.uniforms.uniform3ui(loc, 1, 2, 3);
    gl.uniforms.uniform4ui(loc, 1, 2, 3, 4);
    gl.uniforms.uniform1uiv(loc, &.{1});
    gl.uniforms.uniform2uiv(loc, &.{ 1, 2 });
    gl.uniforms.uniform3uiv(loc, &.{ 1, 2, 3 });
    gl.uniforms.uniform4uiv(loc, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniformMatrix2fv(loc, false, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniformMatrix2x3fv(loc, false, &.{ 1, 2, 3, 4, 5, 6 });
    gl.uniforms.uniformMatrix2x4fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8 });
    gl.uniforms.uniformMatrix3fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 });
    gl.uniforms.uniformMatrix3x2fv(loc, false, &.{ 1, 2, 3, 4, 5, 6 });
    gl.uniforms.uniformMatrix3x4fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 });
    gl.uniforms.uniformMatrix4fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    gl.uniforms.uniformMatrix4x2fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8 });
    gl.uniforms.uniformMatrix4x3fv(loc, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 });
}

test "queries, transform feedback, sync, loader" {
    ensureLoaded();

    var q_ids: [2]u32 = undefined;
    gl.queries.gen(2, &q_ids);
    gl.queries.delete(2, &q_ids);
    _ = gl.queries.isQuery(0);
    gl.queries.begin(gl.queries.QueryTarget.any_samples_passed, 0);
    gl.queries.end(gl.queries.QueryTarget.any_samples_passed);
    var counts: [2]u32 = undefined;
    gl.queries.getObject(0, gl.queries.QueryParameter.query_result, &counts);
    gl.queries.getResult(0, &counts);
    gl.queries.resultIsAvailable(0, &counts);
    var iv: [4]i32 = undefined;
    gl.queries.getParameter(gl.queries.QueryTarget.any_samples_passed, gl.queries.QueryParameter.current_query, &iv);

    var tf_ids: [2]u32 = undefined;
    gl.transform_feedback.gen(2, &tf_ids);
    gl.transform_feedback.delete(2, &tf_ids);
    _ = gl.transform_feedback.isTransformFeedback(0);
    gl.transform_feedback.bind(0);
    gl.transform_feedback.begin(gl.drawing.PrimitiveType.triangles);
    gl.transform_feedback.pause();
    gl.transform_feedback.resumeCapture();
    gl.transform_feedback.end();
    gl.transform_feedback.varyings(0, &.{"out_data"}, gl.transform_feedback.BufferMode.interleaved_attribs);
    var name_buf: [64]u8 = undefined;
    _ = gl.transform_feedback.getVarying(0, 0, &name_buf);

    const fence = gl.sync.fence(gl.sync.FenceCondition.sync_gpu_commands_complete, 0);
    _ = gl.sync.isSync(fence);
    var values: [4]i32 = undefined;
    var length: i32 = 0;
    gl.sync.getParameter(fence, gl.sync.SyncParameter.sync_status, 4, &length, &values);
    _ = gl.sync.clientWait(fence, 0, 0);
    gl.sync.wait(fence, 0, 0);
    gl.sync.delete(fence);

    try std.testing.expect(!(try gl.loader.hasExtension("GL_KHR_debug")));
}