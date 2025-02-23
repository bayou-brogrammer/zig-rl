const std = @import("std");
const print = std.debug.print;

pub const InputAction = union(enum) {
    esc,
    none,
    cursorReturn,
    moveTowardsCursor,
};
