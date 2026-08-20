//! Core primitive types of OpenGL ES 3.0.
//!
//! These types mirror the native `GLenum`, `GLuint`, `GLintptr` and other
//! types declared in the `glad/gles2.h` header (GL ES 3.0 specification).
//! They all have the same width and are layout-compatible with their C
//! counterparts, so they can be freely passed to native functions and used
//! in `extern`-linked structs.

/// Positive boolean flag (`GL_TRUE`, value 1).
pub const true_value: u8 = 1;

/// Negative boolean flag (`GL_FALSE`, value 0).
pub const false_value: u8 = 0;

/// `GLenum` — unsigned 32-bit integer encoding OpenGL enumerations.
///
/// The native values of all enumerations are described by dedicated
/// `enum(u32)` types; `Enum` itself acts as a low-level value container.
pub const Enum = u32;

/// `GLboolean` — a byte holding an OpenGL boolean value (`GL_FALSE` = 0,
/// `GL_TRUE` = 1). Used as the return type of boolean queries.
pub const Boolean = u8;

/// `GLbitfield` — unsigned 32-bit integer holding a bitmask.
pub const Bitfield = u32;

/// `GLbyte` — signed 8-bit integer (`khronos_int8_t`).
pub const Byte = i8;

/// `GLubyte` — unsigned 8-bit integer (`khronos_uint8_t`).
pub const UByte = u8;

/// `GLshort` — signed 16-bit integer (`khronos_int16_t`).
pub const Short = i16;

/// `GLushort` — unsigned 16-bit integer (`khronos_uint16_t`).
pub const UShort = u16;

/// `GLint` — signed 32-bit integer.
pub const Int = i32;

/// `GLuint` — unsigned 32-bit integer; the standard type for object names
/// (buffers, textures, programs, etc.).
pub const UInt = u32;

/// `GLsizei` — signed 32-bit integer; the type for sizes and counts.
pub const Sizei = i32;

/// `GLintptr` — signed integer large enough to hold an address
/// (`khronos_intptr_t`); used as a byte offset within a buffer.
pub const Intptr = isize;

/// `GLsizeiptr` — signed integer large enough to hold a size
/// (`khronos_ssize_t`); used as a buffer size in bytes.
pub const Sizeiptr = isize;

/// `GLint64` — signed 64-bit integer (`khronos_int64_t`).
pub const Int64 = i64;

/// `GLuint64` — unsigned 64-bit integer (`khronos_uint64_t`); used, for
/// example, for timeouts expressed in nanoseconds.
pub const UInt64 = u64;

/// `GLfloat` — 32-bit floating-point number (`khronos_float_t`).
pub const Float = f32;

/// `GLclampf` — 32-bit floating-point number, clamped to the [0, 1] range
/// by the specification.
pub const Clampf = f32;

/// `GLclampx` — 32-bit integer encoding a fixed-point number
/// (`khronos_int32_t`).
pub const Clampx = i32;

/// `GLfixed` — 32-bit integer encoding a fixed-point number
/// (`khronos_int32_t`); used in ES 1.x, kept for compatibility.
pub const Fixed = i32;

/// `GLchar` — a character byte; OpenGL strings are NUL-terminated sequences
/// of `GLchar`.
pub const Char = u8;

/// `GLhalf` — 16-bit floating-point number (`khronos_uint16_t`).
pub const Half = u16;

/// `GLsync` — opaque pointer to a sync object (`struct __GLsync *`). The type
/// is opaque: it can only be manipulated through the [`sync`](sync) namespace
/// functions, such as `fenceSync` and `clientWaitSync`.
pub const Sync = *opaque {};

/// Function that loads an OpenGL function address by name (analogue of
/// `GLADloadfunc`).
///
/// The library itself does not know where function addresses come from — the
/// exact mechanism depends on the platform (e.g. `eglGetProcAddress` on
/// Android or `wglGetProcAddress` on Windows). The user passes a loader
/// function to [`loader.init`](loader.init), and the library requests the
/// addresses of all required functions from it by name.
///
/// The prototype is compatible with `GLADloadfunc`: the function takes a
/// function name (`const char *`) and returns a function pointer or `null`
/// if the function is unavailable.
pub const LoadFn = *const fn (name: [*:0]const u8) callconv(.c) ?*const anyopaque;

/// `GLADapiproc` — generic OpenGL function pointer without a signature.
///
/// Used internally by the library to store intermediate loading results;
/// the user usually does not need it.
pub const ApiProc = *const fn () callconv(.c) void;