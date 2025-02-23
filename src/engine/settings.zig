const std = @import("std");
const BoundedArray = std.BoundedArray;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;
const core = @import("core");
const save = core.save;

const input = @import("input.zig");

const actions = @import("actions.zig");

pub const GameState = enum {
    playing,
    win,
    lose,
    use,
    finishedLevel,
    startNewLevel,
};

pub const Mode = union(enum) {
    playing,
};

pub const Settings = struct {
    state: GameState = .playing,
    mode: Mode = Mode.playing,
    levels_completed: usize = 0,

    debug_enabled: bool = false,
    overlay_enabled: bool = false,
    map_changed: bool = false,

    pub fn init() Settings {
        return Settings{};
    }
};
