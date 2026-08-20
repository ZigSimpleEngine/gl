//! Occlusion and primitive-count queries.
//!
//! Queries measure GPU-side events without stalling the pipeline: begin a
//! query, render, end it, and poll the result later with
//! [`getResult`](getResult).

const loader = @import("loader.zig");

/// Target of a query, determining what is measured
/// (`GL_ANY_SAMPLES_PASSED`, `GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN`,
/// ...).
pub const QueryTarget = enum(u32) {
    /// Counts whether any sample of the rendered fragments passed all tests
    /// (`GL_ANY_SAMPLES_PASSED`). The result is `1` or `0`.
    any_samples_passed = 0x8C2F,

    /// Like [`QueryTarget.any_samples_passed`](QueryTarget.any_samples_passed)
    /// but more conservative about multisample coverage
    /// (`GL_ANY_SAMPLES_PASSED_CONSERVATIVE`).
    any_samples_passed_conservative = 0x8D6A,

    /// Counts the primitives written to the transform feedback buffers
    /// (`GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN`).
    transform_feedback_primitives_written = 0x8C88,
};

/// A parameter of a query read via [`getObject`](getObject) or
/// [`getParameter`](getParameter).
pub const QueryParameter = enum(u32) {
    /// Result of the query (`GL_QUERY_RESULT`).
    query_result = 0x8866,

    /// Whether the result is already available without stalling
    /// ([`boolean`], `GL_QUERY_RESULT_AVAILABLE`).
    query_result_available = 0x8867,

    /// Name of the query active on the target, or `0` (`GL_CURRENT_QUERY`).
    current_query = 0x8865,
};

/// Generates `n` new query names (port of `glGenQueries`).
///
/// Query names do not become queries until first used with
/// [`begin`](begin).
pub fn gen(n: i32, ids: [*]u32) void {
    loader.context.gen_queries(n, ids);
}

/// Deletes the given queries (port of `glDeleteQueries`).
pub fn delete(n: i32, ids: [*]const u32) void {
    loader.context.delete_queries(n, ids);
}

/// Returns whether `id` is the name of an existing query (port of
/// `glIsQuery`).
pub fn isQuery(id: u32) bool {
    return loader.context.isQuery(id) != 0;
}

/// Starts measuring on the target with the given query (port of
/// `glBeginQuery`).
///
/// Only one query per target can be active at a time; calling `begin`
/// while a query on the same target is active is an error.
///
/// ```
/// gl.queries.begin(.any_samples_passed, query_id);
/// gl.drawing.drawArrays(.triangles, 0, 36);
/// gl.queries.end(.any_samples_passed);
/// ```
pub fn begin(target: QueryTarget, id: u32) void {
    loader.context.begin_query(@intFromEnum(target), id);
}

/// Stops the active query on the target (port of `glEndQuery`).
pub fn end(target: QueryTarget) void {
    loader.context.end_query(@intFromEnum(target));
}

/// Reads a parameter of the given query (port of `glGetQueryObjectuiv`).
pub fn getObject(id: u32, pname: QueryParameter, params: [*]u32) void {
    loader.context.get_query_object_uiv(id, @intFromEnum(pname), params);
}

/// Returns the result of the query into `params` (port of
/// `glGetQueryObjectuiv` with `GL_QUERY_RESULT`).
///
/// Blocks until the result is available, which may stall the pipeline;
/// poll [`resultIsAvailable`](resultIsAvailable) to avoid that.
pub fn getResult(id: u32, params: [*]u32) void {
    loader.context.get_query_object_uiv(id, 0x8866, params);
}

/// Writes whether the query result is available without stalling (port of
/// `glGetQueryObjectuiv` with `GL_QUERY_RESULT_AVAILABLE`).
///
/// Poll in a loop until the value becomes non-zero, then read the result
/// with [`getResult`](getResult).
pub fn resultIsAvailable(id: u32, params: [*]u32) void {
    loader.context.get_query_object_uiv(id, 0x8867, params);
}

/// Reads a parameter of the query active on the target (port of
/// `glGetQueryiv`).
pub fn getParameter(target: QueryTarget, pname: QueryParameter, params: [*]i32) void {
    loader.context.get_query_iv(@intFromEnum(target), @intFromEnum(pname), params);
}