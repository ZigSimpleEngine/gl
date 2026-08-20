//! Framebuffer objects: offscreen rendering targets.
//!
//! A framebuffer object collects color, depth and stencil images (textures
//! or renderbuffers) into a single rendering target. After setting up the
//! attachments with [`attachment_texture_2d`](attachment_texture_2d) and
//! checking completeness with [`checkStatus`](checkStatus), rendering can
//! be redirected with [`bind`](bind).

const loader = @import("loader.zig");
const enums = @import("enums.zig");
const textures = @import("textures.zig");

/// Binding point of a framebuffer (`GL_FRAMEBUFFER`,
/// `GL_DRAW_FRAMEBUFFER`, `GL_READ_FRAMEBUFFER`).
pub const FramebufferTarget = enum(u32) {
    /// Read and draw target at once (`GL_FRAMEBUFFER`).
    framebuffer = 0x8D40,

    /// Target of draw commands (`GL_DRAW_FRAMEBUFFER`).
    draw_framebuffer = 0x8CA9,

    /// Target of pixel readback commands (`GL_READ_FRAMEBUFFER`).
    read_framebuffer = 0x8CA8,
};

/// A color attachment point of a framebuffer, plus the depth and stencil
/// attachment points (`GL_COLOR_ATTACHMENT0`, `GL_DEPTH_ATTACHMENT`, ...).
pub const Attachment = enum(u32) {
    /// First color attachment (`GL_COLOR_ATTACHMENT0`).
    color_attachment0 = 0x8CE0,

    /// Second color attachment (`GL_COLOR_ATTACHMENT1`).
    color_attachment1 = 0x8CE1,

    /// Third color attachment (`GL_COLOR_ATTACHMENT2`).
    color_attachment2 = 0x8CE2,

    /// Fourth color attachment (`GL_COLOR_ATTACHMENT3`).
    color_attachment3 = 0x8CE3,

    /// Fifth color attachment (`GL_COLOR_ATTACHMENT4`).
    color_attachment4 = 0x8CE4,

    /// Sixth color attachment (`GL_COLOR_ATTACHMENT5`).
    color_attachment5 = 0x8CE5,

    /// Seventh color attachment (`GL_COLOR_ATTACHMENT6`).
    color_attachment6 = 0x8CE6,

    /// Eighth color attachment (`GL_COLOR_ATTACHMENT7`).
    color_attachment7 = 0x8CE7,

    /// Ninth color attachment (`GL_COLOR_ATTACHMENT8`).
    color_attachment8 = 0x8CE8,

    /// Tenth color attachment (`GL_COLOR_ATTACHMENT9`).
    color_attachment9 = 0x8CE9,

    /// Eleventh color attachment (`GL_COLOR_ATTACHMENT10`).
    color_attachment10 = 0x8CEA,

    /// Twelfth color attachment (`GL_COLOR_ATTACHMENT11`).
    color_attachment11 = 0x8CEB,

    /// Thirteenth color attachment (`GL_COLOR_ATTACHMENT12`).
    color_attachment12 = 0x8CEC,

    /// Fourteenth color attachment (`GL_COLOR_ATTACHMENT13`).
    color_attachment13 = 0x8CED,

    /// Fifteenth color attachment (`GL_COLOR_ATTACHMENT14`).
    color_attachment14 = 0x8CEE,

    /// Sixteenth color attachment (`GL_COLOR_ATTACHMENT15`).
    color_attachment15 = 0x8CEF,

    /// Depth attachment point (`GL_DEPTH_ATTACHMENT`).
    depth_attachment = 0x8D00,

    /// Stencil attachment point (`GL_STENCIL_ATTACHMENT`).
    stencil_attachment = 0x8D20,

    /// Combined depth and stencil attachment point
    /// (`GL_DEPTH_STENCIL_ATTACHMENT`).
    depth_stencil_attachment = 0x821A,
};

/// Status of a framebuffer after [`checkStatus`](checkStatus)
/// (`GL_FRAMEBUFFER_COMPLETE`, ...).
pub const FramebufferStatus = enum(u32) {
    /// The framebuffer is complete and can be used for rendering
    /// (`GL_FRAMEBUFFER_COMPLETE`).
    framebuffer_complete = 0x8CD5,

    /// An attachment's internal format is not supported
    /// (`GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT`).
    incomplete_attachment = 0x8CD6,

    /// The framebuffer has no attachments (`GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT`).
    incomplete_missing_attachment = 0x8CD7,

    /// Attachments have inconsistent dimensions
    /// (`GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS`).
    incomplete_dimensions = 0x8CD9,

    /// The combination of internal formats is not supported
    /// (`GL_FRAMEBUFFER_UNSUPPORTED`).
    unsupported = 0x8CDD,

    /// The default framebuffer does not exist (`GL_FRAMEBUFFER_UNDEFINED`).
    framebuffer_undefined = 0x8219,
};

/// An attachment parameter read via [`getAttachmentParameter`](getAttachmentParameter).
pub const AttachmentParameter = enum(u32) {
    /// Type of the attached object ([`AttachmentObjectType`](AttachmentObjectType),
    /// `GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE`).
    framebuffer_attachment_object_type = 0x8CD0,

    /// Name of the attached texture or renderbuffer
    /// (`GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME`).
    framebuffer_attachment_object_name = 0x8CD1,

    /// Mipmap level of the attached texture (`GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL`).
    framebuffer_attachment_texture_level = 0x8CD2,

    /// Cube map face of the attached texture
    /// (`GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE`).
    framebuffer_attachment_texture_cube_map_face = 0x8CD3,

    /// Texture layer of the attached texture
    /// (`GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER`).
    framebuffer_attachment_texture_layer = 0x8CD4,
};

/// Type of the object attached to a framebuffer attachment point.
pub const AttachmentObjectType = enum(u32) {
    /// No object is attached (`GL_NONE`).
    none = 0x0000,

    /// A texture is attached (`GL_TEXTURE`).
    texture = 0x1702,

    /// A renderbuffer is attached (`GL_RENDERBUFFER`).
    renderbuffer = 0x8D55,
};

/// A destination buffer of a draw call, used with [`drawBuffers`](drawBuffers)
/// (`GL_NONE`, `GL_BACK`, `GL_COLOR_ATTACHMENTi`).
pub const DrawBuffer = enum(u32) {
    /// Fragment output is discarded (`GL_NONE`).
    none = 0x0000,

    /// The back buffer of the default framebuffer (`GL_BACK`).
    back = 0x0405,

    /// First color attachment (`GL_COLOR_ATTACHMENT0`).
    color_attachment0 = 0x8CE0,

    /// Second color attachment (`GL_COLOR_ATTACHMENT1`).
    color_attachment1 = 0x8CE1,

    /// Third color attachment (`GL_COLOR_ATTACHMENT2`).
    color_attachment2 = 0x8CE2,

    /// Fourth color attachment (`GL_COLOR_ATTACHMENT3`).
    color_attachment3 = 0x8CE3,

    /// Fifth color attachment (`GL_COLOR_ATTACHMENT4`).
    color_attachment4 = 0x8CE4,

    /// Sixth color attachment (`GL_COLOR_ATTACHMENT5`).
    color_attachment5 = 0x8CE5,

    /// Seventh color attachment (`GL_COLOR_ATTACHMENT6`).
    color_attachment6 = 0x8CE6,

    /// Eighth color attachment (`GL_COLOR_ATTACHMENT7`).
    color_attachment7 = 0x8CE7,

    /// Ninth color attachment (`GL_COLOR_ATTACHMENT8`).
    color_attachment8 = 0x8CE8,

    /// Tenth color attachment (`GL_COLOR_ATTACHMENT9`).
    color_attachment9 = 0x8CE9,

    /// Eleventh color attachment (`GL_COLOR_ATTACHMENT10`).
    color_attachment10 = 0x8CEA,

    /// Twelfth color attachment (`GL_COLOR_ATTACHMENT11`).
    color_attachment11 = 0x8CEB,

    /// Thirteenth color attachment (`GL_COLOR_ATTACHMENT12`).
    color_attachment12 = 0x8CEC,

    /// Fourteenth color attachment (`GL_COLOR_ATTACHMENT13`).
    color_attachment13 = 0x8CED,

    /// Fifteenth color attachment (`GL_COLOR_ATTACHMENT14`).
    color_attachment14 = 0x8CEE,

    /// Sixteenth color attachment (`GL_COLOR_ATTACHMENT15`).
    color_attachment15 = 0x8CEF,
};

/// Filter used by [`blit`](blit) when the source and destination rectangles
/// differ in size (`GL_NEAREST`, `GL_LINEAR`).
pub const BlitFilter = enum(u32) {
    /// Nearest-neighbor filtering (`GL_NEAREST`).
    nearest = 0x2600,

    /// Bilinear filtering (`GL_LINEAR`).
    linear = 0x2601,
};

/// Generates `n` new framebuffer names (port of `glGenFramebuffers`).
///
/// Framebuffer names do not become framebuffers until first bound.
///
/// ```
/// var fbo: u32 = 0;
/// gl.framebuffers.gen(1, &fbo);
/// ```
pub fn gen(n: i32, framebuffers: [*]u32) void {
    loader.context.gen_framebuffers(n, framebuffers);
}

/// Deletes the given framebuffers (port of `glDeleteFramebuffers`).
pub fn delete(n: i32, framebuffers: [*]const u32) void {
    loader.context.delete_framebuffers(n, framebuffers);
}

/// Returns whether `framebuffer` is the name of an existing framebuffer
/// (port of `glIsFramebuffer`).
pub fn isFramebuffer(framebuffer: u32) bool {
    return loader.context.isFramebuffer(framebuffer) != 0;
}

/// Binds the framebuffer to the given target (port of `glBindFramebuffer`).
///
/// With [`FramebufferTarget.framebuffer`](FramebufferTarget.framebuffer) the
/// framebuffer is bound for both drawing and reading. Binding name `0`
/// restores the default framebuffer.
pub fn bind(target: FramebufferTarget, framebuffer: u32) void {
    loader.context.bind_framebuffer(@intFromEnum(target), framebuffer);
}

/// Returns the completeness status of the bound framebuffer (port of
/// `glCheckFramebufferStatus`).
///
/// Must be [`FramebufferStatus.framebuffer_complete`](FramebufferStatus.framebuffer_complete)
/// before rendering into the framebuffer; otherwise draw commands are
/// ignored and `GL_INVALID_FRAMEBUFFER_OPERATION` is generated.
pub fn checkStatus(target: FramebufferTarget) FramebufferStatus {
    return @enumFromInt(loader.context.check_framebuffer_status(@intFromEnum(target)));
}

/// Attaches a renderbuffer to an attachment point of the bound framebuffer
/// (port of `glFramebufferRenderbuffer`).
pub fn attachRenderbuffer(
    target: FramebufferTarget,
    attachment: Attachment,
    renderbuffer: u32,
) void {
    loader.context.framebuffer_renderbuffer(
        @intFromEnum(target),
        @intFromEnum(attachment),
        0x8D41, // GL_RENDERBUFFER
        renderbuffer,
    );
}

/// Attaches a 2D texture image (or cube map face) to an attachment point of
/// the bound framebuffer (port of `glFramebufferTexture2D`).
///
/// `textarget` selects `GL_TEXTURE_2D` or one of the cube map faces;
/// `level` is the mipmap level to attach.
///
/// ```
/// gl.framebuffers.attachTexture2d(.framebuffer, .color_attachment0, .texture_2d, fbo_tex, 0);
/// ```
pub fn attachTexture2d(
    target: FramebufferTarget,
    attachment: Attachment,
    textarget: textures.TextureTarget,
    texture: u32,
    level: i32,
) void {
    loader.context.framebuffer_texture_2d(
        @intFromEnum(target),
        @intFromEnum(attachment),
        @intFromEnum(textarget),
        texture,
        level,
    );
}

/// Attaches a single layer of a 3D or array texture to an attachment point
/// (port of `glFramebufferTextureLayer`).
pub fn attachTextureLayer(
    target: FramebufferTarget,
    attachment: Attachment,
    texture: u32,
    level: i32,
    layer: i32,
) void {
    loader.context.framebuffer_texture_layer(
        @intFromEnum(target),
        @intFromEnum(attachment),
        texture,
        level,
        layer,
    );
}

/// Reads a parameter of the given attachment of the bound framebuffer
/// (port of `glGetFramebufferAttachmentParameteriv`).
pub fn getAttachmentParameter(
    target: FramebufferTarget,
    attachment: Attachment,
    pname: AttachmentParameter,
    params: [*]i32,
) void {
    loader.context.get_framebuffer_attachment_parameter_iv(
        @intFromEnum(target),
        @intFromEnum(attachment),
        @intFromEnum(pname),
        params,
    );
}

/// Copies a rectangle of pixels between framebuffers (port of
/// `glBlitFramebuffer`).
///
/// The source is the framebuffer bound to `GL_READ_FRAMEBUFFER`, the
/// destination — the one bound to `GL_DRAW_FRAMEBUFFER`. `mask` selects the
/// buffers to copy ([`enums.BufferMask`](enums.BufferMask)); when sample
/// counts differ, a resolve is performed instead of a copy.
pub fn blit(
    src_x0: i32,
    src_y0: i32,
    src_x1: i32,
    src_y1: i32,
    dst_x0: i32,
    dst_y0: i32,
    dst_x1: i32,
    dst_y1: i32,
    mask: enums.BufferMask,
    filter: BlitFilter,
) void {
    loader.context.blit_framebuffer(
        src_x0,
        src_y0,
        src_x1,
        src_y1,
        dst_x0,
        dst_y0,
        dst_x1,
        dst_y1,
        mask.bits(),
        @intFromEnum(filter),
    );
}

/// Selects the color buffers that fragment outputs are written to (port of
/// `glDrawBuffers`).
///
/// The i-th element of `bufs` selects the destination of the i-th fragment
/// shader output; a [`DrawBuffer.none`](DrawBuffer.none) discards the output.
///
/// ```
/// gl.framebuffers.drawBuffers(&.{ .color_attachment0, .color_attachment1 });
/// ```
pub fn drawBuffers(bufs: []const DrawBuffer) void {
    loader.context.drawBuffers(@intCast(bufs.len), @ptrCast(bufs.ptr));
}

/// Discards the contents of the given attachments of the bound framebuffer
/// (port of `glInvalidateFramebuffer`).
///
/// `attachments` holds raw `GLenum` values: `GL_COLOR`, `GL_DEPTH`,
/// `GL_STENCIL`, `GL_DEPTH_STENCIL` or `GL_COLOR_ATTACHMENTi`.
pub fn invalidate(target: FramebufferTarget, attachments: []const u32) void {
    loader.context.invalidate_framebuffer(@intFromEnum(target), @intCast(attachments.len), attachments.ptr);
}

/// Discards the contents of the given attachments within a rectangle
/// (port of `glInvalidateSubFramebuffer`).
pub fn invalidateSub(
    target: FramebufferTarget,
    attachments: []const u32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) void {
    loader.context.invalidate_sub_framebuffer(
        @intFromEnum(target),
        @intCast(attachments.len),
        attachments.ptr,
        x,
        y,
        width,
        height,
    );
}