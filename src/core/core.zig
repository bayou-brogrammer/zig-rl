pub const config = @import("config.zig");
pub const level = @import("level.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
