const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const g = @import("game.zig");
const Game = g.Game;

const messaging = @import("messaging.zig");
const Msg = messaging.Msg;
const MsgType = messaging.MsgType;

pub fn resolveMsg(game: *Game, msg: Msg) !void {
    switch (msg) {
        .startLevel => try resolveStartLevel(game),
        else => {},
    }
}

fn resolveStartLevel(game: *Game) !void {
    print("resolveStartLevel\n", .{});
    _ = game; // autofix
    // try game.level.updateAllFov();

    // // Clear every entities turn, as they may have done level setup steps that don't count as a turn.
    // for (game.level.entities.turn.ids.items) |id| {
    //     game.level.entities.turn.set(id, core.entities.Turn.init());
    // }
}
