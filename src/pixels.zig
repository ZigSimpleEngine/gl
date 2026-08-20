//! Pixel transfer: store settings and readback from the framebuffer.
//!
//! This namespace groups the pixel store state ([`storeI`](storeI)) that
//! governs how pixel data is packed and unpacked in memory, plus the
//! framebuffer readback operations [`readBuffer`](readBuffer) and
//! [`readPixels`](readPixels).

const loader = @import("loader.zig");
const enums = @import("enums.zig");
const textures = @import("textures.zig");

/// A pixel store parameter read or written via [`storeI`](storeI)
/// (`GL_PACK_ALIGNMENT`, `GL_UNPACK_ROW_LENGTH`, ...).
pub const PixelStoreParameter = enum(u32) {
    /// Row length in pixels used when packing data for
    /// [`readPixels`](readPixels) (`GL_PACK_ROW_LENGTH`).
    pack_row_length = 0x0D02,

    /// Number of rows skipped at the start of packed data (`GL_PACK_SKIP_ROWS`).
    pack_skip_rows = 0x0D03,

    /// Number of pixels skipped at the start of each row when packing
    /// (`GL_PACK_SKIP_PIXELS`).
    pack_skip_pixels = 0x0D04,

    /// Byte alignment (1, 2, 4 or 8) of each pixel row when packing
    /// (`GL_PACK_ALIGNMENT`).
    pack_alignment = 0x0D05,

    /// Row length in pixels used when unpacking data for texture uploads
    /// (`GL_UNPACK_ROW_LENGTH`).
    unpack_row_length = 0x0CF2,

    /// Number of rows skipped at the start of unpacked data
    /// (`GL_UNPACK_SKIP_ROWS`).
    unpack_skip_rows = 0x0CF3,

    /// Number of pixels skipped at the start of each row when unpacking
    /// (`GL_UNPACK_SKIP_PIXELS`).
    unpack_skip_pixels = 0x0CF4,

    /// Byte alignment (1, 2, 4 or 8) of each pixel row when unpacking
    /// (`GL_UNPACK_ALIGNMENT`).
    unpack_alignment = 0x0CF5,
};

/// Sets a pixel store parameter (port of `glPixelStorei`).
///
/// The default alignment is 4 for both packing and unpacking; textures with
/// tightly packed rows often need [`PixelStoreParameter.unpack_alignment`](PixelStoreParameter.unpack_alignment)
/// set to 1.
///
/// ```
/// gl.pixels.storeI(.unpack_alignment, 1);
/// ```
pub fn storeI(pname: PixelStoreParameter, param: i32) void {
    loader.context.pixel_store_i(@intFromEnum(pname), param);
}

/// Selects the buffer read by [`readPixels`](readPixels)
/// (port of `glReadBuffer`).
///
/// On the default framebuffer, `GL_BACK` and `GL_COLOR` both select the
/// color buffer; on a framebuffer object only `GL_COLOR` is valid.
pub fn readBuffer(src: ReadBuffer) void {
    loader.context.readBuffer(@intFromEnum(src));
}

/// Buffer selectable as the read source of [`readPixels`](readPixels).
pub const ReadBuffer = enum(u32) {
    /// No buffer: reads produce undefined data (`GL_NONE`).
    none = 0x0000,

    /// The color buffer (`GL_COLOR`).
    color = 0x1800,

    /// The back buffer of the default framebuffer (`GL_BACK`).
    back = 0x0405,
};

/// Reads a block of pixels from the framebuffer into CPU memory
/// (port of `glReadPixels`).
///
/// The region is a `width` × `height` rectangle with its lower-left corner
/// at (`x`, `y`). `format` and `kind` describe the desired CPU layout; the
/// driver performs the conversion. The source is the buffer selected by
/// [`readBuffer`](readBuffer) and the preferred format reported by the
/// `GL_IMPLEMENTATION_COLOR_READ_FORMAT`/`GL_IMPLEMENTATION_COLOR_READ_TYPE`
/// state.
///
/// The number of bytes written into `pixels` depends on the pack settings
/// ([`storeI`](storeI)). Call [`state.finish`](state.finish) before reading
/// to guarantee that the framebuffer contents are up to date.
pub fn readPixels(
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    format: textures.PixelFormat,
    kind: enums.DataType,
    pixels: ?*anyopaque,
) void {
    loader.context.readPixels(x, y, width, height, @intFromEnum(format), @intFromEnum(kind), pixels);
}