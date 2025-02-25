const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const core = @import("core");
const MoveType = core.movement.MoveType;
const MoveMode = core.movement.MoveMode;

const g = @import("game.zig");
const Game = g.Game;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;

const messaging = @import("messaging.zig");
const Msg = messaging.Msg;
const MsgType = messaging.MsgType;

const utils = @import("utils");
const Id = utils.comp.Id;

pub fn resolveMsg(game: *Game, msg: Msg) !void {
    switch (msg) {
        .startLevel => try resolveStartLevel(game),

        .tryMove => |args| try resolveTryMove(args.id, args.dir, args.amount, game),
        .move => |args| try resolveMove(args.id, args.move_type, args.move_mode, args.pos, game),

        else => {},
    }
}

fn resolveStartLevel(game: *Game) !void {
    // try game.level.updateAllFov();

    // Clear every entities turn, as they may have done level setup steps that don't count as a turn.
    for (game.level.entities.turn.ids.items) |id| {
        game.level.entities.turn.set(id, core.entities.Turn.init());
    }
}

fn resolveMove(id: Id, move_type: MoveType, move_mode: MoveMode, pos: Pos, game: *Game) !void {
    _ = move_mode; // autofix
    const start_pos = game.level.entities.pos.get(id);

    game.level.entities.pos.set(id, pos);
    // try game.level.updateAllFov();
    // _ = changed_pos; // autofix
    // const changed_pos = !std.meta.eql(start_pos, pos);

    // This is cleared in the start of the next turn when the game is stepped.
    game.level.entities.turn.getPtr(id).*.blink = move_type == MoveType.blink;

    // For teleportations (blink) leave the current facing, and do not set facing for
    // entities without a 'facing' component. Otherwise update facing after move.
    if (move_type != MoveType.blink and game.level.entities.facing.has(id)) {
        if (Direction.fromPositions(start_pos, pos)) |dir| {
            try game.log.now(.facing, .{ id, dir });
        }
    }
}

fn resolveTryMove(id: Id, dir: Direction, amount: usize, game: *Game) !void {

    // NOTE if this does happen, consider making amount == 0 a Msg.pass.
    std.debug.assert(amount > 0);

    const move_mode = game.level.entities.next_move_mode.get(id);

    const start_pos = game.level.entities.pos.get(id);
    const move_pos = dir.move(start_pos);

    game.level.entities.move_mode.set(id, move_mode);
    // const collision = game.level.checkCollision(start_pos, dir);
    // _ = collision; // autofix

    // // NOTE handle blink and Misc move types as well.
    // if (collision.hit()) {
    //     const stance = game.level.entities.stance.get(id);
    //     const can_jump = move_mode == MoveMode.run and stance != Stance.crouching;
    //     const jumpable_wall = collision.wall != null and !collision.wall.?.blocked_tile and collision.wall.?.height == .short;
    //     const jumped_wall = jumpable_wall and can_jump;

    //     if (jumped_wall) {
    //         // NOTE land roll flag could be checks to move one more tile here. Generate another move msg.
    //         try game.log.now(.vaultWall, .{ id, start_pos, move_pos });
    //         try game.log.now(.move, .{ id, MoveType.vaultWall, move_mode, move_pos });
    //     } else if (collision.wall == null and collision.entity != null and game.level.entities.typ.get(collision.entity.?) == .column) {
    //         try game.log.now(.pushed, .{ id, collision.entity.?, dir });
    //         // NOTE maybe its better to not walk into the column, like you pushed it over instead? Easier in the code at least.
    //         //try game.log.now(.move, .{ id, MoveType.move, move_mode, move_pos });
    //     } else {
    //         // We hit a wall. Generate messages about this, but don't move the entity.
    //         try game.log.now(.faceTowards, .{ id, move_pos });
    //         try game.log.now(.collided, .{ id, move_pos });
    //     }
    // } else {
    //     // No collision, just move to location.
    //     try game.log.now(.move, .{ id, MoveType.move, move_mode, move_pos });
    //     if (amount > 1) {
    //         try game.log.now(.tryMove, .{ id, dir, amount - 1 });
    //     }
    // }

    try game.log.now(.move, .{ id, MoveType.move, move_mode, move_pos });
    if (amount > 1) {
        try game.log.now(.tryMove, .{ id, dir, amount - 1 });
    }
}
