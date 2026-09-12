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
    const api_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "gl", .module = gl_module },
            },
        }),
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
    test_step.dependOn(&b.addRunArtifact(api_tests).step);
}
