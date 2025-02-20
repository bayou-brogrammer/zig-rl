const std = @import("std");
const print = std.debug.print;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const core = @import("core");
const Config = core.config.Config;

pub const CONFIG_PATH: []const u8 = "data/config.txt";

pub const Game = struct {
    config: Config,

    allocator: Allocator,
    frame_allocator: Allocator,

    pub fn init(seed: u64, allocator: Allocator, frame_allocator: Allocator) !Game {
        _ = seed; // autofix
        // const rng = RndGen.init(seed);
        const config = try Config.fromFile(CONFIG_PATH[0..]);
        // const level = Level.empty(allocator);
        // const log = try MsgLog.init(allocator);

        return Game{
            .config = config,
            // .level = level,
            // .rng = rng,
            // .input = Input.init(),
            // .settings = Settings.init(),
            // .log = log,
            .allocator = allocator,
            .frame_allocator = frame_allocator,
        };
    }

    pub fn deinit(game: *Game) void {
        _ = game; // autofix
        // game.level.deinit(game.allocator);
        // game.log.deinit();
    }

    pub fn reloadConfig(game: *Game) !void {
        game.config = try Config.fromFile(CONFIG_PATH[0..]);
    }
};
