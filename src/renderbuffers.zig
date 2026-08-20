//! Renderbuffer objects: renderable storage for framebuffer attachments.
//!
//! A renderbuffer is an image that cannot be sampled by shaders but can be
//! used as a framebuffer attachment (color, depth or stencil). Multisampled
//! storage is supported via [`storageMultisample`](storageMultisample).

const loader = @import("loader.zig");
const textures = @import("textures.zig");

/// The only binding point of a renderbuffer (`GL_RENDERBUFFER`).
pub const RenderbufferTarget = enum(u32) {
    /// General renderbuffer binding point (`GL_RENDERBUFFER`).
    renderbuffer = 0x8D41,
};

/// A parameter of a renderbuffer read via [`getParameter`](getParameter).
pub const RenderbufferParameter = enum(u32) {
    /// Width of the renderbuffer in pixels (`GL_RENDERBUFFER_WIDTH`).
    renderbuffer_width = 0x8D42,

    /// Height of the renderbuffer in pixels (`GL_RENDERBUFFER_HEIGHT`).
    renderbuffer_height = 0x8D43,

    /// Internal format of the renderbuffer
    /// ([`textures.InternalFormat`](textures.InternalFormat),
    /// `GL_RENDERBUFFER_INTERNAL_FORMAT`).
    renderbuffer_internal_format = 0x8D44,

    /// Resolution of the red component (`GL_RENDERBUFFER_RED_SIZE`).
    renderbuffer_red_size = 0x8D50,

    /// Resolution of the green component (`GL_RENDERBUFFER_GREEN_SIZE`).
    renderbuffer_green_size = 0x8D51,

    /// Resolution of the blue component (`GL_RENDERBUFFER_BLUE_SIZE`).
    renderbuffer_blue_size = 0x8D52,

    /// Resolution of the alpha component (`GL_RENDERBUFFER_ALPHA_SIZE`).
    renderbuffer_alpha_size = 0x8D53,

    /// Resolution of the depth component (`GL_RENDERBUFFER_DEPTH_SIZE`).
    renderbuffer_depth_size = 0x8D54,

    /// Resolution of the stencil component (`GL_RENDERBUFFER_STENCIL_SIZE`).
    renderbuffer_stencil_size = 0x8D55,

    /// Number of samples of the renderbuffer (`GL_RENDERBUFFER_SAMPLES`).
    renderbuffer_samples = 0x8CAB,
};

/// Generates `n` new renderbuffer names (port of `glGenRenderbuffers`).
///
/// Renderbuffer names do not become renderbuffers until first bound.
pub fn gen(n: i32, renderbuffers: [*]u32) void {
    loader.context.gen_renderbuffers(n, renderbuffers);
}

/// Deletes the given renderbuffers (port of `glDeleteRenderbuffers`).
pub fn delete(n: i32, renderbuffers: [*]const u32) void {
    loader.context.delete_renderbuffers(n, renderbuffers);
}

/// Returns whether `renderbuffer` is the name of an existing renderbuffer
/// (port of `glIsRenderbuffer`).
pub fn isRenderbuffer(renderbuffer: u32) bool {
    return loader.context.isRenderbuffer(renderbuffer) != 0;
}

/// Binds the renderbuffer to its binding point (port of `glBindRenderbuffer`).
pub fn bind(target: RenderbufferTarget, renderbuffer: u32) void {
    loader.context.bind_renderbuffer(@intFromEnum(target), renderbuffer);
}

/// Allocates the storage of the bound renderbuffer (port of
/// `glRenderbufferStorage`).
///
/// The format cannot be sampled directly; attach the renderbuffer to a
/// framebuffer with [`framebuffers.attachRenderbuffer`](framebuffers.attachRenderbuffer)
/// to render into it.
///
/// ```
/// gl.renderbuffers.storage(.renderbuffer, .depth24_stencil8, width, height);
/// ```
pub fn storage(
    target: RenderbufferTarget,
    internalformat: textures.InternalFormat,
    width: i32,
    height: i32,
) void {
    loader.context.renderbuffer_storage(
        @intFromEnum(target),
        @intFromEnum(internalformat),
        width,
        height,
    );
}

/// Allocates multisampled storage of the bound renderbuffer (port of
/// `glRenderbufferStorageMultisample`).
///
/// `samples` must not exceed `GL_MAX_SAMPLES`; resolving the multisampled
/// image into a texture is performed via
/// [`framebuffers.blit`](framebuffers.blit).
pub fn storageMultisample(
    target: RenderbufferTarget,
    samples: i32,
    internalformat: textures.InternalFormat,
    width: i32,
    height: i32,
) void {
    loader.context.renderbuffer_storage_multisample(
        @intFromEnum(target),
        samples,
        @intFromEnum(internalformat),
        width,
        height,
    );
}

/// Reads a parameter of the bound renderbuffer (port of
/// `glGetRenderbufferParameteriv`).
pub fn getParameter(target: RenderbufferTarget, pname: RenderbufferParameter, params: [*]i32) void {
    loader.context.get_renderbuffer_parameter_iv(@intFromEnum(target), @intFromEnum(pname), params);
}