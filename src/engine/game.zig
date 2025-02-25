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

const board = @import("board");
const Map = board.map.Map;
const MapBits = board.map.MapBits;

pub const messaging = @import("messaging.zig");
pub const MsgLog = messaging.MsgLog;
// pub const SaveMsgLog = messaging.SaveMsgLog;
pub const Msg = messaging.Msg;

pub const s = @import("settings.zig");
pub const GameState = s.GameState;
pub const Settings = s.Settings;

const procgen = @import("procgen.zig");
pub const resolve = @import("resolve.zig");
const utils = @import("utils");

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

    pub fn changeState(game: *Game, new_state: GameState) void {
        game.settings.state = new_state;
        if (new_state == .playing) {
            game.settings.mode = .playing;
        }
    }

    pub fn generateNewLevel(game: *Game, keep_player: bool, map_config: procgen.MapConfig) !void {
        try procgen.generateMap(game, keep_player, map_config);
    }

    pub fn startEmptyLevel(game: *Game, width: i32, height: i32, ids: ?utils.comp.Ids) !void {
        _ = ids; // autofix
        game.level.map.deinit(game.allocator);

        print("Generating map... {d}x{d}\n", .{ width, height });
        game.level.map = try Map.fromDims(width, height, game.allocator);

        game.log.deinit();
        game.log = try MsgLog.init(game.allocator);
        try game.log.log(.newLevel, .{});

        // if (ids) |ids_to_keep| {
        //     game.level.entities.clearExcept(game.allocator, ids_to_keep);
        // } else {
        //     game.level.entities.clear();
        //     try spawn.spawnPlayer(&game.level.entities, &game.log, &game.config, game.allocator);
        // }
    }

    pub fn step(game: *Game, input_action: InputAction) !void {
        try game.startTurn(input_action);

        // Handle player input.
        try game.handleInputAction(input_action);

        // If the game continues, resolve messages logged by the action.
        try game.resolveMessages();
    }

    pub fn handleInputEvent(game: *Game, input_event: InputEvent, delta_ticks: u64) InputAction {
        return game.input.handleEvent(input_event, &game.settings, delta_ticks);
    }

    pub fn handleInputAction(game: *Game, input_action: InputAction) !void {
        // if (input_action != .none) {
        //     try game.removeMarkedEntities();
        // }

        try actions.resolveAction(game, input_action);
    }

    pub fn startTurn(game: *Game, input_action: InputAction) !void {
        if (game.settings.state == .finishedLevel or game.settings.state == .startNewLevel) {
            game.changeState(.playing);
        }

        // All entities previously spawned are now playing.
        // for (game.level.entities.state.ids.items) |id| {
        //     if (game.level.entities.state.get(id) == .spawn) {
        //         game.level.entities.state.getPtr(id).* = .play;
        //     }
        // }

        if (input_action.canTakeTurn()) {
            // for (game.level.entities.sound.ids.items) |id| {
            //     game.level.entities.sound.getPtr(id).* = MapBits.initEmpty();
            // }
        }

        game.log.clear();
    }
};
