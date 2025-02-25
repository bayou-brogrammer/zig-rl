const std = @import("std");
const Allocator = std.mem.Allocator;
const StaticBitSet = std.StaticBitSet;

const math = @import("math");
const Dims = math.dims.Dims;
const Pos = math.pos.Pos;

const Tile = @import("tile.zig").Tile;

pub const MAX_MAP_WIDTH: i32 = 80;
pub const MAX_MAP_HEIGHT: i32 = 80;
pub const MapBits = StaticBitSet(MAX_MAP_WIDTH * MAX_MAP_HEIGHT);

pub const Map = struct {
    width: i32,
    height: i32,
    tiles: []Tile,

    pub fn deinit(self: *Map, allocator: Allocator) void {
        allocator.free(self.tiles);
    }

    pub fn get(self: *const Map, position: Pos) Tile {
        const index = position.x + position.y * self.width;
        return self.tiles[@as(usize, @intCast(index))];
    }

    pub fn set(self: *Map, position: Pos, tile: Tile) void {
        const index = position.x + position.y * self.width;
        self.tiles[@as(usize, @intCast(index))] = tile;
    }

    pub fn fromSlice(tiles: []Tile, width: i32, height: i32) Map {
        return Map{ .tiles = tiles, .width = width, .height = height };
    }

    pub fn empty() Map {
        return Map{ .width = 0, .height = 0, .tiles = &.{} };
    }

    pub fn dims(map: *const Map) Dims {
        return Dims.init(@as(i32, @intCast(map.width)), @as(i32, @intCast(map.height)));
    }

    pub fn fromDims(width: i32, height: i32, allocator: Allocator) !Map {
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);

        const tiles = try allocator.alloc(Tile, @as(usize, @intCast(width * height)));
        @memset(tiles, Tile.empty());
        return Map.fromSlice(tiles, width, height);
    }
};
