const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const board = @import("board");
const Map = board.map.Map;

pub const Level = struct {
    map: Map,

    pub fn init(map: Map) Level {
        return Level{ .map = map };
    }

    pub fn deinit(level: *Level, allocator: Allocator) void {
        level.map.deinit(allocator);
    }

    pub fn empty() Level {
        return Level.init(Map.empty());
    }
};
