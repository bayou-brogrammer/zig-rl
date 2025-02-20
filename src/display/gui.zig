const std = @import("std");
const print = std.debug.print;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const BoundedArrayAligned = std.BoundedArrayAligned;

const Allocator = std.mem.Allocator;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;

pub const sdl3 = @import("sdl3");

const engine = @import("engine");
const Game = engine.game.Game;
const InputEvent = engine.input.InputEvent;
const Msg = engine.messaging.Msg;

const utils = @import("utils");
const Timer = utils.timer.Timer;

const display = @import("display.zig");
const panels = @import("panels.zig");
const keyboard = @import("keyboard.zig");
const Screen = @import("screen.zig").Screen;

pub const PIXELS_PER_CELL: usize = 24;
pub const WINDOW_WIDTH: usize = PIXELS_PER_CELL * panels.SCREEN_CELLS_WIDTH;
pub const WINDOW_HEIGHT: usize = PIXELS_PER_CELL * panels.SCREEN_CELLS_HEIGHT;

pub const FRAME_ALLOCATOR_MAX_NUM_BYTES: usize = 32 * 1024 * 1024;

// pub const SaveBuffer = BoundedArrayAligned(u8, @alignOf(Save), SAVE_GAME_MAX_NUM_BYTES);
pub const InputBuffer = BoundedArrayAligned(InputEvent, @alignOf(InputEvent), 64);

pub const GuiMode = enum {
    empty,
    startScreen,
    playing,
    exiting,

    pub fn isMenu(mode: GuiMode) bool {
        return mode != .playing and mode != .exiting;
    }
};

pub const DisplayState = struct {
    next_screen_index: usize = 0,
    screens: ArrayListUnmanaged(Screen),

    pub fn init(allocator: Allocator) DisplayState {
        return .{
            .screens = ArrayListUnmanaged(Screen).initCapacity(allocator, 0) catch unreachable,
        };
    }

    pub fn deinit(state: *DisplayState, allocator: Allocator) void {
        state.screens.deinit(allocator);
    }
};

pub const Gui = struct {
    game: Game,
    display: display.Display,
    reload_config_timer: Timer,

    state: DisplayState,
    mode: GuiMode = .empty,

    ticks: u64,
    delta_ticks: u64,
    config_mtime_ms: i64,

    allocator: Allocator,
    frame_allocator: FixedBufferAllocator,

    pub fn init(seed: u64, allocator: Allocator) !Gui {
        const frame_allocation = try allocator.alloc(u8, FRAME_ALLOCATOR_MAX_NUM_BYTES);
        var fixed_buffer_allocator = FixedBufferAllocator.init(frame_allocation);

        const disp = try display.Display.init("rlgame", WINDOW_WIDTH, WINDOW_HEIGHT, allocator);

        var width: c_int = 0;
        var height: c_int = 0;
        if (!sdl3.SDL_GetWindowSize(disp.window, &width, &height)) {
            std.log.err("SDL_GetWindowSize: {s}", .{sdl3.SDL_GetError()});
            return error.SDL_GetWindowSize;
        }

        std.log.info("window size: {d}x{d}", .{ width, height });

        const game = try Game.init(seed, allocator, fixed_buffer_allocator.allocator());

        const gui = Gui{
            .ticks = 0,
            .delta_ticks = 0,
            .config_mtime_ms = try configMTimeMs(),

            .display = disp,
            .game = game,
            .reload_config_timer = Timer.init(game.config.reload_config_period),

            .mode = .empty,
            .state = DisplayState.init(allocator),

            .allocator = allocator,
            .frame_allocator = fixed_buffer_allocator,
        };

        // try gui.game.resolveMessages();

        return gui;
    }

    pub fn deinit(gui: *Gui) void {
        gui.display.deinit();
        gui.state.deinit(gui.allocator);
        gui.game.deinit();
        // gui.panels.deinit();
        // gui.profiler.deinit();
        gui.allocator.free(gui.frame_allocator.buffer);
        // gui.allocator.destroy(gui.save_buffer);
        // gui.recording.deinit();
        // gui.imm.deinit();
    }

    pub fn drawUi(gui: *Gui, input_buffer: *InputBuffer) !void {
        _ = input_buffer; // autofix
        _ = gui; // autofix

        // try gui.collectImmInputsPlayer(input_buffer);
        // try gui.collectImmInputsInventory(input_buffer);
        // try gui.collectImmInputsInfo();
        // try gui.drawPips();
    }

    pub fn resolveMessages(gui: *Gui) !void {
        _ = gui; // autofix
        // while (try gui.game.resolveMessage()) |msg| {
        //     try gui.resolveMessage(msg);
        // }
    }

    pub fn resolveMessage(gui: *Gui, msg: Msg) !void {
        _ = msg; // autofix
        _ = gui; // autofix
    }

    /////////////////////
    /// Step
    /////////////////////

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
    }

    /////////////////////
    /// Input processing
    /////////////////////

    // Process input events to update the input state without updating the game state.
    pub fn updateInputState(gui: *Gui, inputs: InputBuffer) bool {
        var any_key_pressed = false;
        for (inputs.slice()) |input_event| {
            if (input_event == .quit) {
                gui.mode = .exiting;
            } else {
                // _ = gui.game.handleInputEvent(input_event, gui.ticks);
            }

            any_key_pressed = any_key_pressed or input_event == .char or input_event == .enter or input_event == .esc or input_event == .tab or input_event == .mouse_button;
        }
        return any_key_pressed;
    }

    pub fn processInputs(gui: *Gui, inputs: InputBuffer) !bool {
        if (gui.reload_config_timer.step(gui.delta_ticks) > 0) {
            const current_config_mtime_ms = try configMTimeMs();
            if (current_config_mtime_ms != gui.config_mtime_ms) {
                // prof.Prof.scope("reload config");
                try gui.game.reloadConfig();
                // prof.Prof.end();
                gui.config_mtime_ms = current_config_mtime_ms;
            }
        }

        switch (gui.mode) {
            .empty => {
                gui.state.next_screen_index = 0;
                try gui.enterScreen();
                // gui.state.next_screen_index = (gui.state.next_screen_index + 1) % gui.state.screens.items.len;
            },
            .startScreen => {
                try gui.stepStartScreen(inputs);
            },
            else => {},
        }

        return gui.mode != .exiting;
    }

    fn collectInputs(gui: *Gui, input_buffer: *InputBuffer) !void {
        // const prev_mouse_state = gui.game.input.mouse;

        _ = gui; // autofix
        var event: sdl3.SDL_Event = undefined;
        while (sdl3.SDL_PollEvent(&event)) {
            if (keyboard.translateEvent(event)) |input_event| {
                try input_buffer.append(input_event);
            }
        }

        // SDL3 does not produce mouse 'held' events, so check mouse state
        // and previous Input mouse state to determine if the button is still
        // held this frame.
        const mouse_state: u32 = sdl3.SDL_GetMouseState(null, null);

        const left_clicked: bool = (mouse_state & sdl3.SDL_BUTTON_LEFT) != 0;
        _ = left_clicked; // autofix
        // if (prev_mouse_state.left != null and left_clicked) {
        //     const left_held = InputEvent{ .mouse_button = .{
        //         .button = .left,
        //         .pos = gui.game.input.mouse.left.?.pos,
        //         .key_dir = .held,
        //     } };
        //     try input_buffer.append(left_held);
        // }
    }

    /////////////////////
    /// Screen management
    /////////////////////

    pub fn enterScreen(gui: *Gui) !void {
        gui.enterStartScreen();
        // switch (gui.state.screens.items[gui.state.next_screen_index]) {
        //     .start => {
        //         gui.enterStartScreen();
        //     },
        // }
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
};

fn configMTimeMs() !i64 {
    const config_file = try std.fs.cwd().openFile(engine.game.CONFIG_PATH, .{});
    defer config_file.close();

    const config_stat = try config_file.stat();
    const config_mtime_ms: i64 = @intCast(@divTrunc(config_stat.mtime, 1_000_000));

    return config_mtime_ms;
}
