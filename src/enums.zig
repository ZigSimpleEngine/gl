//! Common OpenGL ES 3.0 enumerations.
//!
//! This module collects types shared by several library namespaces: data
//! types, comparison functions, polygon faces and the buffer bitmask.
//! Specialized enumerations (buffer binding targets, texture internal
//! formats, etc.) live in their respective namespaces: [`buffers`](buffers),
//! [`textures`](textures) and others.

/// Error code returned by [`errors.getError`](errors.getError).
///
/// Calling `getError` resets the error state: a subsequent call returns
/// [`no_error`](ErrorCode.no_error) unless a new error occurred in between.
pub const ErrorCode = enum(u32) {
    /// No error has been recorded (`GL_NO_ERROR`).
    no_error = 0x0000,

    /// An invalid enumerator was passed (`GL_INVALID_ENUM`).
    invalid_enum = 0x0500,

    /// A numeric value outside the valid range was passed (`GL_INVALID_VALUE`).
    invalid_value = 0x0501,

    /// The operation is not valid in the current state (`GL_INVALID_OPERATION`).
    invalid_operation = 0x0502,

    /// A command changes the state of the framebuffer, but the framebuffer is
    /// incomplete (`GL_INVALID_FRAMEBUFFER_OPERATION`).
    invalid_framebuffer_operation = 0x0506,

    /// Not enough memory is available to perform the operation
    /// (`GL_OUT_OF_MEMORY`).
    out_of_memory = 0x0505,
};

/// Data type describing the representation of values in memory or in a
/// shader (`GL_BYTE`, `GL_FLOAT`, etc.).
///
/// Used by texture upload, pixel readback and other APIs that operate on
/// data of an unspecified format.
pub const DataType = enum(u32) {
    /// Signed 8-bit integer (`GL_BYTE`).
    byte = 0x1400,

    /// Unsigned 8-bit integer (`GL_UNSIGNED_BYTE`).
    unsigned_byte = 0x1401,

    /// Signed 16-bit integer (`GL_SHORT`).
    short = 0x1402,

    /// Unsigned 16-bit integer (`GL_UNSIGNED_SHORT`).
    unsigned_short = 0x1403,

    /// Signed 32-bit integer (`GL_INT`).
    int = 0x1404,

    /// Unsigned 32-bit integer (`GL_UNSIGNED_INT`).
    unsigned_int = 0x1405,

    /// 16-bit floating-point number (`GL_HALF_FLOAT`).
    half_float = 0x140B,

    /// 32-bit floating-point number (`GL_FLOAT`).
    float = 0x1406,

    /// 32-bit fixed-point number (`GL_FIXED`).
    fixed = 0x140C,

    /// 32-bit integer with 2,10,10,10 packing, bits in reversed order
    /// (`GL_INT_2_10_10_10_REV`).
    int_2_10_10_10_rev = 0x8D9F,

    /// Unsigned 32-bit integer with 2,10,10,10 packing
    /// (`GL_UNSIGNED_INT_2_10_10_10_REV`).
    unsigned_int_2_10_10_10_rev = 0x8368,

    /// Unsigned 32-bit integer with 10,11,11 packing, encoding an unsigned
    /// floating-point format (`GL_UNSIGNED_INT_10F_11F_11F_REV`).
    unsigned_int_10f_11f_11f_rev = 0x8C3B,

    /// Packed 24-bit depth buffer plus 8-bit stencil (`GL_UNSIGNED_INT_24_8`).
    unsigned_int_24_8 = 0x84FA,

    /// Packed RGB_E5B9G9R9 format (`GL_UNSIGNED_INT_5_9_9_9_REV`).
    unsigned_int_5_9_9_9_rev = 0x8C3E,

    /// A pair of a 32-bit floating-point value and 24-bit depth with 8-bit
    /// stencil (`GL_FLOAT_32_UNSIGNED_INT_24_8_REV`).
    float_32_unsigned_int_24_8_rev = 0x8DAD,
};

/// Comparison function: the result is `true` if `operand1 <operator> operand2`.
///
/// Used by the depth test ([`depth.depthFunc`](depth.depthFunc)), the
/// stencil test ([`stencil`](stencil)), texture comparison
/// ([`textures.CompareFunc`](textures.CompareFunc)) and other operations.
pub const Comparison = enum(u32) {
    /// Never passes (`GL_NEVER`).
    never = 0x0200,

    /// Passes if the reference value is less than the stored value
    /// (`GL_LESS`).
    less = 0x0201,

    /// Passes if the reference value is equal to the stored value
    /// (`GL_EQUAL`).
    equal = 0x0202,

    /// Passes if the reference value is less than or equal to the stored
    /// value (`GL_LEQUAL`).
    lequal = 0x0203,

    /// Passes if the reference value is greater than the stored value
    /// (`GL_GREATER`).
    greater = 0x0204,

    /// Passes if the reference value is not equal to the stored value
    /// (`GL_NOTEQUAL`).
    not_equal = 0x0205,

    /// Passes if the reference value is greater than or equal to the stored
    /// value (`GL_GEQUAL`).
    gequal = 0x0206,

    /// Always passes (`GL_ALWAYS`).
    always = 0x0207,
};

/// Polygon face or "side" (for stencil and culling modes).
///
/// Used by back-face culling ([`rasterization.cullFace`](rasterization.cullFace))
/// and by separate stencil settings ([`stencil`](stencil)).
pub const Face = enum(u32) {
    /// Front face (`GL_FRONT`).
    front = 0x0404,

    /// Back face (`GL_BACK`).
    back = 0x0405,

    /// Both faces (`GL_FRONT_AND_BACK`).
    front_and_back = 0x0408,
};

/// Bitmask of buffers affected by a clear or copy operation.
///
/// A convenient struct instead of manual flag assembly: it is passed to
/// [`clear.clear`](clear.clear) and [`framebuffers.blit`](framebuffers.blit).
/// The [`bits`](BufferMask.bits) method returns the native `GLbitfield` value.
pub const BufferMask = packed struct {
    /// Clear/copy the color buffer (`GL_COLOR_BUFFER_BIT`).
    color: bool = false,

    /// Clear/copy the depth buffer (`GL_DEPTH_BUFFER_BIT`).
    depth: bool = false,

    /// Clear/copy the stencil buffer (`GL_STENCIL_BUFFER_BIT`).
    stencil: bool = false,

    /// Reserved bits; always zero.
    _reserved: u29 = 0,

    /// Reserved bits not used in ES 3.0.
    pub const reserved_bits: u32 = 0;

    /// Returns the native 32-bit bitmask value (`GLbitfield`).
    ///
    /// The color bit occupies position `0x00004000`, the depth bit
    /// `0x00000100` and the stencil bit `0x00000400`, as defined by the
    /// OpenGL specification.
    pub fn bits(mask: BufferMask) u32 {
        var value: u32 = 0;
        if (mask.color) value |= color_buffer_bit;
        if (mask.depth) value |= depth_buffer_bit;
        if (mask.stencil) value |= stencil_buffer_bit;
        return value;
    }
};

/// Value of the color buffer bit in the [`BufferMask`](BufferMask) bitmask.
pub const color_buffer_bit: u32 = 0x00004000;

/// Value of the depth buffer bit in the [`BufferMask`](BufferMask) bitmask.
pub const depth_buffer_bit: u32 = 0x00000100;

/// Value of the stencil buffer bit in the [`BufferMask`](BufferMask) bitmask.
pub const stencil_buffer_bit: u32 = 0x00000400;