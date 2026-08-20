//! OpenGL ES 3.0 bindings for Zig — a native port of the `glad` loader.
//!
//! This library provides typed, documented wrappers over the native OpenGL
//! ES 3.0 API (compatible with WebGL 2). All functions are grouped into
//! object-oriented namespaces by their meaning;
//!
//! # Example
//!
//! 1. Obtain a loader function that resolves OpenGL function addresses by
//!    name (platform-dependent, e.g. `eglGetProcAddress` on Android or
//!    `wglGetProcAddress` on Windows).
//! 2. Load the context once:
//!
//!    ```
//!    const gl = @import("gl");
//!
//!    fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
//!        return platform.get_proc_address(name);
//!    }
//!
//!    try gl.loader.load(getProcAddress);
//!    ```
//!
//! 3. Use the namespaces:
//!
//!    ```
//!    gl.viewport.viewport(0, 0, width, height);
//!    gl.clear.clearColor(0.2, 0.3, 0.3, 1.0);
//!    gl.clear.clear(.{ .color = true });
//!    gl.drawing.drawArrays(.triangles, 0, 36);
//!    ```
//!
//! # Namespaces
//!
//! - [`loader`](loader) — context loading, extension checks;
//! - [`types`](types) — primitive GL types;
//! - [`enums`](enums) — shared enumerations;
//! - [`state`](state) — global state: capabilities, getters, hints;
//! - [`viewport`](viewport) — viewport rectangle;
//! - [`clear`](clear) — clear values and clear operations;
//! - [`blending`](blending) — color blending;
//! - [`depth`](depth) — depth test;
//! - [`stencil`](stencil) — stencil test;
//! - [`rasterization`](rasterization) — culling, line width, scissor;
//! - [`drawing`](drawing) — draw calls;
//! - [`buffers`](buffers) — buffer objects;
//! - [`textures`](textures) — texture objects;
//! - [`samplers`](samplers) — sampler objects;
//! - [`pixels`](pixels) — pixel store and readback;
//! - [`framebuffers`](framebuffers) — framebuffer objects;
//! - [`renderbuffers`](renderbuffers) — renderbuffer objects;
//! - [`vertex_attributes`](vertex_attributes) — generic vertex attributes;
//! - [`vertex_arrays`](vertex_arrays) — vertex array objects;
//! - [`shaders`](shaders) — shader objects;
//! - [`programs`](programs) — program objects;
//! - [`uniforms`](uniforms) — uniforms and uniform blocks;
//! - [`queries`](queries) — occlusion and count queries;
//! - [`transform_feedback`](transform_feedback) — transform feedback;
//! - [`sync`](sync) — sync objects;
//! - [`errors`](errors) — error reporting.
//!
//! # Example
//!
//! A minimal triangle:
//!
//! ```
//! const gl = @import("gl");
//!
//! const vertex_source = @embedFile("triangle.vert");
//! const fragment_source = @embedFile("triangle.frag");
//!
//! pub fn init() !void {
//!     try gl.loader.load(platform.get_proc_address);
//!
//!     gl.viewport.viewport(0, 0, 640, 480);
//!     gl.clear.clearColor(0.0, 0.0, 0.0, 1.0);
//!
//!     const vs = gl.shaders.create(.vertex_shader);
//!     gl.shaders.source(vs, vertex_source);
//!     gl.shaders.compile(vs);
//!     const fs = gl.shaders.create(.fragment_shader);
//!     gl.shaders.source(fs, fragment_source);
//!     gl.shaders.compile(fs);
//!
//!     const program = gl.programs.create();
//!     gl.programs.attach(program, vs);
//!     gl.programs.attach(program, fs);
//!     gl.programs.link(program);
//!     gl.programs.use(program);
//! }
//!
//! pub fn render() void {
//!     gl.clear.clear(.{ .color = true });
//!     gl.drawing.drawArrays(.triangles, 0, 3);
//! }
//! ```

pub const types = @import("types.zig");
pub const enums = @import("enums.zig");
pub const loader = @import("loader.zig");
pub const state = @import("state.zig");
pub const viewport = @import("viewport.zig");
pub const clear = @import("clear.zig");
pub const blending = @import("blending.zig");
pub const depth = @import("depth.zig");
pub const stencil = @import("stencil.zig");
pub const rasterization = @import("rasterization.zig");
pub const drawing = @import("drawing.zig");
pub const buffers = @import("buffers.zig");
pub const textures = @import("textures.zig");
pub const samplers = @import("samplers.zig");
pub const pixels = @import("pixels.zig");
pub const framebuffers = @import("framebuffers.zig");
pub const renderbuffers = @import("renderbuffers.zig");
pub const vertex_attributes = @import("vertex_attributes.zig");
pub const vertex_arrays = @import("vertex_arrays.zig");
pub const shaders = @import("shaders.zig");
pub const programs = @import("programs.zig");
pub const uniforms = @import("uniforms.zig");
pub const queries = @import("queries.zig");
pub const transform_feedback = @import("transform_feedback.zig");
pub const sync = @import("sync.zig");
pub const errors = @import("errors.zig");
