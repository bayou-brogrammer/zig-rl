// SPDX-FileCopyrightText: © 2024 Mark Delk <jethrodaniel@gmail.com>
//
// SPDX-License-Identifier: Zlib

const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const intel_one_mono_dep = b.dependency("intel_one_mono", .{});

    const module = b.addModule("fonts", .{
        .root_source_file = b.path("src/lib.zig"),
    });
    {
        module.addAnonymousImport("regular.ttf", .{
            .root_source_file = intel_one_mono_dep.path("fonts/ttf/IntelOneMono-Regular.ttf"),
        });
        module.addAnonymousImport("bold.ttf", .{
            .root_source_file = intel_one_mono_dep.path("fonts/ttf/IntelOneMono-Bold.ttf"),
        });
    }

    {
        const tests = b.addTest(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
        });
        tests.root_module.addImport("fonts", module);

        const run_tests = b.addRunArtifact(tests);
        const step = b.step("test", "Run tests");
        step.dependOn(&run_tests.step);
        step.dependOn(b.getInstallStep());
    }
}
