const std = @import("std");

const Pos = @import("pos.zig").Pos;

pub const Direction = enum {
    left,
    right,
    up,
    down,
    downLeft,
    downRight,
    upLeft,
    upRight,

    pub const directions = [8]Direction{ .downLeft, .left, .upLeft, .up, .upRight, .right, .downRight, .down };
    pub const cardinals = [4]Direction{ .left, .up, .right, .down };
    pub const ordinals = [4]Direction{ .leftUp, .leftDown, .rightUp, .rightDown };

    pub fn fromPosition(position: Pos) ?Direction {
        if (position.x == 0 and position.y == 0) {
            return null;
        } else if (position.x == 0 and position.y < 0) {
            return .up;
        } else if (position.x == 0 and position.y > 0) {
            return .down;
        } else if (position.x > 0 and position.y == 0) {
            return .right;
        } else if (position.x < 0 and position.y == 0) {
            return .left;
        } else if (position.x > 0 and position.y > 0) {
            return .downRight;
        } else if (position.x > 0 and position.y < 0) {
            return .upRight;
        } else if (position.x < 0 and position.y > 0) {
            return .downLeft;
        } else if (position.x < 0 and position.y < 0) {
            return .upLeft;
        } else {
            std.debug.panic("Direction should not exist for {}", .{position});
        }
    }

    pub fn fromPositions(start: Pos, end: Pos) ?Direction {
        const delta = end.sub(start);
        return fromPosition(delta);
    }

    pub fn reverse(self: Direction) Direction {
        return switch (self) {
            .left => .right,
            .right => .left,
            .up => .down,
            .down => .up,
            .downLeft => .upRight,
            .downRight => .upLeft,
            .upLeft => .downRight,
            .upRight => .downLeft,
        };
    }

    pub fn horiz(self: Direction) bool {
        switch (self) {
            .left, .right, .up, .down => return true,
            else => return false,
        }
    }

    pub fn diag(self: Direction) bool {
        return !self.horiz();
    }

    pub fn intoMove(self: Direction) Pos {
        return switch (self) {
            .left => Pos.init(-1, 0),
            .right => Pos.init(1, 0),
            .up => Pos.init(0, -1),
            .down => Pos.init(0, 1),
            .downLeft => Pos.init(-1, 1),
            .downRight => Pos.init(1, 1),
            .upLeft => Pos.init(-1, -1),
            .upRight => Pos.init(1, -1),
        };
    }

    pub fn fromF32(flt: f32) Direction {
        const index = @as(usize, @intFromFloat(flt * 8.0));
        const dirs = Direction.directions;
        return dirs[index];
    }

    pub fn move(self: Direction, position: Pos) Pos {
        return self.offsetPos(position, 1);
    }

    pub fn offsetPos(self: Direction, position: Pos, amount: i32) Pos {
        const mov = self.intoMove();
        return position.add(mov.scale(amount));
    }

    pub fn turnAmount(self: Direction, dir: Direction) i32 {
        const dirs = Direction.directions;
        const count = @as(i32, @intCast(dirs.len));

        // These are safe to unpack because 'dirs' contains all directions.
        const start_ix = @as(i32, @intCast(std.mem.indexOfScalar(Direction, dirs[0..], self).?));
        const end_ix = @as(i32, @intCast(std.mem.indexOfScalar(Direction, dirs[0..], dir).?));

        // absInt should always work with these indices.
        const ix_diff: i32 = @intCast(@abs(end_ix - start_ix));
        if (ix_diff < 4) {
            return end_ix - start_ix;
        } else if (end_ix > start_ix) {
            return (count - end_ix) + start_ix;
        } else {
            return (count - start_ix) + end_ix;
        }
    }

    pub fn clockwise(self: Direction) Direction {
        switch (self) {
            .left => return .upLeft,
            .right => return .downRight,
            .up => return .upRight,
            .down => return .downLeft,
            .downLeft => return .left,
            .downRight => return .down,
            .upLeft => return .up,
            .upRight => return .right,
        }
    }

    pub fn counterclockwise(self: Direction) Direction {
        switch (self) {
            .left => return .downLeft,
            .right => return .upRight,
            .up => return .upLeft,
            .down => return .downRight,
            .downLeft => return .down,
            .downRight => return .right,
            .upLeft => return .left,
            .upRight => return .up,
        }
    }

    pub fn isFacingPos(self: Direction, start: Pos, end: Pos) bool {
        return self == Direction.fromPositions(start, end);
    }

    pub fn continuePast(self: Pos, towards: Pos) ?Pos {
        if (Direction.fromPositions(self, towards)) |dir| {
            return dir.offsetPos(towards, 1);
        } else {
            return null;
        }
    }
};

test "test direction turn amount" {
    try std.testing.expectEqual(@as(i32, @intCast(-1)), Direction.up.turnAmount(Direction.upLeft));
    try std.testing.expectEqual(@as(i32, @intCast(1)), Direction.up.turnAmount(Direction.upRight));

    for (Direction.directions) |dir| {
        try std.testing.expectEqual(@as(i32, @intCast(0)), dir.turnAmount(dir));
    }

    try std.testing.expectEqual(@as(i32, @intCast(1)), Direction.down.turnAmount(Direction.downLeft));
    try std.testing.expectEqual(@as(i32, @intCast(-1)), Direction.down.turnAmount(Direction.downRight));

    try std.testing.expectEqual(@as(i32, @intCast(1)), Direction.left.turnAmount(Direction.upLeft));
    try std.testing.expectEqual(@as(i32, @intCast(-1)), Direction.left.turnAmount(Direction.downLeft));
}

test "test direction clockwise" {
    const dir = Direction.right;

    var index: usize = 0;
    while (index < 8) : (index += 1) {
        const new_dir = dir.clockwise();
        try std.testing.expectEqual(@as(i32, @intCast(1)), dir.turnAmount(new_dir));
    }
    try std.testing.expectEqual(Direction.right, dir);
}

test "test direction counterclockwise" {
    const dir = Direction.right;

    var index: usize = 0;
    while (index < 8) : (index += 1) {
        const new_dir = dir.counterclockwise();
        try std.testing.expectEqual(@as(i32, @intCast(-1)), dir.turnAmount(new_dir));
    }
    try std.testing.expectEqual(Direction.right, dir);
}

pub const Offset = enum {
    left,
    right,
    up,
    down,
    downLeft,
    downRight,
    upLeft,
    upRight,
    center,

    pub fn fromDirection(dir: Direction) Offset {
        return switch (dir) {
            .left => Offset.left,
            .right => Offset.right,
            .up => Offset.up,
            .down => Offset.down,
            .downLeft => Offset.downLeft,
            .downRight => Offset.downRight,
            .upLeft => Offset.upLeft,
            .upRight => Offset.upRight,
        };
    }

    pub fn toDirection(self: Offset) ?Direction {
        return switch (self) {
            .left => .left,
            .right => .right,
            .up => .up,
            .down => .down,
            .downLeft => .downLeft,
            .downRight => .downRight,
            .upLeft => .upLeft,
            .upRight => .upRight,
            .center => null,
        };
    }
};

pub const MoveDirection = enum {
    center,
    left,
    right,
    up,
    down,
    downLeft,
    downRight,
    upLeft,
    upRight,
};
