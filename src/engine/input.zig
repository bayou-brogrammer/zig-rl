const std = @import("std");
const Allocator = std.mem.Allocator;
const BoundedArray = std.BoundedArray;

const actions = @import("actions.zig");
const InputAction = actions.InputAction;

const math = @import("math");
const Direction = math.direction.Direction;
const Pos = math.pos.Pos;

const s = @import("settings.zig");
const GameState = s.GameState;
const Settings = s.Settings;

pub const KeyDir = enum {
    up,
    held,
    down,
};

pub const MouseButton = enum {
    left,
    right,
    middle,
};

pub const ButtonState = struct {
    pos: Pos,
    dir: KeyDir,
};

pub const InputEvent = union(enum) {
    char: struct { chr: u8, key_dir: KeyDir },
    ctrl: KeyDir,
    shift: KeyDir,
    alt: KeyDir,
    enter: KeyDir,
    mouse_pos: struct { x: i32, y: i32 },
    mouse_button: struct { button: MouseButton, pos: Pos, key_dir: KeyDir },
    esc,
    tab,
    quit,

    pub fn initChar(chr: u8, key_dir: KeyDir) InputEvent {
        return InputEvent{ .char = .{ .chr = chr, .key_dir = key_dir } };
    }
};

pub const HeldState = struct {
    down_time: u64,
    repetitions: usize,

    pub fn init(down_time: u64, repetitions: usize) HeldState {
        return HeldState{ .down_time = down_time, .repetitions = repetitions };
    }

    pub fn repeated(self: HeldState) HeldState {
        return HeldState.init(self.down_time, self.repetitions + 1);
    }
};

pub const MouseState = struct {
    x: i32 = 0,
    y: i32 = 0,
    left: ?ButtonState = null,
    middle: ?ButtonState = null,
    right: ?ButtonState = null,

    fn init() MouseState {
        return MouseState{};
    }
};

pub const InputDirection = union(enum) {
    dir: Direction,
    current: void,

    pub fn fromChar(chr: u8) ?InputDirection {
        if (directionFromDigit(chr)) |dir| {
            return InputDirection{ .dir = dir };
        } else if (chr == '5') {
            return InputDirection.current;
        } else {
            return null;
        }
    }
};

pub const Input = struct {
    // 10 items seems to be enough that we can't hold this many down, which would crash the game.
    const CharDownBuffer = BoundedArray(u8, 10);

    ctrl: bool,
    alt: bool,
    shift: bool,
    // target: ?Target,
    direction: ?InputDirection,
    char_down_order: CharDownBuffer,
    char_held: [256]?HeldState,
    mouse: MouseState,

    pub fn init() Input {
        return Input{
            .ctrl = false,
            .alt = false,
            .shift = false,
            // .target = null,
            .direction = null,
            .char_down_order = CharDownBuffer.init(0) catch unreachable,
            .char_held = [_]?HeldState{null} ** 256,
            .mouse = MouseState.init(),
        };
    }

    // This must be called at the start of every frame to clear mouse up state.
    pub fn tick(input: *Input) void {
        if (input.mouse.left != null and input.mouse.left.?.dir == .up) {
            input.mouse.left = null;
        }
        if (input.mouse.right != null and input.mouse.right.?.dir == .up) {
            input.mouse.right = null;
        }
        if (input.mouse.middle != null and input.mouse.middle.?.dir == .up) {
            input.mouse.middle = null;
        }
    }

    pub fn handleEvent(self: *Input, event: InputEvent, settings: *Settings, ticks: u64) InputAction {
        _ = settings; // autofix
        var action: InputAction = InputAction.none;

        // Remember characters that are pressed down.
        if (event == InputEvent.char) {
            if (event.char.key_dir == KeyDir.down) {
                const held_state = HeldState.init(ticks, 0);
                self.char_held[event.char.chr] = held_state;
            }
        }

        switch (event) {
            // NOTE this might be used by the Unity controller to clean up the game state on exit.
            InputEvent.quit => {},

            InputEvent.esc => {
                action = InputAction.esc;
            },

            InputEvent.tab => {
                action = InputAction.cursorReturn;
            },

            InputEvent.enter => |dir| {
                if (dir == KeyDir.up) {
                    action = InputAction.moveTowardsCursor;
                }
            },

            InputEvent.ctrl => |dir| {
                _ = dir; // autofix
                // if (dir != KeyDir.held) {
                //     self.ctrl = dir == KeyDir.down;
                // }

                // switch (dir) {
                //     KeyDir.down => action = InputAction.sneak,
                //     KeyDir.up => action = InputAction.walk,
                //     else => {},
                // }
            },

            InputEvent.alt => |dir| {
                _ = dir;
            },

            InputEvent.shift => |dir| {
                _ = dir;
            },

            InputEvent.mouse_button => |button| {
                switch (button.button) {
                    .left => {
                        if (button.key_dir == .down and self.mouse.left == null) {
                            self.mouse.left = ButtonState{ .pos = button.pos, .dir = .down };
                        } else if (button.key_dir == .held) {
                            self.mouse.left = ButtonState{ .pos = button.pos, .dir = .held };
                        } else if (button.key_dir == .up) {
                            self.mouse.left.?.dir = .up;
                        }
                    },
                    .right => {
                        if (button.key_dir == .down and self.mouse.right == null) {
                            self.mouse.right = ButtonState{ .pos = button.pos, .dir = .down };
                        } else if (button.key_dir == .held) {
                            self.mouse.left = ButtonState{ .pos = button.pos, .dir = .held };
                        } else if (button.key_dir == .up) {
                            self.mouse.right.?.dir = .up;
                        }
                    },
                    .middle => {
                        if (button.key_dir == .down and self.mouse.middle == null) {
                            self.mouse.middle = ButtonState{ .pos = button.pos, .dir = .down };
                        } else if (button.key_dir == .held and self.mouse.middle == null) {
                            self.mouse.middle = ButtonState{ .pos = button.pos, .dir = .held };
                        } else if (button.key_dir == .up) {
                            self.mouse.middle.?.dir = .up;
                        }
                    },
                }
                // Always update the mouse position.
                self.mouse.x = button.pos.x;
                self.mouse.y = button.pos.y;
            },

            InputEvent.mouse_pos => |pos| {
                self.mouse.x = pos.x;
                self.mouse.y = pos.y;
            },

            InputEvent.char => |chr| {
                _ = chr;
            },
        }

        return action;
    }
};

fn directionFromDigit(chr: u8) ?Direction {
    return switch (chr) {
        '4' => Direction.left,
        '6' => Direction.right,
        '8' => Direction.up,
        '2' => Direction.down,
        '1' => Direction.downLeft,
        '3' => Direction.downRight,
        '7' => Direction.upLeft,
        '9' => Direction.upRight,
        else => null,
    };
}
