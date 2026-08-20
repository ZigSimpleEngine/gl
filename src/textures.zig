//! Texture objects: image storage, sampling parameters and mipmaps.
//!
//! Textures are GPU-side images sampled by shaders. This namespace covers
//! their creation, deletion, binding, data upload ([`image2d`](image2d),
//! [`storage2d`](storage2d)) and configuration of sampling behavior
//! ([`parameterI`](parameterI) and friends).

const loader = @import("loader.zig");
const enums = @import("enums.zig");

/// Binding point (target) of a texture (`GL_TEXTURE_2D`, `GL_TEXTURE_3D`,
/// ...).
pub const TextureTarget = enum(u32) {
    /// Two-dimensional texture (`GL_TEXTURE_2D`).
    texture_2d = 0x0DE1,

    /// Three-dimensional texture (`GL_TEXTURE_3D`).
    texture_3d = 0x806F,

    /// Array of 2D texture layers with a shared size (`GL_TEXTURE_2D_ARRAY`).
    texture_2d_array = 0x8C1A,

    /// Cube map texture: six 2D faces (`GL_TEXTURE_CUBE_MAP`).
    texture_cube_map = 0x8513,

    /// Positive X face of a cube map (`GL_TEXTURE_CUBE_MAP_POSITIVE_X`).
    cube_map_positive_x = 0x8515,

    /// Negative X face of a cube map (`GL_TEXTURE_CUBE_MAP_NEGATIVE_X`).
    cube_map_negative_x = 0x8516,

    /// Positive Y face of a cube map (`GL_TEXTURE_CUBE_MAP_POSITIVE_Y`).
    cube_map_positive_y = 0x8517,

    /// Negative Y face of a cube map (`GL_TEXTURE_CUBE_MAP_NEGATIVE_Y`).
    cube_map_negative_y = 0x8518,

    /// Positive Z face of a cube map (`GL_TEXTURE_CUBE_MAP_POSITIVE_Z`).
    cube_map_positive_z = 0x8519,

    /// Negative Z face of a cube map (`GL_TEXTURE_CUBE_MAP_NEGATIVE_Z`).
    cube_map_negative_z = 0x851A,
};

/// Sized internal format of a texture or renderbuffer
/// (`GL_RGBA8`, `GL_DEPTH24_STENCIL8`, `GL_COMPRESSED_RGB8_ETC2`, ...).
///
/// Determines how texel data is stored and interpreted on the GPU.
pub const InternalFormat = enum(u32) {
    /// 8-bit red (`GL_R8`).
    r8 = 0x8229,

    /// 8-bit red, signed normalized (`GL_R8_SNORM`).
    r8_snorm = 0x8F94,

    /// 16-bit red (`GL_R16F`).
    r16f = 0x822D,

    /// 32-bit red, floating point (`GL_R32F`).
    r32f = 0x822E,

    /// 8-bit red integer (`GL_R8I`).
    r8i = 0x8231,

    /// 8-bit red unsigned integer (`GL_R8UI`).
    r8ui = 0x8232,

    /// 16-bit red integer (`GL_R16I`).
    r16i = 0x8233,

    /// 16-bit red unsigned integer (`GL_R16UI`).
    r16ui = 0x8234,

    /// 32-bit red integer (`GL_R32I`).
    r32i = 0x8235,

    /// 32-bit red unsigned integer (`GL_R32UI`).
    r32ui = 0x8236,

    /// 8-bit red-green (`GL_RG8`).
    rg8 = 0x822B,

    /// 8-bit red-green, signed normalized (`GL_RG8_SNORM`).
    rg8_snorm = 0x8F95,

    /// 16-bit red-green, floating point (`GL_RG16F`).
    rg16f = 0x822F,

    /// 32-bit red-green, floating point (`GL_RG32F`).
    rg32f = 0x8230,

    /// 8-bit red-green integer (`GL_RG8I`).
    rg8i = 0x8237,

    /// 8-bit red-green unsigned integer (`GL_RG8UI`).
    rg8ui = 0x8238,

    /// 16-bit red-green integer (`GL_RG16I`).
    rg16i = 0x8239,

    /// 16-bit red-green unsigned integer (`GL_RG16UI`).
    rg16ui = 0x823A,

    /// 32-bit red-green integer (`GL_RG32I`).
    rg32i = 0x823B,

    /// 32-bit red-green unsigned integer (`GL_RG32UI`).
    rg32ui = 0x823C,

    /// 8-bit RGB (`GL_RGB8`).
    rgb8 = 0x8051,

    /// 8-bit RGB, signed normalized (`GL_RGB8_SNORM`).
    rgb8_snorm = 0x8F96,

    /// 5-6-5 bit RGB (`GL_RGB565`).
    rgb565 = 0x8D62,

    /// RGB with shared exponent, 5/9/9/9 (`GL_RGB9_E5`).
    rgb9_e5 = 0x8C3D,

    /// 11-11-10 bit unsigned floating point (`GL_R11F_G11F_B10F`).
    r11f_g11f_b10f = 0x8C3A,

    /// 8-bit RGB integer (`GL_RGB8I`).
    rgb8i = 0x8D8F,

    /// 8-bit RGB unsigned integer (`GL_RGB8UI`).
    rgb8ui = 0x8D7D,

    /// 16-bit RGB integer (`GL_RGB16I`).
    rgb16i = 0x8D89,

    /// 16-bit RGB unsigned integer (`GL_RGB16UI`).
    rgb16ui = 0x8D77,

    /// 32-bit RGB integer (`GL_RGB32I`).
    rgb32i = 0x8D83,

    /// 32-bit RGB unsigned integer (`GL_RGB32UI`).
    rgb32ui = 0x8D71,

    /// 8-bit RGBA (`GL_RGBA8`).
    rgba8 = 0x8058,

    /// 8-bit RGBA, signed normalized (`GL_RGBA8_SNORM`).
    rgba8_snorm = 0x8F97,

    /// 4-bit RGBA (`GL_RGBA4`).
    rgba4 = 0x8056,

    /// 5-5-5-1 bit RGBA (`GL_RGB5_A1`).
    rgb5_a1 = 0x8057,

    /// 10-10-10-2 bit RGBA (`GL_RGB10_A2`).
    rgb10_a2 = 0x8059,

    /// 10-10-10-2 bit RGBA unsigned integer (`GL_RGB10_A2UI`).
    rgb10_a2ui = 0x906F,

    /// 16-bit RGBA, floating point (`GL_RGBA16F`).
    rgba16f = 0x881A,

    /// 32-bit RGBA, floating point (`GL_RGBA32F`).
    rgba32f = 0x8814,

    /// 8-bit RGBA integer (`GL_RGBA8I`).
    rgba8i = 0x8D8E,

    /// 8-bit RGBA unsigned integer (`GL_RGBA8UI`).
    rgba8ui = 0x8D8C,

    /// 16-bit RGBA integer (`GL_RGBA16I`).
    rgba16i = 0x8D88,

    /// 16-bit RGBA unsigned integer (`GL_RGBA16UI`).
    rgba16ui = 0x8D8A,

    /// 32-bit RGBA integer (`GL_RGBA32I`).
    rgba32i = 0x8D82,

    /// 32-bit RGBA unsigned integer (`GL_RGBA32UI`).
    rgba32ui = 0x8D70,

    /// sRGB 8-bit (`GL_SRGB8`).
    srgb8 = 0x8C41,

    /// sRGB 8-bit with alpha (`GL_SRGB8_ALPHA8`).
    srgb8_alpha8 = 0x8C43,

    /// 16-bit normalized depth (`GL_DEPTH_COMPONENT16`).
    depth_component16 = 0x81A5,

    /// 24-bit normalized depth (`GL_DEPTH_COMPONENT24`).
    depth_component24 = 0x81A6,

    /// 32-bit floating point depth (`GL_DEPTH_COMPONENT32F`).
    depth_component32f = 0x8CAC,

    /// 24-bit depth with 8-bit stencil (`GL_DEPTH24_STENCIL8`).
    depth24_stencil8 = 0x88F0,

    /// 32-bit floating point depth with 8-bit stencil
    /// (`GL_DEPTH32F_STENCIL8`).
    depth32f_stencil8 = 0x8CAD,

    /// 8-bit red, EAC compressed (`GL_COMPRESSED_R11_EAC`).
    compressed_r11_eac = 0x9270,

    /// 8-bit signed red, EAC compressed (`GL_COMPRESSED_SIGNED_R11_EAC`).
    compressed_signed_r11_eac = 0x9271,

    /// 16-bit red-green, EAC compressed (`GL_COMPRESSED_RG11_EAC`).
    compressed_rg11_eac = 0x9272,

    /// 16-bit signed red-green, EAC compressed
    /// (`GL_COMPRESSED_SIGNED_RG11_EAC`).
    compressed_signed_rg11_eac = 0x9273,

    /// 8-bit RGB, ETC2 compressed (`GL_COMPRESSED_RGB8_ETC2`).
    compressed_rgb8_etc2 = 0x9274,

    /// 8-bit sRGB, ETC2 compressed (`GL_COMPRESSED_SRGB8_ETC2`).
    compressed_srgb8_etc2 = 0x9275,

    /// 8-bit RGB with punch-through alpha, ETC2 compressed
    /// (`GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2`).
    compressed_rgb8_punchthrough_alpha1_etc2 = 0x9276,

    /// 8-bit sRGB with punch-through alpha, ETC2 compressed
    /// (`GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2`).
    compressed_srgb8_punchthrough_alpha1_etc2 = 0x9277,

    /// 8-bit RGBA, ETC2/EAC compressed (`GL_COMPRESSED_RGBA8_ETC2_EAC`).
    compressed_rgba8_etc2_eac = 0x9278,

    /// 8-bit sRGB with alpha, ETC2/EAC compressed
    /// (`GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC`).
    compressed_srgb8_alpha8_etc2_eac = 0x9279,
};

/// Base (unsized) pixel format of transferred texel data
/// (`GL_RGB`, `GL_RGBA`, ...).
pub const PixelFormat = enum(u32) {
    /// Single red component (`GL_RED`).
    red = 0x1903,

    /// Red and green components (`GL_RG`).
    rg = 0x8227,

    /// Red, green and blue components (`GL_RGB`).
    rgb = 0x1907,

    /// Red, green, blue and alpha components (`GL_RGBA`).
    rgba = 0x1908,

    /// Depth component (`GL_DEPTH_COMPONENT`).
    depth_component = 0x1902,

    /// Depth and stencil components (`GL_DEPTH_STENCIL`).
    depth_stencil = 0x84F9,

    /// Legacy luminance format (`GL_LUMINANCE`).
    luminance = 0x1909,

    /// Legacy luminance with alpha format (`GL_LUMINANCE_ALPHA`).
    luminance_alpha = 0x190A,

    /// Legacy alpha-only format (`GL_ALPHA`).
    alpha = 0x1906,
};

/// Sampling parameter of a texture, read via [`getParameterI`](getParameterI)
/// and set via [`parameterI`](parameterI) (`GL_TEXTURE_MIN_FILTER`,
/// `GL_TEXTURE_WRAP_S`, ...).
pub const TextureParameter = enum(u32) {
    /// Minification filter (downscaling, `GL_TEXTURE_MIN_FILTER`).
    texture_min_filter = 0x2801,

    /// Magnification filter (upscaling, `GL_TEXTURE_MAG_FILTER`).
    texture_mag_filter = 0x2800,

    /// Wrapping mode on the S axis (`GL_TEXTURE_WRAP_S`).
    texture_wrap_s = 0x2802,

    /// Wrapping mode on the T axis (`GL_TEXTURE_WRAP_T`).
    texture_wrap_t = 0x2803,

    /// Wrapping mode on the R axis (3D textures, `GL_TEXTURE_WRAP_R`).
    texture_wrap_r = 0x8072,

    /// Comparison mode for depth textures ([`CompareMode`](CompareMode),
    /// `GL_TEXTURE_COMPARE_MODE`).
    texture_compare_mode = 0x884C,

    /// Comparison function for depth textures
    /// ([`enums.Comparison`](enums.Comparison), `GL_TEXTURE_COMPARE_FUNC`).
    texture_compare_func = 0x884D,

    /// Index of the base (most detailed) mipmap level (`GL_TEXTURE_BASE_LEVEL`).
    texture_base_level = 0x813C,

    /// Index of the highest mipmap level (`GL_TEXTURE_MAX_LEVEL`).
    texture_max_level = 0x813D,

    /// Minimum level-of-detail parameter; limits the selection of the
    /// highest-resolution mipmap (lowest mipmap level). Initial value -1000
    /// (`GL_TEXTURE_MIN_LOD`).
    texture_min_lod = 0x813A,

    /// Maximum level-of-detail parameter; limits the selection of the
    /// lowest-resolution mipmap (highest mipmap level). Initial value 1000
    /// (`GL_TEXTURE_MAX_LOD`).
    texture_max_lod = 0x813B,

    /// Swizzle of the R channel ([`Swizzle`](Swizzle), `GL_TEXTURE_SWIZZLE_R`).
    texture_swizzle_r = 0x8E42,

    /// Swizzle of the G channel ([`Swizzle`](Swizzle), `GL_TEXTURE_SWIZZLE_G`).
    texture_swizzle_g = 0x8E43,

    /// Swizzle of the B channel ([`Swizzle`](Swizzle), `GL_TEXTURE_SWIZZLE_B`).
    texture_swizzle_b = 0x8E44,

    /// Swizzle of the A channel ([`Swizzle`](Swizzle), `GL_TEXTURE_SWIZZLE_A`).
    texture_swizzle_a = 0x8E45,
};

/// Minification filter selecting the sampling behavior when the texture is
/// scaled down (`GL_NEAREST`, `GL_LINEAR_MIPMAP_LINEAR`, ...).
pub const TextureMinFilter = enum(u32) {
    /// Pick the nearest texel (`GL_NEAREST`).
    nearest = 0x2600,

    /// Interpolate between the four nearest texels (`GL_LINEAR`).
    linear = 0x2601,

    /// Nearest mipmap level, nearest texel (`GL_NEAREST_MIPMAP_NEAREST`).
    nearest_mipmap_nearest = 0x2700,

    /// Nearest mipmap level, linear interpolation (`GL_LINEAR_MIPMAP_NEAREST`).
    linear_mipmap_nearest = 0x2701,

    /// Linear interpolation of the two nearest mipmap levels, nearest texel
    /// (`GL_NEAREST_MIPMAP_LINEAR`).
    nearest_mipmap_linear = 0x2702,

    /// Linear interpolation of the two nearest mipmap levels and texels
    /// (`GL_LINEAR_MIPMAP_LINEAR`).
    linear_mipmap_linear = 0x2703,
};

/// Magnification filter selecting the sampling behavior when the texture is
/// scaled up (`GL_NEAREST`, `GL_LINEAR`).
pub const TextureMagFilter = enum(u32) {
    /// Pick the nearest texel (`GL_NEAREST`).
    nearest = 0x2600,

    /// Interpolate between the four nearest texels (`GL_LINEAR`).
    linear = 0x2601,
};

/// Wrapping mode for texture coordinates outside [0, 1]
/// (`GL_REPEAT`, `GL_CLAMP_TO_EDGE`, `GL_MIRRORED_REPEAT`).
pub const TextureWrap = enum(u32) {
    /// Clamp the coordinate to the texel edge (`GL_CLAMP_TO_EDGE`).
    clamp_to_edge = 0x812F,

    /// Mirror the coordinate before repeating (`GL_MIRRORED_REPEAT`).
    mirrored_repeat = 0x8370,

    /// Repeat the texture (`GL_REPEAT`).
    repeat = 0x2901,
};

/// Comparison mode of depth textures (`GL_NONE`,
/// `GL_COMPARE_REF_TO_TEXTURE`).
pub const CompareMode = enum(u32) {
    /// No comparison: the sampled value is returned directly (`GL_NONE`).
    none = 0x0000,

    /// Compare the reference value against the texture (`GL_COMPARE_REF_TO_TEXTURE`).
    compare_ref_to_texture = 0x884E,
};

/// Aliased comparison function for depth textures
/// (see [`enums.Comparison`](enums.Comparison)).
pub const CompareFunc = enums.Comparison;

/// Source channel of a texture swizzle operation
/// (`GL_RED`, `GL_GREEN`, `GL_BLUE`, `GL_ALPHA`, `GL_ZERO`, `GL_ONE`).
pub const Swizzle = enum(u32) {
    /// Take the value from the red component (`GL_RED`).
    red = 0x1903,

    /// Take the value from the green component (`GL_GREEN`).
    green = 0x1904,

    /// Take the value from the blue component (`GL_BLUE`).
    blue = 0x1905,

    /// Take the value from the alpha component (`GL_ALPHA`).
    alpha = 0x1906,

    /// Use the constant zero (`GL_ZERO`).
    zero = 0x0000,

    /// Use the constant one (`GL_ONE`).
    one = 0x0001,
};

/// Texture image unit index (`GL_TEXTURE0` ... `GL_TEXTURE31`).
pub const TextureUnit = enum(u32) {
    /// Texture unit 0 (`GL_TEXTURE0`).
    texture0 = 0x84C0,

    /// Texture unit 1 (`GL_TEXTURE1`).
    texture1 = 0x84C1,

    /// Texture unit 2 (`GL_TEXTURE2`).
    texture2 = 0x84C2,

    /// Texture unit 3 (`GL_TEXTURE3`).
    texture3 = 0x84C3,

    /// Texture unit 4 (`GL_TEXTURE4`).
    texture4 = 0x84C4,

    /// Texture unit 5 (`GL_TEXTURE5`).
    texture5 = 0x84C5,

    /// Texture unit 6 (`GL_TEXTURE6`).
    texture6 = 0x84C6,

    /// Texture unit 7 (`GL_TEXTURE7`).
    texture7 = 0x84C7,

    /// Texture unit 8 (`GL_TEXTURE8`).
    texture8 = 0x84C8,

    /// Texture unit 9 (`GL_TEXTURE9`).
    texture9 = 0x84C9,

    /// Texture unit 10 (`GL_TEXTURE10`).
    texture10 = 0x84CA,

    /// Texture unit 11 (`GL_TEXTURE11`).
    texture11 = 0x84CB,

    /// Texture unit 12 (`GL_TEXTURE12`).
    texture12 = 0x84CC,

    /// Texture unit 13 (`GL_TEXTURE13`).
    texture13 = 0x84CD,

    /// Texture unit 14 (`GL_TEXTURE14`).
    texture14 = 0x84CE,

    /// Texture unit 15 (`GL_TEXTURE15`).
    texture15 = 0x84CF,

    /// Texture unit 16 (`GL_TEXTURE16`).
    texture16 = 0x84D0,

    /// Texture unit 17 (`GL_TEXTURE17`).
    texture17 = 0x84D1,

    /// Texture unit 18 (`GL_TEXTURE18`).
    texture18 = 0x84D2,

    /// Texture unit 19 (`GL_TEXTURE19`).
    texture19 = 0x84D3,

    /// Texture unit 20 (`GL_TEXTURE20`).
    texture20 = 0x84D4,

    /// Texture unit 21 (`GL_TEXTURE21`).
    texture21 = 0x84D5,

    /// Texture unit 22 (`GL_TEXTURE22`).
    texture22 = 0x84D6,

    /// Texture unit 23 (`GL_TEXTURE23`).
    texture23 = 0x84D7,

    /// Texture unit 24 (`GL_TEXTURE24`).
    texture24 = 0x84D8,

    /// Texture unit 25 (`GL_TEXTURE25`).
    texture25 = 0x84D9,

    /// Texture unit 26 (`GL_TEXTURE26`).
    texture26 = 0x84DA,

    /// Texture unit 27 (`GL_TEXTURE27`).
    texture27 = 0x84DB,

    /// Texture unit 28 (`GL_TEXTURE28`).
    texture28 = 0x84DC,

    /// Texture unit 29 (`GL_TEXTURE29`).
    texture29 = 0x84DD,

    /// Texture unit 30 (`GL_TEXTURE30`).
    texture30 = 0x84DE,

    /// Texture unit 31 (`GL_TEXTURE31`).
    texture31 = 0x84DF,
};

/// Generates `n` new texture names (port of `glGenTextures`).
///
/// Texture names do not become textures until first bound.
///
/// ```
/// var tex: u32 = 0;
/// gl.textures.gen(1, &tex);
/// ```
pub fn gen(n: i32, textures: [*]u32) void {
    loader.context.gen_textures(n, textures);
}

/// Deletes the given textures (port of `glDeleteTextures`).
pub fn delete(n: i32, textures: [*]const u32) void {
    loader.context.delete_textures(n, textures);
}

/// Returns whether `texture` is the name of an existing texture
/// (port of `glIsTexture`).
pub fn isTexture(texture: u32) bool {
    return loader.context.isTexture(texture) != 0;
}

/// Selects the active texture unit (port of `glActiveTexture`).
///
/// All subsequent texture commands operate on the unit specified here.
/// Combine with the sampler binding in the shader via the texture unit
/// index.
///
/// ```
/// gl.textures.activeTexture(.texture0);
/// ```
pub fn activeTexture(unit: TextureUnit) void {
    loader.context.activeTexture(@intFromEnum(unit));
}

/// Binds the texture to the given target (port of `glBindTexture`).
pub fn bind(target: TextureTarget, texture: u32) void {
    loader.context.bind_texture(@intFromEnum(target), texture);
}

/// Generates mipmaps for the bound texture (port of `glGenerateMipmap`).
///
/// The base level must have been uploaded with [`image2d`](image2d) or
/// [`storage2d`](storage2d); the generated levels are needed for the
/// mipmapped minification filters.
pub fn generateMipmap(target: TextureTarget) void {
    loader.context.generateMipmap(@intFromEnum(target));
}

/// Uploads a 2D texture image (port of `glTexImage2D`).
///
/// `internalformat` defines the storage format on the GPU; `format` and
/// `kind` describe the layout of the CPU data in `pixels`. Passing `null` as
/// `pixels` only reserves storage. A cube map face is uploaded by using the
/// corresponding [`TextureTarget`](TextureTarget) face as `target`.
///
/// ```
/// gl.textures.image2d(.texture_2d, 0, .rgba8, w, h, 0, .rgba, .unsigned_byte, pixels);
/// ```
pub fn image2d(
    target: TextureTarget,
    level: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
    border: i32,
    format: PixelFormat,
    kind: enums.DataType,
    pixels: ?*const anyopaque,
) void {
    loader.context.tex_image_2d(
        @intFromEnum(target),
        level,
        @intCast(@intFromEnum(internalformat)),
        width,
        height,
        border,
        @intFromEnum(format),
        @intFromEnum(kind),
        pixels,
    );
}

/// Uploads a 3D texture image (port of `glTexImage3D`).
///
/// All three dimensions must be positive; otherwise the driver sets
/// `GL_INVALID_VALUE`.
pub fn image3d(
    target: TextureTarget,
    level: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
    depth: i32,
    border: i32,
    format: PixelFormat,
    kind: enums.DataType,
    pixels: ?*const anyopaque,
) void {
    loader.context.tex_image_3d(
        @intFromEnum(target),
        level,
        @intCast(@intFromEnum(internalformat)),
        width,
        height,
        depth,
        border,
        @intFromEnum(format),
        @intFromEnum(kind),
        pixels,
    );
}

/// Uploads a subrange of a 2D texture image (port of `glTexSubImage2D`).
pub fn subImage2d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    width: i32,
    height: i32,
    format: PixelFormat,
    kind: enums.DataType,
    pixels: ?*const anyopaque,
) void {
    loader.context.tex_sub_image_2d(
        @intFromEnum(target),
        level,
        xoffset,
        yoffset,
        width,
        height,
        @intFromEnum(format),
        @intFromEnum(kind),
        pixels,
    );
}

/// Uploads a subrange of a 3D texture image (port of `glTexSubImage3D`).
pub fn subImage3d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    zoffset: i32,
    width: i32,
    height: i32,
    depth: i32,
    format: PixelFormat,
    kind: enums.DataType,
    pixels: ?*const anyopaque,
) void {
    loader.context.tex_sub_image_3d(
        @intFromEnum(target),
        level,
        xoffset,
        yoffset,
        zoffset,
        width,
        height,
        depth,
        @intFromEnum(format),
        @intFromEnum(kind),
        pixels,
    );
}

/// Allocates immutable storage of a 2D texture with `levels` mipmap levels
/// (port of `glTexStorage2D`).
///
/// After this call the texture is immutable: neither its format nor its
/// dimensions can be changed, and data is uploaded with
/// [`subImage2d`](subImage2d).
pub fn storage2d(
    target: TextureTarget,
    levels: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
) void {
    loader.context.tex_storage_2d(
        @intFromEnum(target),
        levels,
        @intFromEnum(internalformat),
        width,
        height,
    );
}

/// Allocates immutable storage of a 3D texture with `levels` mipmap levels
/// (port of `glTexStorage3D`).
pub fn storage3d(
    target: TextureTarget,
    levels: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
    depth: i32,
) void {
    loader.context.tex_storage_3d(
        @intFromEnum(target),
        levels,
        @intFromEnum(internalformat),
        width,
        height,
        depth,
    );
}

/// Copies a rectangle from the framebuffer into a 2D texture image
/// (port of `glCopyTexImage2D`).
pub fn copyImage2d(
    target: TextureTarget,
    level: i32,
    internalformat: InternalFormat,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    border: i32,
) void {
    loader.context.copy_tex_image_2d(
        @intFromEnum(target),
        level,
        @intFromEnum(internalformat),
        x,
        y,
        width,
        height,
        border,
    );
}

/// Copies a rectangle from the framebuffer into a 2D texture subimage
/// (port of `glCopyTexSubImage2D`).
pub fn copySubImage2d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) void {
    loader.context.copy_tex_sub_image_2d(@intFromEnum(target), level, xoffset, yoffset, x, y, width, height);
}

/// Copies a rectangle from the framebuffer into a 3D texture subimage
/// (port of `glCopyTexSubImage3D`).
pub fn copySubImage3d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    zoffset: i32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
) void {
    loader.context.copy_tex_sub_image_3d(@intFromEnum(target), level, xoffset, yoffset, zoffset, x, y, width, height);
}

/// Uploads a compressed 2D texture image (port of `glCompressedTexImage2D`).
///
/// `image_size` is the size of the compressed data in bytes; `data` points to
/// ETC2/EAC or another supported compressed block stream.
pub fn compressedImage2d(
    target: TextureTarget,
    level: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
    border: i32,
    image_size: i32,
    data: ?*const anyopaque,
) void {
    loader.context.compressed_tex_image_2d(
        @intFromEnum(target),
        level,
        @intFromEnum(internalformat),
        width,
        height,
        border,
        image_size,
        data,
    );
}

/// Uploads a compressed 3D texture image (port of `glCompressedTexImage3D`).
pub fn compressedImage3d(
    target: TextureTarget,
    level: i32,
    internalformat: InternalFormat,
    width: i32,
    height: i32,
    depth: i32,
    border: i32,
    image_size: i32,
    data: ?*const anyopaque,
) void {
    loader.context.compressed_tex_image_3d(
        @intFromEnum(target),
        level,
        @intFromEnum(internalformat),
        width,
        height,
        depth,
        border,
        image_size,
        data,
    );
}

/// Uploads a compressed 2D texture subimage (port of
/// `glCompressedTexSubImage2D`).
pub fn compressedSubImage2d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    width: i32,
    height: i32,
    format: InternalFormat,
    image_size: i32,
    data: ?*const anyopaque,
) void {
    loader.context.compressed_tex_sub_image_2d(
        @intFromEnum(target),
        level,
        xoffset,
        yoffset,
        width,
        height,
        @intFromEnum(format),
        image_size,
        data,
    );
}

/// Uploads a compressed 3D texture subimage (port of
/// `glCompressedTexSubImage3D`).
pub fn compressedSubImage3d(
    target: TextureTarget,
    level: i32,
    xoffset: i32,
    yoffset: i32,
    zoffset: i32,
    width: i32,
    height: i32,
    depth: i32,
    format: InternalFormat,
    image_size: i32,
    data: ?*const anyopaque,
) void {
    loader.context.compressed_tex_sub_image_3d(
        @intFromEnum(target),
        level,
        xoffset,
        yoffset,
        zoffset,
        width,
        height,
        depth,
        @intFromEnum(format),
        image_size,
        data,
    );
}

/// Sets an integer-valued parameter of the bound texture (port of
/// `glTexParameteri`).
///
/// ```
/// gl.textures.parameterI(.texture_2d, .texture_min_filter, @intFromEnum(.linear_mipmap_linear));
/// ```
pub fn parameterI(target: TextureTarget, pname: TextureParameter, param: i32) void {
    loader.context.tex_parameter_i(@intFromEnum(target), @intFromEnum(pname), param);
}

/// Sets a floating-point parameter of the bound texture (port of
/// `glTexParameterf`).
pub fn parameterF(target: TextureTarget, pname: TextureParameter, param: f32) void {
    loader.context.tex_parameter_f(@intFromEnum(target), @intFromEnum(pname), param);
}

/// Sets an array of integer parameters of the bound texture (port of
/// `glTexParameteriv`).
pub fn parameterIv(target: TextureTarget, pname: TextureParameter, params: [*]const i32) void {
    loader.context.tex_parameter_iv(@intFromEnum(target), @intFromEnum(pname), params);
}

/// Sets an array of floating-point parameters of the bound texture (port of
/// `glTexParameterfv`).
pub fn parameterFv(target: TextureTarget, pname: TextureParameter, params: [*]const f32) void {
    loader.context.tex_parameter_fv(@intFromEnum(target), @intFromEnum(pname), params);
}

/// Reads an integer-valued parameter of the bound texture (port of
/// `glGetTexParameteriv`).
pub fn getParameterI(target: TextureTarget, pname: TextureParameter, params: [*]i32) void {
    loader.context.get_tex_parameter_iv(@intFromEnum(target), @intFromEnum(pname), params);
}

/// Reads a floating-point parameter of the bound texture (port of
/// `glGetTexParameterfv`).
pub fn getParameterF(target: TextureTarget, pname: TextureParameter, params: [*]f32) void {
    loader.context.get_tex_parameter_fv(@intFromEnum(target), @intFromEnum(pname), params);
}