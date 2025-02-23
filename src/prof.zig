const std = @import("std");

const has_profiling = @import("options").remotery;

pub const ProfilerError = error{
    RemoteryError,
};

pub const Prof = blk: {
    if (has_profiling) {
        break :blk struct {
            pub const rmt = @cImport({
                @cInclude("Remotery.pp.h");
            });

            remotery: ?*rmt.Remotery = undefined,
            running: bool = false,
            err: c_uint = 0,

            pub fn start(prof: *Prof) ProfilerError!void {
                const err = rmt._rmt_CreateGlobalInstance(&prof.remotery);
                if (err != 0) {
                    prof.err = err;
                    std.debug.print("Remotery error {}\n", .{err});
                    return ProfilerError.RemoteryError;
                } else {
                    std.debug.print("running profiling\n", .{});
                    prof.running = true;
                }
            }

            pub fn deinit(prof: *Prof) void {
                if (prof.running) {
                    _ = rmt._rmt_DestroyGlobalInstance(prof.remotery);
                }
            }

            pub fn log(text: [*c]const u8) void {
                rmt._rmt_LogText(text);
            }

            pub fn scope(name: [*c]const u8) void {
                rmt._rmt_BeginCPUSample(name, 0, null);
            }

            pub fn end() void {
                rmt._rmt_EndCPUSample();
            }
        };
    } else {
        break :blk struct {
            running: bool = false,
            err: c_uint = 0,

            pub fn start(prof: *Prof) ProfilerError!void {
                _ = prof;
            }

            pub fn deinit(prof: *Prof) void {
                _ = prof;
            }

            pub fn log(text: [*c]const u8) void {
                _ = text;
            }

            pub fn scope(name: [*c]const u8) void {
                _ = name;
            }

            pub fn end() void {}
        };
    }
};
