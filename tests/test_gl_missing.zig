//! Notice shown when real OpenGL verification cannot run.
//!
//! This executable is wired into the `test` step only when the optional
//! local rgfw checkout is absent (see `build.zig`). It always exits with
//! code 1: without rgfw the GL tests cannot be built at all, so the suite
//! reports that real verification is impossible and the tests do not pass.
//! Downstream consumers of the `gl` package never need rgfw: their builds
//! never execute this package's `test` step.

const std = @import("std");
const build_paths = @import("build_paths");

pub fn main() !void {
    std.debug.print("real GL verification of gl is impossible: local rgfw dependency not found at \"{s}\"; GL tests are not executed\n", .{build_paths.rgfw_path});
    std.process.exit(1);
}
