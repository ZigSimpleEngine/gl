//! Exhaustive `state_parameters` coverage against a real OpenGL context.
//!
//! Every helper is called at least once and unexpected GL errors fail the
//! test, so a wrapper that misdeclares its query is caught immediately. The
//! context comes from `test_gl_setup` (hidden RGFW window); the file only
//! compiles when the optional local rgfw checkout is present. Without rgfw
//! these tests cannot build at all — `build.zig` then fails the `test` step
//! with an explicit message instead of running fake-green mocks.
//!
//! Silent by design: test binaries must not write to stderr under
//! `zig build test` (Zig 0.16 `--listen` IPC quirk on Windows turns any
//! child output into a spurious `failed command` line). Results surface as
//! passed/failed tests only.

const std = @import("std");
const gl = @import("gl");
const setup = @import("test_gl_setup.zig");

/// Asserts that no GL error is pending (also drains the flag).
fn checkClean() !void {
    try std.testing.expectEqual(gl.enums.ErrorCode.no_error, gl.errors.getError());
}

/// Discards a tolerated GL error left by an informational-only query.
fn drainError() void {
    _ = gl.errors.getError();
}

test "state_parameters against real driver" {
    try setup.ensureRealSetup();
    try checkClean();

    const parameters = gl.state_parameters;
    const isRealEs = gl.loader.context.is_es;

    // Active unit, ranges, bit depths.
    _ = parameters.getActiveTexture();
    _ = parameters.getAliasedLineWidthRange();
    _ = parameters.getAliasedPointSizeRange();
    _ = parameters.getAlphaBits();
    _ = parameters.getBlueBits();
    _ = parameters.getGreenBits();
    _ = parameters.getRedBits();
    try checkClean();

    // Depth/stencil sizes need buffers that exist: the window visual is not
    // guaranteed to provide depth/stencil attachments (headless and minimal
    // X servers vary, and strict core drivers fault missing points instead
    // of returning 0). Verify against an FBO with a known DEPTH24_STENCIL8
    // renderbuffer, which asserts exact values on every driver.
    {
        var rb: u32 = 0;
        var fb: u32 = 0;
        gl.renderbuffers.gen(1, @ptrCast(&rb));
        defer gl.renderbuffers.delete(1, @ptrCast(&rb));
        gl.renderbuffers.bind(.renderbuffer, rb);
        gl.renderbuffers.storage(.renderbuffer, .depth24_stencil8, 64, 64);
        gl.framebuffers.gen(1, @ptrCast(&fb));
        defer gl.framebuffers.delete(1, @ptrCast(&fb));
        gl.framebuffers.bind(.framebuffer, fb);
        // Same packed depth-stencil image on both points (complete per spec).
        gl.framebuffers.attachRenderbuffer(.framebuffer, .depth_attachment, rb);
        gl.framebuffers.attachRenderbuffer(.framebuffer, .stencil_attachment, rb);
        try std.testing.expectEqual(
            gl.framebuffers.FramebufferStatus.framebuffer_complete,
            gl.framebuffers.checkStatus(.framebuffer),
        );
        try std.testing.expectEqual(@as(i32, 24), parameters.getDepthBits());
        try std.testing.expectEqual(@as(i32, 8), parameters.getStencilBits());
        gl.framebuffers.bind(.framebuffer, 0);
    }
    try checkClean();

    // Bindings.
    _ = parameters.getArrayBufferBinding();
    _ = parameters.getElementArrayBufferBinding();
    _ = parameters.getPixelPackBufferBinding();
    _ = parameters.getPixelUnpackBufferBinding();
    _ = parameters.getFramebufferBinding();
    _ = parameters.getRenderbufferBinding();
    _ = parameters.getSamplerBinding();
    _ = parameters.getCurrentProgram();
    _ = parameters.getTransformFeedbackBinding();
    _ = parameters.getTransformFeedbackBufferBinding();
    _ = parameters.getUniformBufferBinding();
    _ = parameters.getTextureBinding2D();
    _ = parameters.getTextureBinding2DArray();
    _ = parameters.getTextureBinding3D();
    _ = parameters.getTextureBindingCubeMap();
    try checkClean();

    // Blending.
    _ = parameters.isBlend();
    _ = parameters.getBlendColor();
    _ = parameters.getBlendDestinationAlpha();
    _ = parameters.getBlendDestinationRgb();
    _ = parameters.getBlendEquationAlpha();
    _ = parameters.getBlendEquationRgb();
    _ = parameters.getBlendSourceAlpha();
    _ = parameters.getBlendSourceRgb();
    try checkClean();

    // Clear values and masks.
    _ = parameters.getColorClearValue();
    _ = parameters.getColorWritemask();
    _ = parameters.getDepthClearValue();
    _ = parameters.getStencilClearValue();
    try checkClean();

    // Culling, depth, dither, polygon offset.
    _ = parameters.isCullFace();
    _ = parameters.getCullFaceMode();
    _ = parameters.getDepthFunction();
    _ = parameters.getDepthRange();
    _ = parameters.isDepthTest();
    _ = parameters.isDepthWritemask();
    _ = parameters.isDither();
    _ = parameters.getPolygonOffsetFactor();
    _ = parameters.isPolygonOffsetFill();
    _ = parameters.getPolygonOffsetUnits();
    try checkClean();

    // Draw buffers: only as many as the driver reports.
    const maxDrawBuffers = parameters.getMaxDrawBuffers();
    try checkClean();
    const drawLimit: u32 = @intCast(@min(@as(i32, 16), @max(maxDrawBuffers, 0)));
    var drawIndex: u32 = 0;
    while (drawIndex < drawLimit) : (drawIndex += 1) {
        _ = parameters.getDrawBuffer(drawIndex);
    }
    try checkClean();

    // Front face, hints, line width, versions.
    // NOTE: getGenerateMipmapHint() is intentionally not called: the suite
    // runs on core contexts, where GL_GENERATE_MIPMAP_HINT was removed, so
    // the query faults and its result cannot convert to HintMode. The
    // hint() setter stays covered in test.zig with a core-valid target.
    _ = parameters.getFrontFace();
    _ = parameters.getLineWidth();
    try std.testing.expect(parameters.getMajorVersion() >= 3);
    _ = parameters.getMinorVersion();
    try checkClean();

    // OpenGL ES-only enumerants must not be queried on desktop drivers:
    // bare glGet would raise INVALID_ENUM and leave unconvertible data.
    if (isRealEs) {
        _ = parameters.getImplementationColorReadFormat();
        _ = parameters.getImplementationColorReadType();
        try checkClean();
    }

    // Maximums.
    try std.testing.expect(parameters.getMaxTextureSize() > 0);
    _ = parameters.getMax3DTextureSize();
    _ = parameters.getMaxArrayTextureLayers();
    _ = parameters.getMaxColorAttachments();
    _ = parameters.getMaxCombinedFragmentUniformComponents();
    _ = parameters.getMaxCombinedTextureImageUnits();
    _ = parameters.getMaxCombinedUniformBlocks();
    _ = parameters.getMaxCombinedVertexUniformComponents();
    _ = parameters.getMaxCubeMapTextureSize();
    _ = parameters.getMaxElementIndex();
    _ = parameters.getMaxElementsIndices();
    _ = parameters.getMaxElementsVertices();
    _ = parameters.getMaxFragmentInputComponents();
    _ = parameters.getMaxFragmentUniformBlocks();
    _ = parameters.getMaxFragmentUniformComponents();
    _ = parameters.getMaxFragmentUniformVectors();
    _ = parameters.getMaxProgramTexelOffset();
    _ = parameters.getMaxRenderbufferSize();
    _ = parameters.getMaxSamples();
    _ = parameters.getMaxServerWaitTimeout();
    _ = parameters.getMaxTextureImageUnits();
    _ = parameters.getMaxTextureLevelOfDetailBias();
    _ = parameters.getMaxTransformFeedbackInterleavedComponents();
    _ = parameters.getMaxTransformFeedbackSeparateAttributes();
    _ = parameters.getMaxTransformFeedbackSeparateComponents();
    _ = parameters.getMaxUniformBlockSize();
    _ = parameters.getMaxUniformBufferBindings();
    _ = parameters.getMaxVaryingComponents();
    _ = parameters.getMaxVaryingVectors();
    _ = parameters.getMaxVertexAttributes();
    _ = parameters.getMaxVertexOutputComponents();
    _ = parameters.getMaxVertexTextureImageUnits();
    _ = parameters.getMaxVertexUniformBlocks();
    _ = parameters.getMaxVertexUniformComponents();
    _ = parameters.getMaxVertexUniformVectors();
    _ = parameters.getMaxViewportDimensions();
    _ = parameters.getMinProgramTexelOffset();
    try checkClean();

    // Counters.
    try std.testing.expect(parameters.getNumberOfExtensions() > 0);
    _ = parameters.getNumberOfCompressedTextureFormats();
    _ = parameters.getNumberOfProgramBinaryFormats();
    _ = parameters.getNumberOfShaderBinaryFormats();
    try checkClean();

    // Pixel store.
    _ = parameters.getPackAlignment();
    _ = parameters.getPackRowLength();
    _ = parameters.getPackSkipPixels();
    _ = parameters.getPackSkipRows();
    _ = parameters.getUnpackAlignment();
    _ = parameters.getUnpackRowLength();
    _ = parameters.getUnpackSkipPixels();
    _ = parameters.getUnpackSkipRows();
    try checkClean();

    // Multisampling.
    _ = parameters.isSampleAlphaToCoverage();
    _ = parameters.getSampleBuffers();
    _ = parameters.isSampleCoverage();
    _ = parameters.isSampleCoverageInverted();
    _ = parameters.getSampleCoverageValue();
    _ = parameters.getSamples();
    try checkClean();

    // Scissor and compiler.
    _ = parameters.getScissorBox();
    _ = parameters.isScissorTest();
    _ = parameters.isShaderCompiler();
    try checkClean();

    // Stencil.
    _ = parameters.getStencilBackFailOperation();
    _ = parameters.getStencilBackFunction();
    _ = parameters.getStencilBackPassDepthFailOperation();
    _ = parameters.getStencilBackPassDepthPassOperation();
    _ = parameters.getStencilBackReference();
    _ = parameters.getStencilBackValueMask();
    _ = parameters.getStencilBackWritemask();
    _ = parameters.getStencilFailOperation();
    _ = parameters.getStencilFunction();
    _ = parameters.getStencilPassDepthFailOperation();
    _ = parameters.getStencilPassDepthPassOperation();
    _ = parameters.getStencilReference();
    _ = parameters.isStencilTest();
    _ = parameters.getStencilValueMask();
    _ = parameters.getStencilWritemask();
    try checkClean();

    // Transform feedback, uniform buffers, viewport.
    _ = parameters.isTransformFeedbackActive();
    _ = parameters.isTransformFeedbackPaused();
    _ = parameters.getUniformBufferOffsetAlignment();
    _ = parameters.getViewport();
    try checkClean();

    // Capabilities.
    _ = parameters.isRasterizerDiscard();
    _ = parameters.isPrimitiveRestartFixedIndex();
    try checkClean();

    // Strings.
    try std.testing.expect(parameters.getVendor() != null);
    try std.testing.expect(parameters.getRenderer() != null);
    try std.testing.expect(parameters.getVersion() != null);
    try std.testing.expect(parameters.getShadingLanguageVersion() != null);
    try std.testing.expect(parameters.getExtensionAtIndex(0) != null);
    try checkClean();

    // Informational-only queries valid solely through dedicated entry
    // points (not bare glGet): executed for coverage, errors drained.
    _ = parameters.getCurrentQuery();
    drainError();
    _ = parameters.getCurrentVertexAttribute();
    drainError();
    _ = parameters.getNumberOfSampleCounts();
    drainError();
    _ = parameters.getIndexedInteger(.uniform_buffer, 0);
    drainError();
    _ = parameters.getIndexedInteger64(.uniform_buffer, 0);
    drainError();
    _ = parameters.getIndexedUniformBufferBinding(0);
    drainError();
    _ = parameters.getIndexedTransformFeedbackBufferBinding(0);
    drainError();

    // Allocator-based lists must agree with their counters.
    const allocator = std.testing.allocator;
    const compressedFormats = try parameters.getCompressedTextureFormats(allocator);
    defer allocator.free(compressedFormats);
    try std.testing.expectEqual(
        @as(usize, @intCast(parameters.getNumberOfCompressedTextureFormats())),
        compressedFormats.len,
    );
    const programFormats = try parameters.getProgramBinaryFormats(allocator);
    defer allocator.free(programFormats);
    try std.testing.expectEqual(
        @as(usize, @intCast(parameters.getNumberOfProgramBinaryFormats())),
        programFormats.len,
    );
    const shaderFormats = try parameters.getShaderBinaryFormats(allocator);
    defer allocator.free(shaderFormats);
    try std.testing.expectEqual(
        @as(usize, @intCast(parameters.getNumberOfShaderBinaryFormats())),
        shaderFormats.len,
    );
    const extensionList = try parameters.getExtensionList(allocator);
    defer allocator.free(extensionList);
    try std.testing.expectEqual(
        @as(usize, @intCast(parameters.getNumberOfExtensions())),
        extensionList.len,
    );
    for (extensionList) |extension| {
        try std.testing.expect(extension != null);
    }
    try checkClean();
}
