const std = @import("std");
const print = std.debug.print;

const core = @import("core");
const Entities = core.entities.Entities;

const math = @import("math");
const Direction = math.direction.Direction;
const Pos = math.pos.Pos;

const g = @import("game.zig");
const Game = g.Game;

pub const InputAction = union(enum) {
    esc,
    none,
    cursorReturn,
    moveTowardsCursor,

    move: Direction,
    face: Direction,
    walk,

    pub fn canTakeTurn(input_action: InputAction) bool {
        switch (input_action) {
            .move,
            .face,
            .moveTowardsCursor,
            => {
                return true;
            },

            else => {
                return false;
            },
        }
    }
};

pub fn resolveAction(game: *Game, input_action: InputAction) !void {
    const resolved = try resolveActionUniversal(game, input_action);

    if (!resolved) {
        switch (game.settings.state) {
            .finishedLevel => {},
            .startNewLevel => {},
            .use => try resolveActionUse(game, input_action),
            .playing => try resolveActionPlaying(game, input_action),
        }
    }
}

fn resolveActionUniversal(game: *Game, input_action: InputAction) !bool {
    _ = input_action; // autofix

    _ = game; // autofix}

    return false;
}

fn resolveActionPlaying(game: *Game, input_action: InputAction) !void {
    switch (input_action) {
        .move => |dir| try game.log.log(.tryMove, .{ Entities.player_id, dir, game.level.entities.next_move_mode.get(Entities.player_id).moveAmount() }),

        .face => |dir| try game.log.log(.facing, .{ Entities.player_id, dir }),

        // .cursorToggle => try cursorToggle(game),
        // .cursorMove => |args| try cursorMove(game, args.dir, args.is_relative, args.is_long),
        // .cursorReturn => cursorReturn(game),

        else => {},
    }
}

fn resolveActionUse(game: *Game, input_action: InputAction) !void {
    _ = input_action; // autofix
    _ = game; // autofix

}

fn cursorMove(game: *Game, dir: Direction, is_relative: bool, is_long: bool) !void {
    _ = is_long; // autofix
    std.debug.assert(game.settings.mode == .cursor);
    const player_pos = game.level.entities.pos.get(Entities.player_id);
    const cursor_pos = game.settings.mode.cursor.pos;

    const dist: i32 = 1;
    // if (is_long) {
    //     dist = game.config.cursor_fast_move_dist;
    // }

    const dir_move: Pos = dir.intoMove().scale(dist);

    var new_pos: Pos = undefined;
    if (is_relative) {
        new_pos = player_pos.add(dir_move);
    } else {
        new_pos = cursor_pos.add(dir_move);
    }

    new_pos = game.level.map.dims().clamp(new_pos);

    try game.log.log(.cursorMove, new_pos);
    game.settings.mode.cursor.pos = new_pos;
}
