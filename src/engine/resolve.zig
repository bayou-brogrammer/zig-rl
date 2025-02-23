const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const g = @import("game.zig");
const Game = g.Game;

const messaging = @import("messaging.zig");
const Msg = messaging.Msg;
const MsgType = messaging.MsgType;

pub fn resolveMsg(game: *Game, msg: Msg) !void {
    _ = game; // autofix
    switch (msg) {
        else => {},
    }
}
