pub const map = @import("map.zig");
pub const tile = @import("tile.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
