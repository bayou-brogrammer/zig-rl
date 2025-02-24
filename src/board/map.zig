const std = @import("std");
const Allocator = std.mem.Allocator;

const tile = @import("tile.zig");
const Tile = tile.Tile;

pub const Map = struct {
    width: i32,
    height: i32,
    tiles: []Tile,

    pub fn deinit(self: *Map, allocator: Allocator) void {
        allocator.free(self.tiles);
    }

    pub fn empty() Map {
        return Map{ .width = 0, .height = 0, .tiles = &.{} };
    }
};
