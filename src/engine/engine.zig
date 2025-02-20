pub const game = @import("game.zig");
pub const input = @import("input.zig");
pub const messaging = @import("messaging.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
