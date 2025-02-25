pub const actions = @import("actions.zig");
pub const game = @import("game.zig");
pub const input = @import("input.zig");
pub const messaging = @import("messaging.zig");
pub const resolve = @import("resolve.zig");
pub const settings = @import("settings.zig");
pub const procgen = @import("procgen.zig");
pub const spawn = @import("spawn.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
