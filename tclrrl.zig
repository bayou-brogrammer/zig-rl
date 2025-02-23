const builtin = @import("builtin");
const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const zt = @import("zigtcl");

const utils = @import("utils");
const core = @import("core");
const Config = core.config.Config;

const engine = @import("engine");
const Game = engine.game.Game;

const board = @import("board");
const math = @import("math");
const Pos = math.pos.Pos;

const drawing = @import("drawing");
const gui = @import("gui");
const display = gui.display;

pub const has_profiling = @import("build_options").remotery;

export fn Rrl_Init(interp: zt.Interp) c_int {
    if (builtin.os.tag != .windows) {
        _ = zt.tcl.Tcl_InitStubs(interp, "8.6", 0);
    } else {
        _ = zt.tcl.Tcl_PkgRequire(interp, "Tcl", "8.6", 0);
    }
    const namespace = "rrl";

    const ns = zt.tcl.Tcl_CreateNamespace(interp, "rrl", null, null);

    // Math
    _ = zt.RegisterStruct(math.dims.Dims, "Dims", namespace, interp);

    // Core
    _ = zt.RegisterStruct(core.config.Config, "Config", namespace, interp);
    // _ = zt.RegisterStruct(core.level.Level, "Level", namespace, interp);

    // Map
    _ = zt.RegisterStruct(math.pos.Pos, "Pos", namespace, interp);
    // _ = zt.RegisterStruct(board.map.Map, "Map", namespace, interp);
    // _ = zt.RegisterStruct(board.tile.Tile, "Tile", namespace, interp);
    // _ = zt.RegisterStruct(board.tile.Tile.Wall, "Wall", namespace, interp);
    // _ = zt.RegisterEnum(board.tile.Tile.Height, "Height", namespace, interp);
    // _ = zt.RegisterEnum(board.tile.Tile.Material, "Material", namespace, interp);

    // Entities
    // _ = zt.RegisterStruct(core.entities.Entities, "Entities", namespace, interp);
    // _ = zt.RegisterStruct(utils.comp.Comp(math.pos.Pos), "Comp(Pos)", namespace, interp);

    // Engine
    // _ = zt.RegisterStruct(engine.spawn, "spawn", namespace, interp);
    _ = zt.RegisterUnion(engine.input.InputEvent, "InputEvent", namespace, interp);
    _ = zt.RegisterEnum(engine.input.KeyDir, "KeyDir", namespace, interp);
    _ = zt.RegisterUnion(engine.messaging.Msg, "Msg", namespace, interp);
    _ = zt.RegisterStruct(engine.messaging.MsgLog, "MsgLog", namespace, interp);

    // Display
    _ = zt.RegisterStruct(display.Display, "Display", namespace, interp);
    // _ = zt.RegisterStruct(drawing.sprite.Sprite, "Sprite", namespace, interp);
    _ = zt.RegisterStruct(math.utils.Color, "Color", namespace, interp);
    _ = zt.RegisterUnion(drawing.drawcmd.DrawCmd, "DrawCmd", namespace, interp);
    _ = zt.RegisterStruct(drawing.panel.Panel, "Panel", namespace, interp);
    _ = zt.RegisterStruct(display.TexturePanel, "TexturePanel", namespace, interp);

    // Game
    _ = zt.RegisterStruct(Game, "Game", namespace, interp);

    // Gui
    _ = zt.RegisterStruct(gui.Gui, "Gui", namespace, interp);

    // Misc
    _ = zt.RegisterStruct(std.mem.Allocator, "Allocator", "zigtcl", interp);
    _ = zt.tcl.Tcl_CreateObjCommand(interp, "zigtcl::tcl_allocator", zt.StructCommand(std.mem.Allocator).StructInstanceCommand, @ptrCast(&zt.alloc.tcl_allocator), null);

    const allocatorObj = zt.tcl.Tcl_NewByteArrayObj(@ptrCast(&zt.alloc.tcl_allocator), @sizeOf(@TypeOf(zt.alloc.tcl_allocator)));
    _ = zt.tcl.Tcl_SetVar2Ex(interp, "zigtcl::tclAllocator", null, allocatorObj, 0);

    const pageAllocatorObj = zt.tcl.Tcl_NewByteArrayObj(@ptrCast(&std.heap.page_allocator), @sizeOf(@TypeOf(std.heap.page_allocator)));
    _ = zt.tcl.Tcl_SetVar2Ex(interp, "zigtcl::pageAllocator", null, pageAllocatorObj, 0);

    _ = zt.tcl.Tcl_Export(interp, ns, "*", 0);

    zt.interp = interp;
    _ = zt.tcl.Tcl_EvalFile(zt.interp, "test.tcl");

    return zt.tcl.Tcl_PkgProvide(interp, "rrl", "0.1.0");
}
