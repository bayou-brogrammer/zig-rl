const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const board = @import("board");
const Tile = board.tile.Tile;

const core = @import("core");
const Entities = core.entities.Entities;

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
    try renderEntities(game, painter);
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
                try painter.drawcmds.append(DrawCmd.textCmd("#", pos, Color.white(), 1));
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

fn renderEntities(game: *Game, painter: *Painter) !void {
    // draw player
    const entity_pos = game.level.entities.pos.get(Entities.player_id);
    try painter.drawcmds.append(DrawCmd.textCmd("@", entity_pos, Color.white(), 1));

    // Render triggers.
    // for (painter.state.animation.ids.items) |id| {
    //     if (game.level.entities.typ.get(id) == .trigger and game.level.entities.status.get(id).active) {
    //         if (painter.state.animation.get(id).draw()) |drawcmd| {
    //             try painter.drawcmds.append(drawcmd);
    //         }
    //     }
    // }

    // Render items.
    // for (painter.state.animation.ids.items) |id| {
    //     if (game.level.entities.typ.get(id) == .item and game.level.entities.status.get(id).active) {
    //         const is_visible = game.level.entityInFov(Entities.player_id, id) != .outside;
    //         const index: usize = @intCast(game.level.map.toIndex(game.level.entities.pos.get(id)));
    //         const on_explored_tile = game.level.entities.explored.getPtr(Entities.player_id).isSet(index);
    //         if (is_visible or on_explored_tile) {
    //             if (painter.state.animation.get(id).draw()) |drawcmd| {
    //                 try painter.drawcmds.append(drawcmd);
    //             }
    //         }
    //     }
    // }

    // Render remaining entities.
    // for (painter.state.animation.ids.items) |id| {
    //     // const typ = game.level.entities.typ.get(id);
    //     // if (typ != .item and typ != .trigger and game.level.entities.status.get(id).active) {
    //     //     // Columns and environment entities are rendered even if not in fov.
    //     //     const is_environment = game.level.entities.typ.get(id) == .environment;
    //     //     const is_column = game.level.entities.typ.get(id) == .column;

    //     //     // Other entities are only rendered if currently within fov.
    //     //     const entity_in_player_fov = game.level.entityInFov(Entities.player_id, id);

    //     //     if (is_column or is_environment or entity_in_player_fov == .inside) {
    //     //         const animation = painter.state.animation.get(id);

    //     //         // NOTE the shadow doesn't look that good. This is tracked in issue 19.
    //     //         if (false) {
    //     //             var shadow = animation;
    //     //             shadow.sprite_anim.sprite.flip_horiz = !shadow.sprite_anim.sprite.flip_horiz;
    //     //             if (shadow.draw()) |drawcmd| {
    //     //                 var cmd = drawcmd;
    //     //                 cmd.setColor(Color.black());
    //     //                 try painter.drawcmds.append(cmd);
    //     //             }
    //     //         }

    //     //         if (animation.draw()) |drawcmd| {
    //     //             try painter.drawcmds.append(drawcmd);
    //     //         }
    //     //     }
    //     // }
    // }
}
