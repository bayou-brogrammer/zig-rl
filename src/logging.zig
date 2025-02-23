const std = @import("std");
const options = @import("build_options");

// NOTE this code came from Bork originally.
// https://github.com/kristoff-it/bork/commit/b427c9d19b7f57b5152e7bc337d98b7629b889f4
var log_file: ?std.fs.File = null;

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @Type(std.builtin.Type.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const l = log_file orelse return;
    const scope_prefix = "(" ++ @tagName(scope) ++ "): ";
    const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const writer = l.writer();
    writer.print(prefix ++ format ++ "\n", args) catch return;
}

pub fn setup() void {
    log_file = std.io.getStdErr();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    setup_internal() catch {
        log_file = null;
    };
}

fn setup_internal() !void {
    const log_path = "rrl.log";
    const file = try std.fs.cwd().createFile(log_path, .{ .truncate = false });
    const end = try file.getEndPos();
    try file.seekTo(end);

    log_file = file;
}
