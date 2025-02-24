const std = @import("std");
const print = std.debug.print;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const core = @import("core");
const Config = core.config.Config;
const Level = core.level.Level;

pub const actions = @import("actions.zig");
pub const input = @import("input.zig");
const Input = input.Input;
const InputAction = actions.InputAction;
const InputEvent = input.InputEvent;

pub const messaging = @import("messaging.zig");
pub const MsgLog = messaging.MsgLog;
// pub const SaveMsgLog = messaging.SaveMsgLog;
pub const Msg = messaging.Msg;

pub const s = @import("settings.zig");
pub const GameState = s.GameState;
pub const Settings = s.Settings;

pub const resolve = @import("resolve.zig");

pub const CONFIG_PATH: []const u8 = "data/config.txt";

pub const Game = struct {
    config: Config,
    input: Input,
    settings: Settings,
    log: MsgLog,
    level: Level,

    allocator: Allocator,
    frame_allocator: Allocator,

    pub fn init(seed: u64, allocator: Allocator, frame_allocator: Allocator) !Game {
        _ = seed; // autofix
        // const rng = RndGen.init(seed);
        const config = try Config.fromFile(CONFIG_PATH[0..]);
        const level = Level.empty();
        const log = try MsgLog.init(allocator);

        return Game{
            .config = config,
            .level = level,
            // .rng = rng,
            .log = log,
            .input = Input.init(),
            .settings = Settings.init(),

            .allocator = allocator,
            .frame_allocator = frame_allocator,
        };
    }

    pub fn deinit(game: *Game) void {
        game.level.deinit(game.allocator);
        game.log.deinit();
    }

    pub fn reloadConfig(game: *Game) !void {
        game.config = try Config.fromFile(CONFIG_PATH[0..]);
    }

    pub fn resolveMessages(game: *Game) !void {
        while (try game.resolveMessage() != null) {}
    }

    pub fn resolveMessage(game: *Game) !?Msg {
        if (try game.log.pop()) |msg| {
            try resolve.resolveMsg(game, msg);
            return msg;
        }

        return null;
    }

    pub fn handleInputEvent(game: *Game, input_event: InputEvent, delta_ticks: u64) InputAction {
        return game.input.handleEvent(input_event, &game.settings, delta_ticks);
    }
};
