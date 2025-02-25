pub const config = @import("config.zig");
pub const level = @import("level.zig");
pub const entities = @import("entities.zig");
pub const movement = @import("movement.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
