const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const assert = std.debug.assert;
const BoundedArrayAligned = std.BoundedArrayAligned;
const BoundedArray = std.BoundedArray;
const RndGen = std.rand.DefaultPrng;
const DynamicBitSetUnmanaged = std.DynamicBitSetUnmanaged;

const Allocator = std.mem.Allocator;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;

const utils = @import("utils");
const Timer = utils.timer.Timer;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;
const Dims = math.dims.Dims;
const Color = math.utils.Color;
const Rect = math.rect.Rect;

const core = @import("core");
const Config = core.config.Config;

const engine = @import("engine");
const InputAction = engine.actions.InputAction;
const Game = engine.game.Game;
const Input = engine.input.Input;
const InputEvent = engine.input.InputEvent;
const Settings = engine.settings.Settings;
const GameState = engine.settings.GameState;
const Msg = engine.messaging.Msg;

const drawing = @import("drawing");
const Panel = drawing.panel.Panel;
const DrawCmd = drawing.drawcmd.DrawCmd;

const prof = @import("prof");

pub const display = @import("display.zig");
pub const Display = display.Display;
pub const keyboard = @import("keyboard.zig");
pub const sdl2 = @import("sdl2.zig");
pub const panels_import = @import("panels.zig");
pub const imm = @import("imm.zig");
pub const Imm = imm.Imm;

pub const Panels = panels_import.Panels;
const Texture = sdl2.SDL_Texture;

pub const PIXELS_PER_CELL: usize = 24;
pub const WINDOW_WIDTH: usize = PIXELS_PER_CELL * panels_import.SCREEN_CELLS_WIDTH;
pub const WINDOW_HEIGHT: usize = PIXELS_PER_CELL * panels_import.SCREEN_CELLS_HEIGHT;

pub const FRAME_ALLOCATOR_MAX_NUM_BYTES: usize = 32 * 1024 * 1024;
pub const SAVE_GAME_MAX_NUM_BYTES: usize = 32 * 1024 * 1024;

pub const CONFIG_PATH: []const u8 = "data/config.txt";

pub const InputBuffer = BoundedArrayAligned(InputEvent, @alignOf(InputEvent), 64);
pub const MsgStr = BoundedArrayAligned(u8, @alignOf(u8), 32);

pub const GuiMode = enum {
    empty,

    startScreen,
    helpMenu0,
    helpMenu1,

    playing,
    exiting,

    pub fn isMenu(mode: GuiMode) bool {
        return mode != .playing and mode != .exiting;
    }

    pub fn isHelpMenu(mode: GuiMode) bool {
        return mode == .helpMenu0 or mode == .helpMenu1;
    }
};

pub const DisplayState = struct {
    map_window_center: Pos,
    turn_count: usize,
    impressions: DynamicBitSetUnmanaged,
    screens: ArrayListUnmanaged(Screen),
    next_screen_index: usize = 0,

    pub fn init(allocator: Allocator) DisplayState {
        var state: DisplayState = undefined;

        state.turn_count = 0;
        state.map_window_center = Pos.init(0, 0);
        state.screens = ArrayListUnmanaged(Screen).initCapacity(allocator, 0) catch unreachable;

        return state;
    }

    pub fn deinit(state: *DisplayState, allocator: Allocator) void {
        state.screens.deinit(allocator);
    }

    pub fn clear(state: *DisplayState) void {
        state.map_window_center = Pos.init(0, 0);
        state.turn_count = 0;
    }
};

pub const Gui = struct {
    display: display.Display,
    game: Game,
    state: DisplayState,
    profiler: prof.Prof,
    delta_ticks: u64,
    ticks: u64,
    reload_config_timer: Timer,
    panels: Panels,
    imm: Imm,
    mode: GuiMode = .empty,
    found_save_file: bool,
    config_mtime_ms: i64,
    allocator: Allocator,
    frame_allocator: FixedBufferAllocator,

    pub fn init(seed: u64, allocator: Allocator) !Gui {
        const frame_allocation = try allocator.alloc(u8, FRAME_ALLOCATOR_MAX_NUM_BYTES);
        var fixed_buffer_allocator = FixedBufferAllocator.init(frame_allocation);

        const game = try Game.init(seed, allocator, fixed_buffer_allocator.allocator());
        var profiler: prof.Prof = prof.Prof{};
        if (game.config.use_profiling) {
            try profiler.start();
            prof.Prof.log("Starting up");
        }

        var disp = try display.Display.init("rustrl", WINDOW_WIDTH, WINDOW_HEIGHT, allocator);

        var width: c_int = 0;
        var height: c_int = 0;
        if (!sdl2.SDL_GetWindowSize(disp.window, &width, &height)) {
            std.log.warn("Failed to get window size", .{});
        }

        const panels = try Panels.init(@as(i32, @intCast(width)), @as(i32, @intCast(height)), &disp, allocator);

        const state = DisplayState.init(allocator);

        var gui = Gui{
            .allocator = allocator,
            .config_mtime_ms = try configMTimeMs(),
            .delta_ticks = 0,
            .display = disp,
            .found_save_file = false,
            .frame_allocator = fixed_buffer_allocator,
            .game = game,
            .imm = Imm.init(allocator, disp.charDims(&panels.screen.panel, 1.0)),
            .mode = .empty,
            .panels = panels,
            .profiler = profiler,
            .reload_config_timer = Timer.init(game.config.reload_config_period),
            .state = state,
            .ticks = 0,
        };
        try gui.game.resolveMessages();

        return gui;
    }

    pub fn deinit(gui: *Gui) void {
        gui.display.deinit();
        gui.state.deinit(gui.allocator);
        gui.game.deinit();
        gui.panels.deinit();
        gui.profiler.deinit();
        gui.allocator.free(gui.frame_allocator.buffer);
        gui.imm.deinit();
    }

    pub fn resolveMessages(gui: *Gui) !void {
        while (try gui.game.resolveMessage()) |msg| {
            try gui.resolveMessage(msg);
        }
    }

    pub fn resolveMessage(gui: *Gui, msg: Msg) !void {
        _ = msg; // autofix
        _ = gui; // autofix
        // switch (msg) {
        //     else => {},
        // }

        // try gui.state.console_log.queue(&gui.game.level.entities, msg, gui.state.turn_count);
    }

    ///////////////////////////////
    // Stepping
    ///////////////////////////////
    pub fn step(gui: *Gui, ticks: u64) !bool {
        gui.frame_allocator.reset();

        gui.delta_ticks = ticks - gui.ticks;
        gui.ticks = ticks;

        var input_buffer: InputBuffer = try InputBuffer.init(0);
        try gui.collectInputs(&input_buffer);

        // if (gui.mode.levelVisible()) {
        //     try gui.drawUi(&input_buffer);
        // }

        return try gui.processInputs(input_buffer);
    }

    pub fn stepStartScreen(gui: *Gui, inputs: InputBuffer) !void {
        _ = gui.updateInputState(inputs);

        var config = imm.Imm.Config.init(&gui.panels.screen.drawcmds, Color.white());
        config.outline = true;

        // Immediate mode GUI.
        gui.imm.pos = Pos.init(10, 10);

        const new_game_click = try gui.imm.button(gui.panels.screen.panel, gui.game.input.mouse, "new_game", " new game ", config);
        const new_game = new_game_click == .up;

        gui.imm.skip();
        const quit_click = try gui.imm.button(gui.panels.screen.panel, gui.game.input.mouse, "quit_game", " quit ", config);
        const quit = quit_click == .up;

        if (new_game) {
            try gui.nextScreen();
        }
        if (quit) {
            gui.mode = .exiting;
        }
    }

    ///////////////////////////////
    // Screen navigation
    ///////////////////////////////

    pub fn nextScreen(gui: *Gui) !void {
        try gui.enterScreen();

        // Clear display state for new level to start.
        gui.state.clear();
        gui.state.next_screen_index = (gui.state.next_screen_index + 1) % gui.state.screens.items.len;
    }

    pub fn enterScreen(gui: *Gui) !void {
        // switch (gui.state.screens.items[gui.state.next_screen_index]) {
        //     .start => {
        //         gui.enterStartScreen();
        //     },
        // }

        gui.enterStartScreen();

        // When changing screens, clear UI state.
        gui.imm.clear();
    }

    fn enterStartScreen(gui: *Gui) void {
        // var dir = std.fs.cwd();
        // gui.found_save_file = true;
        // dir.access(SAVE_GAME_FILE_NAME, .{}) catch blk: {
        //     gui.found_save_file = false;
        //     break :blk;
        // };
        gui.mode = .startScreen;
    }

    fn collectImmInfo(gui: *Gui) !void {
        const text_color = Color.init(0xcd, 0xb4, 0x96, 255);
        var config = imm.Imm.Config.init(&gui.panels.screen.drawcmds, text_color);
        config.justify = .left;

        const start_pos = gui.panels.info_area.position();
        gui.imm.pos = Pos.init(start_pos.x + 1, start_pos.y + 1);

        const cursor_pos = gui.game.settings.mode.cursor.pos;

        var y_pos: i32 = 1;

        const coords_str = try std.fmt.allocPrint(gui.frame_allocator.allocator(), "({:>2},{:>2})", .{ @as(usize, @intCast(cursor_pos.x)), @as(usize, @intCast(cursor_pos.y)) });
        try gui.imm.text(coords_str, config);

        y_pos += 1;
    }

    ///////////////////////////////
    // Input processing
    ///////////////////////////////

    // Process input events to update the input state without updating the game state.
    pub fn updateInputState(gui: *Gui, inputs: InputBuffer) bool {
        var any_key_pressed = false;
        for (inputs.slice()) |input_event| {
            if (input_event == .quit) {
                gui.mode = .exiting;
            } else {
                _ = gui.game.handleInputEvent(input_event, gui.ticks);
            }

            any_key_pressed = any_key_pressed or input_event == .char or input_event == .enter or input_event == .esc or input_event == .tab or input_event == .mouse_button;
        }
        return any_key_pressed;
    }

    pub fn processInputs(gui: *Gui, inputs: InputBuffer) !bool {
        prof.Prof.scope("step");
        defer prof.Prof.end();

        if (gui.reload_config_timer.step(gui.delta_ticks) > 0) {
            const current_config_mtime_ms = try configMTimeMs();
            if (current_config_mtime_ms != gui.config_mtime_ms) {
                prof.Prof.scope("reload config");
                try gui.game.reloadConfig();
                prof.Prof.end();
                gui.config_mtime_ms = current_config_mtime_ms;
            }
        }

        gui.imm.deltaTime(gui.delta_ticks);

        gui.game.input.tick();
        if (gui.mode == .empty) {
            // if (gui.state.screens.items.len == 0) {
            //     try gui.state.screens.append(gui.allocator, Screen.fromMapConfig(MapConfig.empty()));
            // }

            gui.state.next_screen_index = 0;
            try gui.enterScreen();
            // gui.state.next_screen_index = (gui.state.next_screen_index + 1) % gui.state.screens.items.len;
        } else if (gui.mode == .startScreen) {
            try gui.stepStartScreen(inputs);
        }
        prof.Prof.end();

        if (gui.mode != .exiting) {
            // Draw whether or not there is an event to update animations, effects, etc.
            prof.Prof.scope("draw");
            try gui.draw();
            defer prof.Prof.end();
        }

        const exiting = gui.mode != .exiting;
        return exiting;
    }

    fn collectInputs(gui: *Gui, input_buffer: *InputBuffer) !void {
        const prev_mouse_state = gui.game.input.mouse;

        var event: sdl2.SDL_Event = undefined;
        while (sdl2.SDL_PollEvent(&event)) {
            if (keyboard.translateEvent(event)) |input_event| {
                try input_buffer.append(input_event);
            }
        }

        // SDL2 does not produce mouse 'held' events, so check mouse state
        // and previous Input mouse state to determine if the button is still
        // held this frame.
        const mouse_state: u32 = sdl2.SDL_GetMouseState(null, null);

        const left_clicked: bool = (mouse_state & sdl2.SDL_BUTTON_LEFT) != 0;
        if (prev_mouse_state.left != null and left_clicked) {
            const left_held = InputEvent{ .mouse_button = .{
                .button = .left,
                .pos = gui.game.input.mouse.left.?.pos,
                .key_dir = .held,
            } };
            try input_buffer.append(left_held);
        }

        const middle_clicked: bool = (mouse_state & sdl2.SDL_BUTTON_MIDDLE) != 0;
        if (prev_mouse_state.middle != null and middle_clicked) {
            const middle_held = InputEvent{ .mouse_button = .{
                .button = .middle,
                .pos = gui.game.input.mouse.middle.?.pos,
                .key_dir = .held,
            } };
            try input_buffer.append(middle_held);
        }

        const right_clicked: bool = (mouse_state & sdl2.SDL_BUTTON_RIGHT) != 0;
        if (prev_mouse_state.right != null and right_clicked) {
            const right_held = InputEvent{ .mouse_button = .{
                .button = .right,
                .pos = gui.game.input.mouse.right.?.pos,
                .key_dir = .held,
            } };
            try input_buffer.append(right_held);
        }
    }

    fn collectImmInputsPlayer(gui: *Gui, input_buffer: *InputBuffer) !void {
        _ = input_buffer;

        const ui_color = Color.init(0xcd, 0xb4, 0x96, 255);

        var config = imm.Imm.Config.init(&gui.panels.screen.drawcmds, ui_color);
        config.justify = .left;

        // const y_offset = gui.panels.level_area.bottomLeftCorner();
        // gui.imm.pos = Pos.init(1, y_offset.y + 2);

        // gui.imm.skip();

        const mouse_state = gui.game.input.mouse;
        const turn_str = try std.fmt.allocPrint(gui.frame_allocator.allocator(), "turn {}", .{gui.state.turn_count});
        const turn_click = try gui.imm.button(gui.panels.screen.panel, mouse_state, "turn", turn_str, config);
        if (turn_click == .held or turn_click == .down) {
            const width = 25;
            const height = 8;
            const turn_rect = gui.panels.screen.panel.getRect().centered(width, height);
            try gui.imm.placard(" Turn "[0..], turn_rect, config);
            config.position = turn_rect.position();
            config.position.?.x += 1;
            config.position.?.y += 1;
            try gui.imm.text("the current turn", config);
            config.position = null;
        }
    }

    ///////////////////////////////
    // Drawing
    ///////////////////////////////

    pub fn draw(gui: *Gui) !void {
        gui.display.clear(&gui.panels.screen, Color.init(27, 27, 25, 255));

        // if (gui.mode == .startScreen) {
        //     // try gui.drawStartScreen();
        //     try gui.drawHelpMenu();
        // } else {
        //     gui.display.draw(&gui.panels.screen);
        // }

        try gui.drawStartScreen();

        gui.display.present(&gui.panels.screen);
    }

    pub fn drawUi(gui: *Gui, input_buffer: *InputBuffer) !void {
        try gui.collectImmInputsPlayer(input_buffer);
        // try gui.collectImmInputsInfo();
        // try gui.drawPips();
    }

    pub fn drawStartScreen(gui: *Gui) !void {
        // Draw the background image.
        // const background_sheet = gui.display.sprites.fromKey(key);
        // const background_sprite = background_sheet.sprite();

        // const sprite_area = background_sheet.spriteSrc(0);

        // const dst_area = gui.panels.screen.panel.getPixelRect().fitWithin(sprite_area);
        // const cell_dims = gui.panels.screen.panel.cellDims();
        // _ = cell_dims; // autofix

        // The dst_area is in pixels, but the sprite float is given in cells, so divide out number of pixels per cell.
        // const x_cells: f32 = @as(f32, @floatFromInt(dst_area.width)) / @as(f32, @floatFromInt(cell_dims.width));
        // const y_cells: f32 = @as(f32, @floatFromInt(dst_area.height)) / @as(f32, @floatFromInt(cell_dims.height));
        // const offset = gui.panels.screen.panel.f32CellFromPixel(dst_area.position());

        // try gui.panels.screen.drawcmds.insert(
        //     0,
        //     DrawCmd.spriteFloatCmd(
        //         background_sprite,
        //         Color.white(),
        //         offset.x,
        //         offset.y,
        //         x_cells,
        //         y_cells,
        //     ),
        // );

        gui.display.draw(&gui.panels.screen);
    }

    fn drawPlacard(gui: *Gui, text: []const u8, rect: Rect) !void {
        // Draw header text
        const text_color = Color.init(0, 0, 0, 255);
        const highlight_color = Color.init(0xcd, 0xb4, 0x96, 255);

        const pos = rect.position();
        try gui.panels.screen.drawcmds.append(DrawCmd.rectCmd(pos, rect.width, rect.height, 0.0, true, Color.black()));
        try gui.panels.screen.drawcmds.append(DrawCmd.rectCmd(pos, rect.width, rect.height, 0.5, false, highlight_color));
        try gui.panels.screen.drawcmds.append(DrawCmd.textJustifyCmd(text, .center, pos, text_color, highlight_color, rect.width, 1.0));
    }

    const HELP_MENU_X: i32 = 35;
    const HELP_MENU_Y: i32 = 30;

    fn drawHelpMenu(gui: *Gui) !void {
        const menu_rect = gui.panels.screen.panel.getRect().centered(HELP_MENU_X, HELP_MENU_Y);

        // Render header
        try gui.drawPlacard("Help", menu_rect);

        const help = @embedFile("help_1.txt");
        try gui.drawHelpText(help);
    }

    fn drawHelpMenu2(gui: *Gui) !void {
        const menu_rect = gui.panels.screen.panel.getRect().centered(HELP_MENU_X, HELP_MENU_Y);

        // Render header
        try gui.drawPlacard("Help", menu_rect);

        const help = @embedFile("help_2.txt");
        try gui.drawHelpText(help);
    }

    fn drawHelpText(gui: *Gui, help: []const u8) !void {
        const ui_color = Color.init(0xcd, 0xb4, 0x96, 255);

        const drawcmds = &gui.panels.screen.drawcmds;

        const menu_rect = gui.panels.screen.panel.getRect().centered(HELP_MENU_X, HELP_MENU_Y);

        var y_pos: f32 = 0.5;
        y_pos += @floatFromInt(menu_rect.y_offset);
        const x_pos: f32 = @floatFromInt(menu_rect.x_offset);

        var start: usize = 0;
        var index: usize = 0;
        while (index < help.len) : (index += 1) {
            if (help[index] == '\n') {
                if (index - start > 1) {
                    const drawcmd = DrawCmd.textFloatCmd(help[start..index], x_pos + 1.0, y_pos, .left, ui_color, gui.game.config.ui_help_text_scale);
                    try drawcmds.append(drawcmd);
                }
                y_pos += gui.game.config.ui_help_text_scale;
                start = index + 1;
            }
        }
    }
};

fn configMTimeMs() !i64 {
    const config_file = try std.fs.cwd().openFile(engine.game.CONFIG_PATH, .{});
    defer config_file.close();
    const config_stat = try config_file.stat();
    const config_mtime_ms: i64 = @intCast(@divTrunc(config_stat.mtime, 1_000_000));
    return config_mtime_ms;
}

pub const Screen = union(enum) {
    start,
    // classSelect,
    // skillSelect,
    // level: LevelConfig,
    // win,

    // pub fn fromMapConfig(map_config: MapConfig) Screen {
    //     return Screen{ .level = LevelConfig.init(map_config) };
    // }
};

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
