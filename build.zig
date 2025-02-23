const std = @import("std");

const builtin = @import("builtin");
const Builder = std.Build;
const Import = std.Build.Module.Import;

// This should be provided on the command line, but I don't know how to do that.
const profiling_default: bool = false;
const use_profiling = builtin.os.tag != .windows and profiling_default;

const ModulePair = struct {
    name: []const u8,
    module: *std.Build.Module,
};

var modules: []ModulePair = undefined;
var tcl_extension: ModulePair = undefined;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const step_options = b.addOptions();

    try initModules(b);

    if (builtin.os.tag == .windows) {
        // Move dlls to bin directory so Windows can find them.
        b.installFile("lib/SDL2.dll", "bin/SDL2.dll");
        b.installFile("lib/SDL2_ttf.dll", "bin/SDL2_ttf.dll");
        b.installFile("lib/SDL2_image.dll", "bin/SDL2_image.dll");
    }

    buildMain(b, target, mode, step_options);
    // buildTests(b, target, mode, step_options);

    // buildTclExtension(b, target, mode, step_options);
    try runAtlas(b, target, mode);
}

// Main Executable
fn buildMain(b: *Builder, target: std.Build.ResolvedTarget, mode: std.builtin.Mode, step_options: *std.Build.Step.Options) void {
    const exe = b.addExecutable(.{
        .name = "rustrl",
        .root_source_file = .{ .cwd_relative = "main.zig" },
        .target = target,
        .optimize = mode,
        //.use_llvm = false,
        //.use_lld = false,
    });

    exe.linkLibC();

    if (builtin.os.tag == .windows) {
        exe.linkSystemLibrary("tcl86");
    } else {
        exe.linkSystemLibrary("tcl");
    }

    exe.root_module.addOptions("build_options", step_options);

    addRemotery(exe);

    addCDeps(exe);
    linkTcl(b, exe);

    exe.root_module.addImport("zigtcl", tcl_extension.module);
    addModules(b, exe);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    exe.addIncludePath(.{ .cwd_relative = "deps/SDL2/include" });
    exe.addLibraryPath(.{ .cwd_relative = "lib" });
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_image");

    exe.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });

    const rustrl_step = b.step("rustrl", "Build the zig version of the game");
    //rustrl_step.dependOn(&exe.step);
    rustrl_step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the zig version of the game");
    run_step.dependOn(&run_cmd.step);
}

// Unit tests
fn buildTests(b: *Builder, target: std.Build.ResolvedTarget, mode: std.builtin.Mode, step_options: *std.Build.Step.Options) void {
    const board_step = buildModuleTest(b, "board"[0..], "src/board/board.zig"[0..], target, mode, step_options);
    const engine_step = buildModuleTest(b, "engine"[0..], "src/engine/engine.zig"[0..], target, mode, step_options);
    const core_step = buildModuleTest(b, "core"[0..], "src/core/core.zig"[0..], target, mode, step_options);
    const drawing_step = buildModuleTest(b, "drawing"[0..], "src/drawing/drawing.zig"[0..], target, mode, step_options);
    const gui_step = buildModuleTest(b, "gui"[0..], "src/gui/gui.zig"[0..], target, mode, step_options);
    const math_step = buildModuleTest(b, "math"[0..], "src/math/math.zig"[0..], target, mode, step_options);
    const utils_step = buildModuleTest(b, "utils"[0..], "src/utils/utils.zig"[0..], target, mode, step_options);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(board_step);
    test_step.dependOn(engine_step);
    test_step.dependOn(core_step);
    test_step.dependOn(drawing_step);
    test_step.dependOn(gui_step);
    test_step.dependOn(math_step);
    test_step.dependOn(utils_step);
}

fn buildModuleTest(b: *Builder, name: []const u8, path: []const u8, target: std.Build.ResolvedTarget, mode: std.builtin.Mode, step_options: *std.Build.Step.Options) *std.Build.Step {
    const exe_tests = b.addTest(.{
        .name = name,
        .root_source_file = .{ .cwd_relative = path },
        .target = target,
        .optimize = mode,
    });

    exe_tests.root_module.addOptions("build_options", step_options);

    addCDeps(exe_tests);
    linkTcl(b, exe_tests);

    addRemotery(exe_tests);

    exe_tests.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });
    exe_tests.addIncludePath(.{ .cwd_relative = "deps/SDL2/include" });
    exe_tests.addIncludePath(.{ .cwd_relative = "deps/wfc" });
    exe_tests.addLibraryPath(.{ .cwd_relative = "lib" });
    exe_tests.linkSystemLibrary("SDL2");
    exe_tests.linkSystemLibrary("SDL2_ttf");
    exe_tests.linkSystemLibrary("SDL2_image");

    addModules(b, exe_tests);
    exe_tests.linkLibC();

    const run_tests = b.addRunArtifact(exe_tests);
    run_tests.step.dependOn(b.getInstallStep());

    const test_step = b.step(name, "Run unit tests for this module");
    test_step.dependOn(&run_tests.step);

    return test_step;
}

// Shared Library TCL Extension
fn buildTclExtension(b: *Builder, target: std.Build.ResolvedTarget, mode: std.builtin.Mode, step_options: *std.Build.Step.Options) void {
    const lib = b.addSharedLibrary(
        .{ .name = "rrl", .root_source_file = .{ .cwd_relative = "tclrrl.zig" }, .target = target, .optimize = mode },
    );
    lib.linkLibC();

    lib.root_module.addOptions("build_options", step_options);

    addRemotery(lib);

    addCDeps(lib);
    linkTcl(b, lib);

    lib.root_module.addImport("zigtcl", tcl_extension.module);
    addModules(b, lib);

    b.installArtifact(lib);

    const lib_step = b.step("tcl", "Build TCL extension");
    lib_step.dependOn(&lib.step);
}

// Run Atlas Process
fn runAtlas(b: *Builder, target: std.Build.ResolvedTarget, mode: std.builtin.Mode) !void {
    const exe = b.addExecutable(.{ .name = "atlas", .target = target, .optimize = mode });
    exe.linkLibC();

    // C source
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/main.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/bitmap.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/util.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/lib/stb/stb_image.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/lib/stb/stb_image_write.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/lib/stb/stb_rect_pack.c" }, .flags = &[_][]const u8{} });
    exe.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/atlas/lib/stb/stb_truetype.c" }, .flags = &[_][]const u8{} });

    // C include paths
    exe.addIncludePath(.{ .cwd_relative = "deps/atlas" });
    exe.addIncludePath(.{ .cwd_relative = "deps/atlas/lib/stb" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    var dir = try std.fs.cwd().openDir("data/sprites/animations/", .{ .iterate = true });
    defer dir.close();
    var walker = dir.iterate();
    while (try walker.next()) |entry| {
        if (entry.kind == .directory) {
            const path = try std.mem.join(b.allocator, "/", &[_][]const u8{ "data/sprites/animations", entry.name });
            defer b.allocator.free(path);
            run_cmd.addArg(path);
        }
    }
    run_cmd.addArg("data/sprites/misc/"[0..]);
    run_cmd.addArg("data/sprites/UI/"[0..]);
    run_cmd.addArg("data/sprites/tileset/"[0..]);

    run_cmd.addArg("--imageout"[0..]);
    run_cmd.addArg("data/spriteAtlas.png"[0..]);
    run_cmd.addArg("--textout"[0..]);
    run_cmd.addArg("data/spriteAtlas.txt"[0..]);

    const tileset_cmd = b.addSystemCommand(&[_][]const u8{"tclsh"});
    tileset_cmd.addArg("scripts/add_tiles_to_atlas.tcl"[0..]);
    tileset_cmd.addArg("data/spriteAtlas.txt"[0..]);
    tileset_cmd.addArg("data/tile_locations.txt"[0..]);
    tileset_cmd.step.dependOn(&run_cmd.step);

    const run_step = b.step("atlas", "Run the atlas creation process");
    run_step.dependOn(&tileset_cmd.step);
}

fn initModules(b: *Builder) !void {
    const zigtcl = b.createModule(.{ .root_source_file = .{ .cwd_relative = "deps/zig_tcl/zigtcl.zig" }, .imports = &.{} });
    zigtcl.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });
    tcl_extension = ModulePair{ .name = "zigtcl", .module = zigtcl };

    const step_options = b.addOptions();
    step_options.addOption(bool, "remotery", use_profiling);

    const prof = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/prof.zig" },
        .imports = &[_]Import{.{
            .name = "options",
            .module = step_options.createModule(),
        }},
    });

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
            .{ .name = "prof", .module = prof },
        },
    });

    const drawing = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/drawing/drawing.zig" },
        .imports = &[_]Import{
            .{ .name = "math", .module = math },
            .{ .name = "utils", .module = utils },
        },
    });

    var engine = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/engine/engine.zig" },
        .imports = &[_]Import{
            .{ .name = "core", .module = core },
            .{ .name = "math", .module = math },
            .{ .name = "utils", .module = utils },
            .{ .name = "prof", .module = prof },
        },
    });
    engine.addIncludePath(.{ .cwd_relative = "deps/wfc" });
    engine.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/wfc/wfc.c" }, .flags = &[_][]const u8{"-DWFC_USE_STB"} });

    var gui = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/gui/gui.zig" },
        .imports = &[_]Import{
            .{ .name = "core", .module = core },
            .{ .name = "math", .module = math },
            .{ .name = "drawing", .module = drawing },
            .{ .name = "utils", .module = utils },
            .{ .name = "engine", .module = engine },
            .{ .name = "prof", .module = prof },
        },
    });
    gui.addIncludePath(.{ .cwd_relative = "deps/SDL2/include" });

    var module_list = std.ArrayList(ModulePair).init(b.allocator);

    try module_list.append(ModulePair{ .name = "prof", .module = prof });
    try module_list.append(ModulePair{ .name = "math", .module = math });
    try module_list.append(ModulePair{ .name = "utils", .module = utils });
    try module_list.append(ModulePair{ .name = "core", .module = core });
    try module_list.append(ModulePair{ .name = "drawing", .module = drawing });
    try module_list.append(ModulePair{ .name = "engine", .module = engine });
    try module_list.append(ModulePair{ .name = "gui", .module = gui });

    // Initialize global slice of modules with the allocated array list's items slice.
    modules = module_list.items;
}

fn addModules(b: *Builder, step: *std.Build.Step.Compile) void {
    const step_options = b.addOptions();
    step_options.addOption(bool, "remotery", use_profiling);

    for (modules) |module| {
        step.root_module.addImport(module.name, module.module);
    }
}

fn addCDeps(step: *std.Build.Step.Compile) void {
    // Add SDL2 dependency
    if (builtin.os.tag == .windows) {
        //step.addLibraryPath(.{ .cwd_relative = "deps/SDL2/lib"});
        //step.addLibraryPath(.{ .cwd_relative = "."});
        //step.addLibraryPath(.{ .cwd_relative = "lib" });
        step.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });
        step.addIncludePath(.{ .cwd_relative = "deps/SDL2/include" });
    }
    step.addIncludePath(.{ .cwd_relative = "deps/SDL2/include" });
    step.linkSystemLibrary("SDL2");
    step.linkSystemLibrary("SDL2_ttf");
    step.linkSystemLibrary("SDL2_image");

    //step.addIncludePath(.{ .cwd_relative = "deps/wfc" });
    //step.addCSourceFile(.{ .file = .{ .cwd_relative = "deps/wfc/wfc.c" }, .flags = &[_][]const u8{"-DWFC_USE_STB"} });
}

fn addRemotery(step: *std.Build.Step.Compile) void {
    if (use_profiling) {
        step.addIncludePath(.{ .cwd_relative = "deps/remotery" });
        step.addCSourceFile(.{ .file = .{"deps/remotery/Remotery.c"}, .flags = &[_][]const u8{
            "-DRMT_ENABLED=1 -pthread",
        } });
    }
}

fn linkTcl(b: *Builder, step: *std.Build.Step.Compile) void {
    if (builtin.os.tag == .windows) {
        step.addLibraryPath(.{ .cwd_relative = "lib" });
        step.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });
        step.linkSystemLibrary("tcl86");
        b.installFile("lib/tcl86.dll", "bin/tcl86.dll");
    } else {
        step.addIncludePath(.{ .cwd_relative = "deps/tcl/include" });
        step.linkSystemLibrary("tcl");
        step.addObjectFile(.{ .cwd_relative = "deps/tcl/lib/libtclstub.a" });
    }
}
