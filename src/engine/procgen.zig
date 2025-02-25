const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const DynamicBitSet = std.DynamicBitSet;
const Random = std.Random;
const BoundedArray = std.BoundedArray;

const core = @import("core");
const Level = core.level.Level;
const ConfigStr = core.config.ConfigStr;

const g = @import("game.zig");
const Game = g.Game;

const math = @import("math");
const Pos = math.pos.Pos;
const Dims = math.dims.Dims;
const rand = math.rand;
const Direction = math.direction.Direction;

const utils = @import("utils");
const Id = utils.comp.Id;

pub const MapConfig = struct {
    width: i32 = 20,
    height: i32 = 20,
    player: ?Pos = Pos.init(0, 0),
    map_type: union(enum) { empty: void, procgen: ConfigStr, vault: i32, layout: ConfigStr },

    pub fn empty() MapConfig {
        return MapConfig{ .map_type = .empty };
    }

    pub fn procgen(file_name: []const u8) !MapConfig {
        var map_config = try core.config.ConfigStr.init(0);
        try map_config.appendSlice(file_name);
        return MapConfig{ .map_type = .{ .procgen = map_config } };
    }
};

pub fn generateMap(game: *Game, keep_player: bool, map_config: MapConfig) !void {
    _ = keep_player; // autofix
    const ids: ?utils.comp.Ids = null;
    // if (keep_player) {
    //     ids = utils.comp.Ids.initEmpty();
    //     ids.?.set(Entities.player_id);
    //     const item_ids = game.level.entities.inventory.get(Entities.player_id).itemIds();
    //     for (item_ids.constSlice()) |item_id| {
    //         ids.?.set(item_id);
    //     }
    // }

    print("generateMap {}\n", .{map_config.map_type});

    switch (map_config.map_type) {
        .procgen => {},
        .vault => {},
        .layout => {},
        .empty => {
            try game.startEmptyLevel(map_config.width, map_config.height, ids);

            // if (map_config.player) |player_pos| {
            //     try game.log.log(.move, .{ Entities.player_id, .blink, .walk, player_pos });
            // }
        },
    }

    try game.resolveMessages();
    try game.log.log(.startLevel, .{});
}
