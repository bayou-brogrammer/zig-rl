const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const core = @import("core");
const Config = core.config.Config;
const MoveMode = core.movement.MoveMode;
const MoveType = core.movement.MoveType;
const Entities = core.entities.Entities;

const Name = core.entities.Name;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;
const Dims = math.dims.Dims;

const messaging = @import("messaging.zig");
const MsgLog = messaging.MsgLog;

pub fn spawnPlayer(entities: *Entities, log: *MsgLog, config: *const Config, allocator: Allocator) !void {
    _ = config; // autofix
    const id = Entities.player_id;
    entities.ids.set(id);

    try entities.addBasicComponents(allocator, id, Pos.init(0, 0), .player, .player);

    entities.blocking.getPtr(id).* = true;
    try entities.move_mode.insert(allocator, id, MoveMode.walk);
    try entities.next_move_mode.insert(allocator, id, MoveMode.walk);
    try entities.facing.insert(allocator, id, Direction.right);

    try log.log(.spawn, .{ id, Name.player });
    // try log.log(.stance, .{ id, entities.stance.get(id) });
    try log.log(.facing, .{ id, entities.facing.get(id) });
    try log.log(.move, .{ id, MoveType.blink, MoveMode.walk, Pos.init(10, 10) });
}
