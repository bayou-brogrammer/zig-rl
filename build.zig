const std = @import("std");
const builtin = @import("builtin");
const Import = std.Build.Module.Import;

const ModulePair = struct {
    name: []const u8,
    module: *std.Build.Module,
};

var modules: []ModulePair = undefined;

// This should be provided on the command line, but I don't know how to do that.
const profiling_default: bool = false;
const use_profiling = builtin.os.tag != .windows and profiling_default;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const step_options = b.addOptions();

    try initModules(b, target, optimize);

    buildMain(b, target, optimize, step_options);

    // const sdl_dep = b.dependency("sdl", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // const sdl_lib = sdl_dep.artifact("SDL3");
    // const sdl_ttf_lib = sdl_dep.artifact("SDL3_ttf");
    // const sdl_for_libs = sdl_dep.artifact("SDL3-for-libs");

    // exe.root_module.linkLibrary(sdl_lib);
    // exe.root_module.linkLibrary(sdl_ttf_lib);
    // exe.root_module.linkLibrary(sdl_for_libs);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_exe_unit_tests.step);
}

fn buildMain(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, step_options: *std.Build.Step.Options) void {
    const exe = b.addExecutable(.{
        .name = "rl",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    exe.linkLibC();
    exe.root_module.addOptions("build_options", step_options);
    addRemotery(exe);

    addModules(b, exe);
    b.installArtifact(exe);

    // Run the zig version of the game
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const rl_step = b.step("rl", "Build the zig version of the game");
    // rl_step.dependOn(&exe.step);
    rl_step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the zig version of the game");
    run_step.dependOn(&run_cmd.step);
}

fn initModules(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
    const step_options = b.addOptions();
    step_options.addOption(bool, "remotery", use_profiling);

    const sdl3_module = try initSDL(b, target, optimize);

    const math = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/math/math.zig" },
        .imports = &[_]Import{},
    });

    const utils = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/utils/utils.zig" },
        .imports = &[_]Import{
            .{ .name = "math", .module = math },
        },
    });

    const core = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/core/core.zig" },
        .imports = &[_]Import{
            .{ .name = "utils", .module = utils },
            .{ .name = "math", .module = math },
            // .{ .name = "board", .module = board },
            // .{ .name = "prof", .module = prof },
        },
    });

    const engine = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/engine/engine.zig" },
        .imports = &[_]Import{
            .{ .name = "core", .module = core },
            .{ .name = "math", .module = math },
            .{ .name = "utils", .module = utils },
            // .{ .name = "board", .module = board },
            // .{ .name = "prof", .module = prof },
        },
    });

    const display = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/display/display.zig" },
        .imports = &[_]Import{
            .{ .name = "sdl3", .module = sdl3_module },
            .{ .name = "core", .module = core },
            .{ .name = "math", .module = math },
            // .{ .name = "drawing", .module = drawing },
            .{ .name = "utils", .module = utils },
            // .{ .name = "board", .module = board },
            .{ .name = "engine", .module = engine },
            // .{ .name = "prof", .module = prof },
            // .{ .name = "scripting", .module = scripting },
        },
    });

    var module_list = std.ArrayList(ModulePair).init(b.allocator);
    try module_list.append(ModulePair{ .name = "sdl3", .module = sdl3_module });
    try module_list.append(ModulePair{ .name = "math", .module = math });
    try module_list.append(ModulePair{ .name = "utils", .module = utils });
    try module_list.append(ModulePair{ .name = "core", .module = core });
    try module_list.append(ModulePair{ .name = "engine", .module = engine });
    try module_list.append(ModulePair{ .name = "display", .module = display });

    // Initialize global slice of modules with the allocated array list's items slice.
    modules = module_list.items;
}

fn initSDL(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Module {
    const font_dep = b.dependency("fonts", .{});
    const sdl_dep = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");
    const sdl_ttf_lib = sdl_dep.artifact("SDL3_ttf");
    const sdl_for_libs = sdl_dep.artifact("SDL3-for-libs");

    const sdl_module = b.addModule("sdl3", .{
        .root_source_file = b.addWriteFiles().add("src/lib.zig",
            \\pub usingnamespace @cImport({
            \\    @cInclude("SDL3/SDL.h");
            \\    @cInclude("SDL3_ttf/SDL_ttf.h");
            \\});
            \\pub const fonts = @import("fonts");
        ),
        .link_libc = true,
    });

    sdl_module.linkLibrary(sdl_lib);
    sdl_module.linkLibrary(sdl_ttf_lib);
    sdl_module.linkLibrary(sdl_for_libs);
    sdl_module.addImport("fonts", font_dep.module("fonts"));

    return sdl_module;
}

fn addModules(b: *std.Build, step: *std.Build.Step.Compile) void {
    const step_options = b.addOptions();
    step_options.addOption(bool, "remotery", use_profiling);

    for (modules) |module| {
        step.root_module.addImport(module.name, module.module);
    }
}

fn addRemotery(step: *std.Build.Step.Compile) void {
    if (use_profiling) {
        step.addIncludePath(.{ .cwd_relative = "deps/remotery" });
        step.addCSourceFile(.{ .file = .{"deps/remotery/Remotery.c"}, .flags = &[_][]const u8{
            "-DRMT_ENABLED=1 -pthread",
        } });
    }
}
