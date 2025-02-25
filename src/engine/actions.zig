const std = @import("std");
const print = std.debug.print;

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

    return true;
}

fn resolveActionPlaying(game: *Game, input_action: InputAction) !void {
    _ = input_action; // autofix
    _ = game; // autofix

}

fn resolveActionUse(game: *Game, input_action: InputAction) !void {
    _ = input_action; // autofix
    _ = game; // autofix

}
