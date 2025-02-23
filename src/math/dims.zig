const std = @import("std");

const Pos = @import("pos.zig").Pos;

pub const Dims = struct {
    width: i32,
    height: i32,

    pub fn init(width: i32, height: i32) Dims {
        return Dims{ .width = width, .height = height };
    }

    pub fn numTiles(dims: *const Dims) i32 {
        return dims.width * dims.height;
    }

    pub fn isWithinBounds(dims: *const Dims, position: Pos) bool {
        return position.x >= 0 and position.y >= 0 and position.x < dims.width and position.y < dims.height;
    }

    pub fn toIndex(dims: *const Dims, position: Pos) i32 {
        return @as(i32, @intCast(position.x)) + @as(i32, @intCast(position.y)) * dims.width;
    }

    pub fn fromIndex(dims: *const Dims, index: i32) Pos {
        const x = @as(i32, @intCast(@mod(index, dims.width)));
        const y = @as(i32, @intCast(@divFloor(index, dims.width)));
        return Pos.init(x, y);
    }

    pub fn clamp(dims: *const Dims, pos: Pos) Pos {
        const new_x = @min(@as(i32, @intCast(dims.width)) - 1, @max(0, pos.x));
        const new_y = @min(@as(i32, @intCast(dims.height)) - 1, @max(0, pos.y));
        return Pos.init(new_x, new_y);
    }

    pub fn scale(dims: Dims, x_scaler: i32, y_scaler: i32) Dims {
        return Dims.init(dims.width * x_scaler, dims.height * y_scaler);
    }

    pub fn iter(dims: Dims) DimIter {
        return DimIter.init(dims);
    }
};

pub const DimIter = struct {
    x: i32 = 0,
    y: i32 = 0,
    dims: Dims,

    pub fn init(dims: Dims) DimIter {
        return DimIter{ .dims = dims };
    }

    pub fn next(dim_iter: *DimIter) ?Pos {
        dim_iter.x += 1;

        if (dim_iter.x >= dim_iter.dims.width) {
            dim_iter.x = 0;
            dim_iter.y += 1;
        }

        if (dim_iter.y >= dim_iter.dims.height) {
            return null;
        }

        return Pos.init(@intCast(dim_iter.x), @intCast(dim_iter.y));
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
