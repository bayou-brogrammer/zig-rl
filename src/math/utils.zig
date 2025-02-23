const std = @import("std");

const Pos = @import("pos.zig").Pos;

pub const ASCII_START: i32 = 32;
pub const ASCII_END: i32 = 127;

pub const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn white() Color {
        return Color.init(255, 255, 255, 255);
    }

    pub fn black() Color {
        return Color.init(0, 0, 0, 255);
    }

    pub fn transparent() Color {
        return Color.init(0, 0, 0, 0);
    }
};

pub fn saturatedSubtraction(amount: u64, delta: u64) struct { result: u64, delta: u64 } {
    if (amount > delta) {
        return .{ .result = amount - delta, .delta = 0 };
    } else {
        return .{ .result = 0, .delta = delta - amount };
    }
}

fn cmpPosAsc(start: Pos, a: Pos, b: Pos) bool {
    return start.distance(a) < start.distance(b);
}

fn cmpPosDsc(start: Pos, a: Pos, b: Pos) bool {
    return start.distance(a) > start.distance(b);
}

pub fn sortByDistanceToAsc(pos: Pos, positions: []Pos) void {
    std.sort.heap(Pos, positions, pos, cmpPosAsc);
}

pub fn sortByDistanceToDsc(pos: Pos, positions: []Pos) void {
    std.sort.heap(Pos, positions, pos, cmpPosDsc);
}
