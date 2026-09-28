const std = @import("std");

const ThisBuild = @This();

pub const Options = struct {
    /// The target architecture for which the module will be built.
    target: ?std.Build.ResolvedTarget = null,
    /// The optimization mode used to compile the module.
    optimize: ?std.builtin.OptimizeMode = null,

    pub fn initFromOptions(b: *std.Build) Options {
        return .{
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        };
    }

    /// Create the `gl` module in the caller's build graph.
    ///
    /// Intended for parent packages that want a single shared instance:
    /// ```zig
    /// const gl_mod = (@import("gl").Options{
    ///     .target = target,
    ///     .optimize = optimize,
    /// }).getModule(b);
    /// ```
    /// Uses `dependencyFromBuildZig` so source paths stay correct when
    /// called from a parent build via `@import("gl")`.
    pub fn getModule(self: Options, b: *std.Build) *std.Build.Module {
        const target = self.target orelse b.standardTargetOptions(.{});
        const optimize = self.optimize orelse b.standardOptimizeOption(.{});
        const self_dep = b.dependencyFromBuildZig(ThisBuild, .{
            .target = target,
            .optimize = optimize,
        });
        return b.createModule(.{
            .root_source_file = self_dep.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });
    }
};

/// Create the `gl` module in the *own* package graph (standalone `zig build`).
/// Same wiring as `Options.getModule` but uses `b.path` (valid only for own build).
fn createModuleOwn(b: *std.Build, options: Options) *std.Build.Module {
    const target = options.target orelse b.standardTargetOptions(.{});
    const optimize = options.optimize orelse b.standardOptimizeOption(.{});
    return b.addModule("gl", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}

/// Whether the optional local rgfw checkout is present.
///
/// Probed by its build file directly on the filesystem, without involving
/// the package manager, so builds that cannot see it (downstream consumers
/// of `gl`) simply take the rgfw-free path instead of failing.
fn rgfwCheckoutPresent(b: *std.Build) bool {
    const marker = b.path("../rgfw/build.zig");
    std.Io.Dir.accessAbsolute(b.graph.io, marker.getPath(b), .{}) catch return false;
    return true;
}

pub fn build(b: *std.Build) void {
    const options = Options.initFromOptions(b);
    const target = options.target orelse b.standardTargetOptions(.{});
    const optimize = options.optimize orelse b.standardOptimizeOption(.{});

    const gl_module = createModuleOwn(b, options);

    const exe = b.addExecutable(.{
        .name = "gl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "gl", .module = gl_module },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const lib_tests = b.addTest(.{ .root_module = gl_module });
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);

    // Real-OpenGL tests through a local rgfw checkout.
    //
    // Every test that touches GL runs against a true GPU context opened
    // with rgfw; there are no mocked contexts anywhere in the suite. The
    // checkout is resolved through the `rgfw` path dependency (see
    // build.zig.zon) and only when its directory exists: otherwise `zig
    // build test` reports that real GL verification is impossible and the
    // step fails. Consuming the `gl` package never requires rgfw:
    // downstream builds never execute this package's `test` step.
    if (rgfwCheckoutPresent(b)) {
        const rgfw_dep = b.dependency("rgfw", .{
            .target = target,
            .optimize = optimize,
            .rgfw_opengl = true,
        });
        const rgfw_mod = rgfw_dep.module("rgfw");
        const api_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("tests/test.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "gl", .module = gl_module },
                    .{ .name = "rgfw", .module = rgfw_mod },
                },
            }),
        });
        const state_parameters_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("tests/test_state_parameters.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .imports = &.{
                    .{ .name = "gl", .module = gl_module },
                    .{ .name = "rgfw", .module = rgfw_mod },
                },
            }),
        });
        test_step.dependOn(&b.addRunArtifact(api_tests).step);
        test_step.dependOn(&b.addRunArtifact(state_parameters_tests).step);
    } else {
        const note_options = b.addOptions();
        note_options.addOption([]const u8, "rgfw_path", "../rgfw");
        const note_mod = b.createModule(.{
            .root_source_file = b.path("tests/test_gl_missing.zig"),
            .target = target,
            .optimize = optimize,
        });
        note_mod.addOptions("build_paths", note_options);
        const note_exe = b.addExecutable(.{
            .name = "test-gl-missing",
            .root_module = note_mod,
        });
        test_step.dependOn(&b.addRunArtifact(note_exe).step);
    }
}
