const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const board = @import("board");
const Tile = board.tile.Tile;

const engine = @import("engine");
const Game = engine.game.Game;

const drawing = @import("drawing");
const DrawCmd = drawing.drawcmd.DrawCmd;

const math = @import("math");
const Rect = math.rect.Rect;
const Pos = math.pos.Pos;
const Color = math.utils.Color;

pub const Painter = struct {
    area: Rect,
    drawcmds: *ArrayList(DrawCmd),
};

pub fn renderLevel(game: *Game, painter: *Painter) !void {
    try renderMapLow(game, painter);
}

fn renderMapLow(game: *Game, painter: *Painter) !void {
    var y: i32 = 0;
    while (y < game.level.map.height) : (y += 1) {
        var x: i32 = 0;
        while (x < game.level.map.width) : (x += 1) {
            const pos = Pos.init(x, y);
            const tile = game.level.map.get(pos);

            // try painter.drawcmds.append(DrawCmd.spriteCmd(open_tile_sprite, Color.white(), pos));
            if (tile.impassable) {
                try painter.drawcmds.append(DrawCmd.textCmd("X", pos, Color.white(), 1));
            } else {
                try painter.drawcmds.append(DrawCmd.textCmd(".", pos, Color.white(), 1));
            }

            // else if (tile.center.material == Tile.Material.rubble) {
            //     try painter.drawcmds.append(DrawCmd.textCmd("X", pos, Color.white(), 1));
            // } else if (tile.center.material == Tile.Material.grass) {
            //     try painter.drawcmds.append(DrawCmd.textCmd("X", pos, Color.white(), 1));
            // }
        }
    }
}
