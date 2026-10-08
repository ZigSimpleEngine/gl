//! API surface tests: every public function of every namespace is called at
//! least once against a real OpenGL context, so wrappers are verified for
//! actual driver behavior, not just call syntax.
//!
//! The context comes from `test_gl_setup` (hidden RGFW window); the file
//! only compiles when the optional local rgfw checkout is present. Without
//! rgfw these tests cannot build at all — `build.zig` then fails the `test`
//! step with an explicit message instead of running fake-green mocks.
//!
//! Silent by design: test binaries must not write to stderr under
//! `zig build test` (Zig 0.16 `--listen` IPC quirk on Windows turns any
//! child output into a spurious `failed command` line). Results surface as
//! passed/failed tests only.

const std = @import("std");
const gl = @import("gl");
const setup = @import("test_gl_setup.zig");

/// Indexed query target for per-binding transform feedback state
/// (`GL_TRANSFORM_FEEDBACK_BUFFER_BINDING`, valid for `glGetIntegeri_v`).
const transform_feedback_buffer_binding: u32 = 0x8C8F;

/// Indexed query target for 64-bit transform feedback offsets
/// (`GL_TRANSFORM_FEEDBACK_BUFFER_START`, valid for `glGetInteger64i_v`).
const transform_feedback_buffer_start: u32 = 0x8C84;

test "state, viewport, clear, blending, depth, stencil, rasterization, drawing" {
    try setup.ensureRealSetup();

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());

    gl.state.enable(gl.state.Capability.blend);
    gl.state.disable(gl.state.Capability.depth_test);
    _ = gl.state.isEnabled(gl.state.Capability.dither);
    var b: [4]u8 = undefined;
    gl.state.getBoolean(gl.state.GetPName.color_writemask, &b);
    var iv: [4]i32 = undefined;
    gl.state.getInteger(gl.state.GetPName.max_texture_size, &iv);
    try std.testing.expect(iv[0] > 0);
    var i64v: [4]i64 = undefined;
    gl.state.getInteger64(gl.state.GetPName.max_server_wait_timeout, &i64v);
    gl.state.getIntegerI(transform_feedback_buffer_binding, 0, &iv);
    gl.state.getInteger64I(transform_feedback_buffer_start, 0, &i64v);
    var fv: [4]f32 = undefined;
    gl.state.getFloat(gl.state.GetPName.color_clear_value, &fv);
    try std.testing.expect(gl.state.getString(gl.state.StringName.version) != null);
    try std.testing.expect(gl.state.getStringI(gl.state.StringName.extensions, 0) != null);
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
    gl.clear.clearBufferFi(gl.clear.Buffer.depth_stencil, 0, 1.0, 0);

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

    setup.useSharedProgram();
    gl.drawing.drawArrays(gl.drawing.PrimitiveType.triangles, 0, 3);
    gl.drawing.drawArraysInstanced(gl.drawing.PrimitiveType.triangles, 0, 3, 2);
    gl.drawing.drawElements(gl.drawing.PrimitiveType.triangles, 3, gl.enums.DataType.unsigned_short, null);
    gl.drawing.drawElementsInstanced(gl.drawing.PrimitiveType.triangles, 3, gl.enums.DataType.unsigned_short, null, 2);
    gl.drawing.drawRangeElements(gl.drawing.PrimitiveType.triangles, 0, 2, 3, gl.enums.DataType.unsigned_short, null);

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

test "buffers, textures, samplers, pixels" {
    try setup.ensureRealSetup();

    var vertexBufferStorage: [1]u32 = undefined;
    gl.buffers.gen(1, &vertexBufferStorage);
    const vertexBuffer = vertexBufferStorage[0];
    try std.testing.expect(vertexBuffer != 0);
    // Gen* only reserves the name; the object exists after the first bind.
    gl.buffers.bind(gl.buffers.BufferTarget.array_buffer, vertexBuffer);
    try std.testing.expect(gl.buffers.isBuffer(vertexBuffer));
    try std.testing.expect(!gl.buffers.isBuffer(0));
    gl.buffers.bufferData(gl.buffers.BufferTarget.array_buffer, 64, null, gl.buffers.BufferUsage.static_draw);
    gl.buffers.bindBase(gl.buffers.BufferTarget.uniform_buffer, 0, vertexBuffer);
    gl.buffers.bindRange(gl.buffers.BufferTarget.uniform_buffer, 0, vertexBuffer, 0, 64);
    var sizeStorage: [1]i32 = undefined;
    gl.buffers.getParameter(gl.buffers.BufferTarget.array_buffer, gl.buffers.BufferParameter.buffer_size, &sizeStorage);
    try std.testing.expectEqual(@as(i32, 64), sizeStorage[0]);
    var size64Storage: [1]i64 = undefined;
    gl.buffers.getParameter64(gl.buffers.BufferTarget.array_buffer, gl.buffers.BufferParameter.buffer_size, &size64Storage);
    try std.testing.expectEqual(@as(i64, 64), size64Storage[0]);
    gl.buffers.bufferSubData(gl.buffers.BufferTarget.array_buffer, 0, 4, "data");
    gl.buffers.bufferSubDataSlice(gl.buffers.BufferTarget.array_buffer, 0, "data");
    var copyBuffer: u32 = 0;
    gl.buffers.gen(1, @ptrCast(&copyBuffer));
    gl.buffers.bind(gl.buffers.BufferTarget.copy_read_buffer, vertexBuffer);
    gl.buffers.bind(gl.buffers.BufferTarget.copy_write_buffer, copyBuffer);
    try std.testing.expect(gl.buffers.isBuffer(copyBuffer));
    gl.buffers.bufferData(gl.buffers.BufferTarget.copy_write_buffer, 64, null, gl.buffers.BufferUsage.static_draw);
    gl.buffers.copySubData(
        gl.buffers.BufferTarget.copy_read_buffer,
        gl.buffers.BufferTarget.copy_write_buffer,
        0,
        0,
        4,
    );
    const mapped = gl.buffers.map(gl.buffers.BufferTarget.array_buffer, 0, 64, .{ .read = true, .write = true });
    try std.testing.expect(mapped != null);
    try std.testing.expect(gl.buffers.unmap(gl.buffers.BufferTarget.array_buffer));
    const mappedExplicit = gl.buffers.map(gl.buffers.BufferTarget.array_buffer, 0, 64, .{ .write = true, .flush_explicit = true });
    try std.testing.expect(mappedExplicit != null);
    gl.buffers.flushMappedRange(gl.buffers.BufferTarget.array_buffer, 0, 64);
    try std.testing.expect(gl.buffers.unmap(gl.buffers.BufferTarget.array_buffer));
    _ = (gl.buffers.MapAccess{ .read = true }).bits();
    gl.buffers.bufferDataSlice(gl.buffers.BufferTarget.array_buffer, "data", gl.buffers.BufferUsage.static_draw);
    gl.buffers.bind(gl.buffers.BufferTarget.array_buffer, 0);
    gl.buffers.bind(gl.buffers.BufferTarget.copy_read_buffer, 0);
    gl.buffers.bind(gl.buffers.BufferTarget.copy_write_buffer, 0);
    gl.buffers.delete(1, @ptrCast(&vertexBuffer));
    gl.buffers.delete(1, @ptrCast(&copyBuffer));

    var colorTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&colorTexture));
    gl.textures.activeTexture(gl.textures.TextureUnit.texture0);
    gl.textures.bind(gl.textures.TextureTarget.texture_2d, colorTexture);
    try std.testing.expect(gl.textures.isTexture(colorTexture));
    try std.testing.expect(!gl.textures.isTexture(0));
    // NOTE: SubImage uploads require real client memory: unlike Image
    // calls, a null pointer means byte offset 0 and dereferences address 0.
    var rgbaPixels: [64]u8 = @splat(0);
    var volumePixels: [256]u8 = @splat(0);
    var etcPixels: [8]u8 = @splat(0);
    var etcArrayPixels: [32]u8 = @splat(0);
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
    gl.textures.subImage2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        0,
        0,
        4,
        4,
        gl.textures.PixelFormat.rgba,
        gl.enums.DataType.unsigned_byte,
        &rgbaPixels,
    );
    gl.textures.generateMipmap(gl.textures.TextureTarget.texture_2d);
    gl.textures.copyImage2d(gl.textures.TextureTarget.texture_2d, 0, gl.textures.InternalFormat.rgba8, 0, 0, 4, 4, 0);
    gl.textures.copySubImage2d(gl.textures.TextureTarget.texture_2d, 0, 0, 0, 0, 0, 4, 4);
    gl.textures.parameterI(
        gl.textures.TextureTarget.texture_2d,
        gl.textures.TextureParameter.texture_min_filter,
        @intCast(@backingInt(gl.textures.TextureMinFilter.nearest)),
    );
    gl.textures.parameterF(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, 0.0);
    gl.textures.parameterIv(
        gl.textures.TextureTarget.texture_2d,
        gl.textures.TextureParameter.texture_min_filter,
        &.{@intCast(@backingInt(gl.textures.TextureMinFilter.nearest))},
    );
    gl.textures.parameterFv(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, &.{0.0});
    var filterStorage: [1]i32 = undefined;
    gl.textures.getParameterI(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_min_filter, &filterStorage);
    try std.testing.expectEqual(@as(i32, @intCast(@backingInt(gl.textures.TextureMinFilter.nearest))), filterStorage[0]);
    var lodStorage: [1]f32 = undefined;
    gl.textures.getParameterF(gl.textures.TextureTarget.texture_2d, gl.textures.TextureParameter.texture_max_lod, &lodStorage);
    try std.testing.expectEqual(@as(f32, 0.0), lodStorage[0]);

    var volumeTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&volumeTexture));
    gl.textures.bind(gl.textures.TextureTarget.texture_3d, volumeTexture);
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
        &volumePixels,
    );
    gl.textures.copySubImage3d(gl.textures.TextureTarget.texture_3d, 0, 0, 0, 0, 0, 0, 4, 4);

    var arrayTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&arrayTexture));
    gl.textures.bind(gl.textures.TextureTarget.texture_2d_array, arrayTexture);
    gl.textures.compressedImage3d(
        gl.textures.TextureTarget.texture_2d_array,
        0,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        4,
        4,
        4,
        0,
        32,
        &etcArrayPixels,
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
        32,
        &etcArrayPixels,
    );

    var storageTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&storageTexture));
    gl.textures.bind(gl.textures.TextureTarget.texture_2d, storageTexture);
    gl.textures.storage2d(gl.textures.TextureTarget.texture_2d, 1, gl.textures.InternalFormat.rgba8, 4, 4);

    var compressedTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&compressedTexture));
    gl.textures.bind(gl.textures.TextureTarget.texture_2d, compressedTexture);
    gl.textures.compressedImage2d(
        gl.textures.TextureTarget.texture_2d,
        0,
        gl.textures.InternalFormat.compressed_rgb8_etc2,
        4,
        4,
        0,
        8,
        &etcPixels,
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
        &etcPixels,
    );

    var storageVolume: u32 = 0;
    gl.textures.gen(1, @ptrCast(&storageVolume));
    gl.textures.bind(gl.textures.TextureTarget.texture_3d, storageVolume);
    gl.textures.storage3d(gl.textures.TextureTarget.texture_3d, 1, gl.textures.InternalFormat.rgba8, 4, 4, 4);

    gl.textures.bind(gl.textures.TextureTarget.texture_2d, 0);
    gl.textures.bind(gl.textures.TextureTarget.texture_3d, 0);
    gl.textures.bind(gl.textures.TextureTarget.texture_2d_array, 0);
    gl.textures.delete(1, @ptrCast(&colorTexture));
    gl.textures.delete(1, @ptrCast(&volumeTexture));
    gl.textures.delete(1, @ptrCast(&arrayTexture));
    gl.textures.delete(1, @ptrCast(&storageTexture));
    gl.textures.delete(1, @ptrCast(&compressedTexture));
    gl.textures.delete(1, @ptrCast(&storageVolume));

    var sampler: u32 = 0;
    gl.samplers.gen(1, @ptrCast(&sampler));
    gl.samplers.bind(0, sampler);
    try std.testing.expect(gl.samplers.isSampler(sampler));
    try std.testing.expect(!gl.samplers.isSampler(0));
    gl.samplers.parameterI(
        sampler,
        gl.samplers.SamplerParameter.texture_min_filter,
        @intCast(@backingInt(gl.textures.TextureMinFilter.nearest)),
    );
    gl.samplers.parameterF(sampler, gl.samplers.SamplerParameter.texture_max_lod, 0.0);
    gl.samplers.parameterIv(
        sampler,
        gl.samplers.SamplerParameter.texture_min_filter,
        &.{@intCast(@backingInt(gl.textures.TextureMinFilter.nearest))},
    );
    gl.samplers.parameterFv(sampler, gl.samplers.SamplerParameter.texture_max_lod, &.{0.0});
    gl.samplers.getParameterI(sampler, gl.samplers.SamplerParameter.texture_min_filter, &filterStorage);
    try std.testing.expectEqual(@as(i32, @intCast(@backingInt(gl.textures.TextureMinFilter.nearest))), filterStorage[0]);
    gl.samplers.getParameterF(sampler, gl.samplers.SamplerParameter.texture_max_lod, &lodStorage);
    try std.testing.expectEqual(@as(f32, 0.0), lodStorage[0]);
    gl.samplers.bind(0, 0);
    gl.samplers.delete(1, @ptrCast(&sampler));

    gl.pixels.storeI(gl.pixels.PixelStoreParameter.pack_alignment, 4);
    gl.pixels.readBuffer(gl.pixels.ReadBuffer.back);
    var px: [64]u8 = undefined;
    gl.pixels.readPixels(0, 0, 4, 4, gl.textures.PixelFormat.rgba, gl.enums.DataType.unsigned_byte, &px);

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

test "framebuffers, renderbuffers" {
    try setup.ensureRealSetup();

    var renderbuffer: u32 = 0;
    gl.renderbuffers.gen(1, @ptrCast(&renderbuffer));
    gl.renderbuffers.bind(gl.renderbuffers.RenderbufferTarget.renderbuffer, renderbuffer);
    try std.testing.expect(gl.renderbuffers.isRenderbuffer(renderbuffer));
    try std.testing.expect(!gl.renderbuffers.isRenderbuffer(0));
    gl.renderbuffers.storage(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        gl.textures.InternalFormat.depth24_stencil8,
        4,
        4,
    );

    var colorTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&colorTexture));
    gl.textures.activeTexture(gl.textures.TextureUnit.texture0);
    gl.textures.bind(gl.textures.TextureTarget.texture_2d, colorTexture);
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
    gl.textures.parameterI(
        gl.textures.TextureTarget.texture_2d,
        gl.textures.TextureParameter.texture_min_filter,
        @intCast(@backingInt(gl.textures.TextureMinFilter.nearest)),
    );

    gl.framebuffers.bind(gl.framebuffers.FramebufferTarget.framebuffer, 0);
    try std.testing.expectEqual(
        gl.framebuffers.FramebufferStatus.framebuffer_complete,
        gl.framebuffers.checkStatus(gl.framebuffers.FramebufferTarget.framebuffer),
    );
    var framebuffer: u32 = 0;
    gl.framebuffers.gen(1, @ptrCast(&framebuffer));
    gl.framebuffers.bind(gl.framebuffers.FramebufferTarget.framebuffer, framebuffer);
    try std.testing.expect(gl.framebuffers.isFramebuffer(framebuffer));
    try std.testing.expect(!gl.framebuffers.isFramebuffer(0));
    gl.framebuffers.attachRenderbuffer(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        renderbuffer,
    );
    gl.framebuffers.attachTexture2d(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        gl.textures.TextureTarget.texture_2d,
        colorTexture,
        0,
    );
    try std.testing.expectEqual(
        gl.framebuffers.FramebufferStatus.framebuffer_complete,
        gl.framebuffers.checkStatus(gl.framebuffers.FramebufferTarget.framebuffer),
    );
    var attached: [1]i32 = undefined;
    gl.framebuffers.getAttachmentParameter(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        gl.framebuffers.AttachmentParameter.framebuffer_attachment_object_name,
        &attached,
    );
    try std.testing.expectEqual(@as(i32, @intCast(colorTexture)), attached[0]);

    var arrayTexture: u32 = 0;
    gl.textures.gen(1, @ptrCast(&arrayTexture));
    gl.textures.bind(gl.textures.TextureTarget.texture_2d_array, arrayTexture);
    gl.textures.storage3d(gl.textures.TextureTarget.texture_2d_array, 1, gl.textures.InternalFormat.rgba8, 4, 4, 2);
    gl.textures.parameterI(
        gl.textures.TextureTarget.texture_2d_array,
        gl.textures.TextureParameter.texture_min_filter,
        @intCast(@backingInt(gl.textures.TextureMinFilter.nearest)),
    );
    gl.framebuffers.bind(gl.framebuffers.FramebufferTarget.framebuffer, framebuffer);
    gl.framebuffers.attachTextureLayer(
        gl.framebuffers.FramebufferTarget.framebuffer,
        gl.framebuffers.Attachment.color_attachment0,
        arrayTexture,
        0,
        1,
    );
    try std.testing.expectEqual(
        gl.framebuffers.FramebufferStatus.framebuffer_complete,
        gl.framebuffers.checkStatus(gl.framebuffers.FramebufferTarget.framebuffer),
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
        .{ .color = true },
        gl.framebuffers.BlitFilter.nearest,
    );
    gl.framebuffers.drawBuffers(&.{gl.framebuffers.DrawBuffer.color_attachment0});
    gl.framebuffers.invalidate(
        gl.framebuffers.FramebufferTarget.framebuffer,
        &.{@backingInt(gl.framebuffers.Attachment.color_attachment0)},
    );
    gl.framebuffers.invalidateSub(
        gl.framebuffers.FramebufferTarget.framebuffer,
        &.{@backingInt(gl.framebuffers.Attachment.color_attachment0)},
        0,
        0,
        4,
        4,
    );
    gl.framebuffers.bind(gl.framebuffers.FramebufferTarget.framebuffer, 0);
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
    gl.framebuffers.delete(1, @ptrCast(&framebuffer));
    gl.textures.delete(1, @ptrCast(&colorTexture));
    gl.textures.delete(1, @ptrCast(&arrayTexture));
    gl.renderbuffers.delete(1, @ptrCast(&renderbuffer));

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

test "renderbuffers" {
    try setup.ensureRealSetup();

    var rbo: u32 = 0;
    gl.renderbuffers.gen(1, @ptrCast(&rbo));
    gl.renderbuffers.bind(gl.renderbuffers.RenderbufferTarget.renderbuffer, rbo);
    try std.testing.expect(gl.renderbuffers.isRenderbuffer(rbo));
    try std.testing.expect(!gl.renderbuffers.isRenderbuffer(0));
    gl.renderbuffers.storage(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        gl.textures.InternalFormat.depth24_stencil8,
        4,
        4,
    );
    var widthStorage: [1]i32 = undefined;
    gl.renderbuffers.getParameter(
        gl.renderbuffers.RenderbufferTarget.renderbuffer,
        gl.renderbuffers.RenderbufferParameter.renderbuffer_width,
        &widthStorage,
    );
    try std.testing.expectEqual(@as(i32, 4), widthStorage[0]);
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
        &widthStorage,
    );
    try std.testing.expectEqual(@as(i32, 4), widthStorage[0]);
    gl.renderbuffers.bind(gl.renderbuffers.RenderbufferTarget.renderbuffer, 0);
    gl.renderbuffers.delete(1, @ptrCast(&rbo));

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

test "vertex attributes, vertex arrays" {
    try setup.ensureRealSetup();
    setup.useSharedProgram();

    gl.vertex_attributes.enable(0);
    gl.vertex_attributes.disable(0);
    gl.vertex_attributes.pointer(0, 3, gl.enums.DataType.float, false, 12, null);
    gl.vertex_attributes.iPointer(0, 3, gl.enums.DataType.int, 12, null);
    gl.vertex_attributes.divisor(0, 1);
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.vertex_attributes.vertexAttrib1f(0, 1.0);
    gl.vertex_attributes.vertexAttrib2f(0, 1.0, 2.0);
    gl.vertex_attributes.vertexAttrib3f(0, 1.0, 2.0, 3.0);
    gl.vertex_attributes.vertexAttrib4f(0, 1.0, 2.0, 3.0, 4.0);
    var currentStorage: [4]f32 = undefined;
    gl.vertex_attributes.get(0, gl.vertex_attributes.VertexAttribParameter.current_vertex_attrib, &currentStorage);
    try std.testing.expectEqual([4]f32{ 1.0, 2.0, 3.0, 4.0 }, currentStorage);
    gl.vertex_attributes.vertexAttrib1fv(0, &.{1.0});
    gl.vertex_attributes.vertexAttrib2fv(0, &.{ 1.0, 2.0 });
    gl.vertex_attributes.vertexAttrib3fv(0, &.{ 1.0, 2.0, 3.0 });
    gl.vertex_attributes.vertexAttrib4fv(0, &.{ 1.0, 2.0, 3.0, 4.0 });
    gl.vertex_attributes.vertexAttribI4i(0, 1, 2, 3, 4);
    gl.vertex_attributes.vertexAttribI4ui(0, 1, 2, 3, 4);
    gl.vertex_attributes.vertexAttribI4iv(0, &.{ 1, 2, 3, 4 });
    gl.vertex_attributes.vertexAttribI4uiv(0, &.{ 1, 2, 3, 4 });
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    var sizeStorage: [1]i32 = undefined;
    gl.vertex_attributes.getI(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_size, &sizeStorage);
    try std.testing.expectEqual(@as(i32, 3), sizeStorage[0]);
    var divisorStorage: [1]u32 = undefined;
    gl.vertex_attributes.getIU(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_divisor, &divisorStorage);
    try std.testing.expectEqual(@as(u32, 1), divisorStorage[0]);
    var enabledStorage: [1]i32 = undefined;
    gl.vertex_attributes.getIS(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_enabled, &enabledStorage);
    try std.testing.expectEqual(@as(i32, 0), enabledStorage[0]);
    var attribPointer: ?*anyopaque = null;
    gl.vertex_attributes.getPointer(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_pointer, &attribPointer);
    try std.testing.expect(attribPointer == null);
    var attribBuffer: [1]i32 = undefined;
    gl.vertex_attributes.getI(0, gl.vertex_attributes.VertexAttribParameter.vertex_attrib_array_buffer_binding, &attribBuffer);
    try std.testing.expect(attribBuffer[0] != 0);

    var vertexArray: u32 = 0;
    gl.vertex_arrays.gen(1, @ptrCast(&vertexArray));
    gl.vertex_arrays.bind(vertexArray);
    try std.testing.expect(gl.vertex_arrays.isVertexArray(vertexArray));
    try std.testing.expect(!gl.vertex_arrays.isVertexArray(0));
    gl.vertex_arrays.delete(1, @ptrCast(&vertexArray));
    gl.vertex_arrays.bind(0);

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

const rosterVertexSource =
    \\#version 330 core
    \\layout(location = 0) in vec3 position;
    \\out vec3 vertexColor;
    \\uniform mat4 u_matrix;
    \\layout(std140) uniform Transform { mat4 model; };
    \\void main() { gl_Position = model * u_matrix * vec4(position, 1.0); vertexColor = position; }
;

const rosterFragmentSource =
    \\#version 330 core
    \\in vec3 vertexColor;
    \\out vec4 fragColor;
    \\uniform float u_float;
    \\uniform vec2 u_vec2;
    \\uniform vec3 u_vec3;
    \\uniform vec4 u_vec4;
    \\uniform int u_int;
    \\uniform ivec2 u_ivec2;
    \\uniform ivec3 u_ivec3;
    \\uniform ivec4 u_ivec4;
    \\uniform uint u_uint;
    \\uniform uvec2 u_uvec2;
    \\uniform uvec3 u_uvec3;
    \\uniform uvec4 u_uvec4;
    \\uniform mat2 u_mat2;
    \\uniform mat2x3 u_mat2x3;
    \\uniform mat2x4 u_mat2x4;
    \\uniform mat3 u_mat3;
    \\uniform mat3x2 u_mat3x2;
    \\uniform mat3x4 u_mat3x4;
    \\uniform mat4 u_mat4;
    \\uniform mat4x2 u_mat4x2;
    \\uniform mat4x3 u_mat4x3;
    \\void main() {
    \\    float total = u_float + float(u_int) + float(u_uint);
    \\    vec2 partial2 = u_vec2 + vec2(u_ivec2) + vec2(u_uvec2);
    \\    vec3 partial3 = u_vec3 + vec3(u_ivec3) + vec3(u_uvec3) + vertexColor;
    \\    vec4 partial4 = u_vec4 + vec4(u_ivec4) + vec4(u_uvec4);
    \\    vec4 transformed = u_mat4 * vec4(partial3, 1.0);
    \\    transformed = transformed + vec4(u_mat3 * partial3, 0.0) + vec4(u_mat2 * partial2, 0.0, 0.0);
    \\    transformed.xyz = transformed.xyz + u_mat2x3 * partial2;
    \\    transformed = transformed + u_mat2x4 * partial2;
    \\    transformed.xy = transformed.xy + u_mat3x2 * partial3;
    \\    transformed = transformed + u_mat3x4 * partial3;
    \\    transformed.xy = transformed.xy + u_mat4x2 * partial4;
    \\    transformed.xyz = transformed.xyz + u_mat4x3 * partial4;
    \\    fragColor = transformed * (0.001 + 0.001 * total) + vec4(partial4.xyz, 1.0);
    \\}
;

const feedbackVertexSource =
    \\#version 330 core
    \\layout(location = 0) in vec3 position;
    \\out float out_data;
    \\void main() { gl_Position = vec4(position, 1.0); out_data = position.x + 1.0; }
;

const feedbackFragmentSource =
    \\#version 330 core
    \\out vec4 fragColor;
    \\void main() { fragColor = vec4(1.0); }
;

test "shaders, programs, uniforms" {
    try setup.ensureRealSetup();

    const vertexShader = gl.shaders.create(gl.shaders.ShaderType.vertex_shader);
    const fragmentShader = gl.shaders.create(gl.shaders.ShaderType.fragment_shader);
    try std.testing.expect(gl.shaders.isShader(vertexShader));
    try std.testing.expect(!gl.shaders.isShader(0));
    gl.shaders.source(vertexShader, rosterVertexSource);
    gl.shaders.source(fragmentShader, rosterFragmentSource);
    gl.shaders.compile(vertexShader);
    gl.shaders.compile(fragmentShader);
    var status: [1]i32 = undefined;
    gl.shaders.getParameter(vertexShader, gl.shaders.ShaderParameter.compile_status, &status);
    try std.testing.expectEqual(@as(i32, 1), status[0]);
    gl.shaders.getParameter(fragmentShader, gl.shaders.ShaderParameter.compile_status, &status);
    try std.testing.expectEqual(@as(i32, 1), status[0]);
    var logBuffer: [512]u8 = undefined;
    _ = gl.shaders.getInfoLog(vertexShader, &logBuffer);
    _ = gl.shaders.getSource(vertexShader, &logBuffer);
    if (gl.loader.context.is_es) {
        var range: [2]i32 = undefined;
        var precision: i32 = 0;
        gl.shaders.getPrecisionFormat(gl.shaders.ShaderType.vertex_shader, gl.shaders.PrecisionType.high_float, &range, &precision);
        gl.shaders.releaseCompiler();
    }

    const program = gl.programs.create();
    try std.testing.expect(gl.programs.isProgram(program));
    try std.testing.expect(!gl.programs.isProgram(0));
    gl.programs.attach(program, vertexShader);
    gl.programs.attach(program, fragmentShader);
    var attachedShaders: [2]u32 = undefined;
    try std.testing.expectEqual(@as(usize, 2), gl.programs.getAttachedShaders(program, &attachedShaders));
    gl.programs.bindAttribLocation(program, 0, "position");
    gl.programs.programParameterI(program, gl.programs.ProgramParameter.program_binary_retrievable_hint, 1);
    gl.programs.link(program);
    gl.programs.getParameter(program, gl.programs.ProgramParameter.link_status, &status);
    try std.testing.expectEqual(@as(i32, 1), status[0]);
    gl.programs.validate(program);
    gl.programs.use(program);
    try std.testing.expectEqual(@as(i32, 0), gl.programs.getAttribLocation(program, "position"));
    try std.testing.expect(gl.programs.getFragDataLocation(program, "fragColor") >= 0);
    _ = gl.programs.getInfoLog(program, &logBuffer);
    const attribInfo = gl.programs.getActiveAttrib(program, 0, &logBuffer);
    try std.testing.expect(attribInfo.name_length > 0);
    var binaryBuffer: [65536]u8 = undefined;
    var binaryFormat: u32 = 0;
    const binaryLength = gl.programs.getBinary(program, &binaryBuffer, &binaryFormat);
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    if (binaryLength > 0) {
        const binaryProgram = gl.programs.create();
        gl.programs.programBinary(binaryProgram, binaryFormat, &binaryBuffer, @intCast(binaryLength));
        gl.programs.getParameter(binaryProgram, gl.programs.ProgramParameter.link_status, &status);
        try std.testing.expectEqual(@as(i32, 1), status[0]);
        gl.programs.delete(binaryProgram);
    }
    gl.programs.detach(program, vertexShader);
    gl.programs.detach(program, fragmentShader);
    gl.shaders.delete(vertexShader);
    gl.shaders.delete(fragmentShader);

    const locFloat = gl.uniforms.location(program, "u_float");
    const locVec2 = gl.uniforms.location(program, "u_vec2");
    const locVec3 = gl.uniforms.location(program, "u_vec3");
    const locVec4 = gl.uniforms.location(program, "u_vec4");
    const locInt = gl.uniforms.location(program, "u_int");
    const locIVec2 = gl.uniforms.location(program, "u_ivec2");
    const locIVec3 = gl.uniforms.location(program, "u_ivec3");
    const locIVec4 = gl.uniforms.location(program, "u_ivec4");
    const locUint = gl.uniforms.location(program, "u_uint");
    const locUVec2 = gl.uniforms.location(program, "u_uvec2");
    const locUVec3 = gl.uniforms.location(program, "u_uvec3");
    const locUVec4 = gl.uniforms.location(program, "u_uvec4");
    const locMat2 = gl.uniforms.location(program, "u_mat2");
    const locMat2x3 = gl.uniforms.location(program, "u_mat2x3");
    const locMat2x4 = gl.uniforms.location(program, "u_mat2x4");
    const locMat3 = gl.uniforms.location(program, "u_mat3");
    const locMat3x2 = gl.uniforms.location(program, "u_mat3x2");
    const locMat3x4 = gl.uniforms.location(program, "u_mat3x4");
    const locMat4 = gl.uniforms.location(program, "u_mat4");
    const locMat4x2 = gl.uniforms.location(program, "u_mat4x2");
    const locMat4x3 = gl.uniforms.location(program, "u_mat4x3");
    const uniformLocations = [_]i32{
        locFloat,  locVec2,   locVec3,   locVec4,
        locInt,    locIVec2,  locIVec3,  locIVec4,
        locUint,   locUVec2,  locUVec3,  locUVec4,
        locMat2,   locMat2x3, locMat2x4, locMat3,
        locMat3x2, locMat3x4, locMat4,   locMat4x2,
        locMat4x3,
    };
    for (uniformLocations) |uniformLocation| {
        try std.testing.expect(uniformLocation >= 0);
    }
    try std.testing.expectEqual(std.math.maxInt(u32), gl.uniforms.blockIndex(program, "Uniforms"));
    const transformBlock = gl.uniforms.blockIndex(program, "Transform");
    try std.testing.expect(transformBlock != std.math.maxInt(u32));
    gl.uniforms.blockBinding(program, transformBlock, 0);
    var blockName: [64]u8 = undefined;
    const blockNameLength = gl.uniforms.getActiveUniformBlockName(program, 0, &blockName);
    try std.testing.expectEqualStrings("Transform", blockName[0..blockNameLength]);
    var blockBindingStorage: [1]i32 = undefined;
    gl.uniforms.getActiveUniformBlock(program, 0, gl.uniforms.UniformBlockParameter.uniform_block_binding, &blockBindingStorage);
    try std.testing.expectEqual(@as(i32, 0), blockBindingStorage[0]);
    const uniformInfo = gl.uniforms.getActiveUniform(program, 0, &logBuffer);
    try std.testing.expect(uniformInfo.name_length > 0);
    var uniformIndices: [2]u32 = undefined;
    gl.uniforms.getIndices(program, &.{ "u_float", "u_vec2" }, &uniformIndices);
    try std.testing.expect(uniformIndices[0] != std.math.maxInt(u32));
    try std.testing.expect(uniformIndices[1] != std.math.maxInt(u32));
    var uniformTypes: [2]i32 = undefined;
    gl.uniforms.getActiveUniforms(program, uniformIndices[0..], gl.uniforms.UniformParameter.uniform_type, &uniformTypes);
    try std.testing.expectEqual(@as(i32, @backingInt(gl.enums.DataType.float)), uniformTypes[0]);
    var readback: [4]f32 = undefined;
    var readbackInt: [4]i32 = undefined;
    var readbackUint: [4]u32 = undefined;
    gl.uniforms.uniform1f(locFloat, 1.0);
    gl.uniforms.get(program, locFloat, &readback);
    try std.testing.expectEqual(@as(f32, 1.0), readback[0]);
    gl.uniforms.uniform1i(locInt, 7);
    gl.uniforms.getI(program, locInt, &readbackInt);
    try std.testing.expectEqual(@as(i32, 7), readbackInt[0]);
    gl.uniforms.uniform1ui(locUint, 9);
    gl.uniforms.getU(program, locUint, &readbackUint);
    try std.testing.expectEqual(@as(u32, 9), readbackUint[0]);
    gl.uniforms.uniform2f(locVec2, 1.0, 2.0);
    gl.uniforms.uniform3f(locVec3, 1.0, 2.0, 3.0);
    gl.uniforms.uniform4f(locVec4, 1.0, 2.0, 3.0, 4.0);
    gl.uniforms.uniform1fv(locFloat, &.{1.0});
    gl.uniforms.uniform2fv(locVec2, &.{ 1.0, 2.0 });
    gl.uniforms.uniform3fv(locVec3, &.{ 1.0, 2.0, 3.0 });
    gl.uniforms.uniform4fv(locVec4, &.{ 1.0, 2.0, 3.0, 4.0 });
    gl.uniforms.uniform2i(locIVec2, 1, 2);
    gl.uniforms.uniform3i(locIVec3, 1, 2, 3);
    gl.uniforms.uniform4i(locIVec4, 1, 2, 3, 4);
    gl.uniforms.uniform1iv(locInt, &.{1});
    gl.uniforms.uniform2iv(locIVec2, &.{ 1, 2 });
    gl.uniforms.uniform3iv(locIVec3, &.{ 1, 2, 3 });
    gl.uniforms.uniform4iv(locIVec4, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniform2ui(locUVec2, 1, 2);
    gl.uniforms.uniform3ui(locUVec3, 1, 2, 3);
    gl.uniforms.uniform4ui(locUVec4, 1, 2, 3, 4);
    gl.uniforms.uniform1uiv(locUint, &.{1});
    gl.uniforms.uniform2uiv(locUVec2, &.{ 1, 2 });
    gl.uniforms.uniform3uiv(locUVec3, &.{ 1, 2, 3 });
    gl.uniforms.uniform4uiv(locUVec4, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniformMatrix2fv(locMat2, false, &.{ 1, 2, 3, 4 });
    gl.uniforms.uniformMatrix2x3fv(locMat2x3, false, &.{ 1, 2, 3, 4, 5, 6 });
    gl.uniforms.uniformMatrix2x4fv(locMat2x4, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8 });
    gl.uniforms.uniformMatrix3fv(locMat3, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 });
    gl.uniforms.uniformMatrix3x2fv(locMat3x2, false, &.{ 1, 2, 3, 4, 5, 6 });
    gl.uniforms.uniformMatrix3x4fv(locMat3x4, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 });
    gl.uniforms.uniformMatrix4fv(locMat4, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    gl.uniforms.uniformMatrix4x2fv(locMat4x2, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8 });
    gl.uniforms.uniformMatrix4x3fv(locMat4x3, false, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 });
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.programs.delete(program);
    setup.useSharedProgram();

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

test "queries, transform feedback, sync, loader" {
    try setup.ensureRealSetup();
    setup.useSharedProgram();

    var query: u32 = 0;
    gl.queries.gen(1, @ptrCast(&query));
    try std.testing.expect(query != 0);
    try std.testing.expect(!gl.queries.isQuery(0));
    gl.queries.begin(gl.queries.QueryTarget.any_samples_passed, query);
    // BeginQuery creates the object; only now is it a real query.
    try std.testing.expect(gl.queries.isQuery(query));
    gl.drawing.drawArrays(gl.drawing.PrimitiveType.triangles, 0, 3);
    var boundStorage: [1]i32 = undefined;
    gl.queries.getParameter(gl.queries.QueryTarget.any_samples_passed, gl.queries.QueryParameter.current_query, &boundStorage);
    try std.testing.expectEqual(@as(i32, @intCast(query)), boundStorage[0]);
    gl.queries.end(gl.queries.QueryTarget.any_samples_passed);
    var available: [1]u32 = undefined;
    var spins: u32 = 0;
    while (spins < 10_000_000) : (spins += 1) {
        gl.queries.resultIsAvailable(query, &available);
        if (available[0] != 0) break;
    }
    try std.testing.expect(available[0] != 0);
    var result: [1]u32 = undefined;
    gl.queries.getResult(query, &result);
    gl.queries.getObject(query, gl.queries.QueryParameter.query_result, &result);
    gl.queries.delete(1, @ptrCast(&query));
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());

    const feedbackVertex = gl.shaders.create(gl.shaders.ShaderType.vertex_shader);
    const feedbackFragment = gl.shaders.create(gl.shaders.ShaderType.fragment_shader);
    gl.shaders.source(feedbackVertex, feedbackVertexSource);
    gl.shaders.source(feedbackFragment, feedbackFragmentSource);
    gl.shaders.compile(feedbackVertex);
    gl.shaders.compile(feedbackFragment);
    var feedbackStatus: [1]i32 = undefined;
    gl.shaders.getParameter(feedbackVertex, gl.shaders.ShaderParameter.compile_status, &feedbackStatus);
    try std.testing.expectEqual(@as(i32, 1), feedbackStatus[0]);
    gl.shaders.getParameter(feedbackFragment, gl.shaders.ShaderParameter.compile_status, &feedbackStatus);
    try std.testing.expectEqual(@as(i32, 1), feedbackStatus[0]);
    const feedbackProgram = gl.programs.create();
    gl.programs.attach(feedbackProgram, feedbackVertex);
    gl.programs.attach(feedbackProgram, feedbackFragment);
    gl.transform_feedback.varyings(feedbackProgram, &.{"out_data"}, gl.transform_feedback.BufferMode.interleaved_attribs);
    gl.programs.link(feedbackProgram);
    gl.programs.getParameter(feedbackProgram, gl.programs.ProgramParameter.link_status, &feedbackStatus);
    try std.testing.expectEqual(@as(i32, 1), feedbackStatus[0]);
    var feedbackObject: u32 = 0;
    gl.transform_feedback.gen(1, @ptrCast(&feedbackObject));
    gl.transform_feedback.bind(feedbackObject);
    try std.testing.expect(gl.transform_feedback.isTransformFeedback(feedbackObject));
    try std.testing.expect(!gl.transform_feedback.isTransformFeedback(0));
    // NOTE: transform feedback buffer bindings belong to the bound feedback
    // object, so the capture buffer is (re)bound only after the object.
    var feedbackBuffer: u32 = 0;
    gl.buffers.gen(1, @ptrCast(&feedbackBuffer));
    gl.buffers.bind(gl.buffers.BufferTarget.transform_feedback_buffer, feedbackBuffer);
    gl.buffers.bufferData(gl.buffers.BufferTarget.transform_feedback_buffer, 64, null, gl.buffers.BufferUsage.static_draw);
    gl.buffers.bindBase(gl.buffers.BufferTarget.transform_feedback_buffer, 0, feedbackBuffer);
    gl.state.enable(gl.state.Capability.rasterizer_discard);
    gl.programs.use(feedbackProgram);
    gl.transform_feedback.begin(gl.drawing.PrimitiveType.triangles);
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.drawing.drawArrays(gl.drawing.PrimitiveType.triangles, 0, 3);
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.transform_feedback.pause();
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.transform_feedback.resumeCapture();
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.transform_feedback.end();
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
    gl.state.disable(gl.state.Capability.rasterizer_discard);
    var varyingName: [64]u8 = undefined;
    const varyingInfo = gl.transform_feedback.getVarying(feedbackProgram, 0, &varyingName);
    try std.testing.expectEqual(@as(usize, 8), varyingInfo.name_length);
    try std.testing.expectEqualStrings("out_data", varyingName[0..8]);
    gl.transform_feedback.bind(0);
    gl.transform_feedback.delete(1, @ptrCast(&feedbackObject));
    gl.buffers.delete(1, @ptrCast(&feedbackBuffer));
    gl.programs.delete(feedbackProgram);
    gl.shaders.delete(feedbackVertex);
    gl.shaders.delete(feedbackFragment);
    setup.useSharedProgram();
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());

    const fence = gl.sync.fence(gl.sync.FenceCondition.sync_gpu_commands_complete, 0);
    try std.testing.expect(@intFromPtr(fence) != 0);
    try std.testing.expect(gl.sync.isSync(fence));
    var syncValues: [4]i32 = undefined;
    var syncLength: i32 = 0;
    gl.sync.getParameter(fence, gl.sync.SyncParameter.sync_status, 4, &syncLength, &syncValues);
    const waitResult = gl.sync.clientWait(fence, 0, 0);
    try std.testing.expect(waitResult != .wait_failed);
    gl.sync.wait(fence, 0, gl.sync.timeout_ignored);
    gl.sync.delete(fence);
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());

    if (gl.loader.context.is_es) {
        _ = try gl.loader.hasExtension("GL_KHR_debug");
    } else {
        try std.testing.expect(try gl.loader.hasExtension("GL_KHR_debug"));
    }

    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}
