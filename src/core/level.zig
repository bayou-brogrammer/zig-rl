const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const board = @import("board");
const Map = board.map.Map;

const entities = @import("entities.zig");
const Entities = entities.Entities;

pub const Level = struct {
    map: Map,
    entities: Entities,

    pub fn init(map: Map, ents: Entities) Level {
        return Level{ .map = map, .entities = ents };
    }

    pub fn deinit(level: *Level, allocator: Allocator) void {
        level.map.deinit(allocator);
        level.entities.deinit(allocator);
    }

    pub fn empty(allocator: Allocator) Level {
        return Level.init(Map.empty(), Entities.init(allocator));
    }
};
