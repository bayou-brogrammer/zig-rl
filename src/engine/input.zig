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

const DEBUG_TOGGLE_KEY: u8 = '\\';
const OVERLAY_TOGGLE_KEY: u8 = 'o';

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

    pub fn isHeld(self: Input, chr: u8) bool {
        if (self.char_held[chr]) |held_state| {
            return held_state.repetitions > 0;
        }

        return false;
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
                if (dir != KeyDir.held) {
                    self.ctrl = dir == KeyDir.down;
                }

                switch (dir) {
                    // KeyDir.down => action = InputAction.sneak,
                    KeyDir.up => action = InputAction.walk,
                    else => {},
                }
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
                action = self.handleChar(chr.chr, chr.key_dir, ticks, settings);
            },
        }

        return action;
    }

    fn handleChar(self: *Input, chr: u8, dir: KeyDir, ticks: u64, settings: *const Settings) InputAction {
        _ = ticks; // autofix
        return switch (dir) {
            KeyDir.up => self.handleCharUp(chr, settings),
            KeyDir.down => self.handleCharDown(chr, settings),
            // KeyDir.held => self.handleCharHeld(chr, ticks, settings),
            else => InputAction.none,
        };
    }

    fn handleCharUp(self: *Input, chr: u8, settings: *const Settings) InputAction {
        if (std.mem.indexOfScalar(u8, self.char_down_order.constSlice(), chr)) |index| {
            _ = self.char_down_order.orderedRemove(index);
        }

        const is_held = self.isHeld(chr);
        self.char_held[chr] = null;

        if (settings.state == GameState.use) {
            // if (InputDirection.fromChar(chr)) |input_dir| {
            //     if (input_dir == InputDirection.dir) {
            //         if (self.direction != null) {
            //             return InputAction.finalizeUse;
            //         }
            //     } else if (settings.mode.use.use_action == .interact) {
            //         return InputAction.pickup;
            //     } else {
            //         return InputAction.dropItem;
            //     }
            // } else if (getTalentIndex(chr) != null) {
            //     // Releasing the talent does not take you out of use-mode.
            // } else if (getItemIndex(chr) != null) {
            //     // Releasing the item does not take you out of use-mode.
            // } else if (getSkillIndex(chr) != null) {
            //     // Releasing a skill key does not take you out of use-mode.
            // } else {
            //     return self.applyChar(chr, settings);
            // }

            return InputAction.none;
        } else {
            // if key was held, do nothing when it is up to avoid a final press
            if (is_held) {
                self.clearCharState(chr);
                return InputAction.none;
            } else {
                const action: InputAction = self.applyChar(chr, settings);

                self.clearCharState(chr);

                return action;
            }
        }
    }

    fn handleCharDown(self: *Input, chr: u8, settings: *const Settings) InputAction {
        _ = settings; // autofix
        // intercept debug and overlay toggle so they are not part of the regular control flow.
        // if (chr == DEBUG_TOGGLE_KEY) {
        //     return InputAction.debugToggle;
        // }
        // if (chr == OVERLAY_TOGGLE_KEY) {
        //     return InputAction.overlayToggle;
        // }

        const action: InputAction = InputAction.none;
        self.char_down_order.append(chr) catch std.debug.panic("Held down too many keys! {}", .{self.char_down_order});

        // if (settings.state == GameState.use) {
        //     action = self.handleCharDownUseMode(chr);
        // }

        if (chr == ' ') {
            // action = InputAction.cursorToggle;
        } else if (InputDirection.fromChar(chr)) |input_dir| {
            self.direction = input_dir;
        }
        // else if (!(settings.mode == .cursor and self.ctrl)) {
        //     if (getItemIndex(chr)) |index| {
        //         const slot = SLOTS[index];

        //         self.target = Target{ .slot = slot };
        //         action = InputAction{ .startUseItem = slot };

        //         // directions are cleared when entering use-mode
        //         self.direction = null;
        //     } else if (getSkillIndex(chr)) |index| {
        //         self.target = Target{ .skill = index };

        //         action = InputAction{ .startUseSkill = .{ .index = index, .action = self.actionMode() } };
        //         // directions are cleared when entering use-mode
        //         self.direction = null;
        //     } else if (getTalentIndex(chr)) |index| {
        //         self.target = Target{ .talent = index };

        //         action = InputAction{ .startUseTalent = index };
        //         // directions are cleared when entering use-mode
        //         self.direction = null;
        //     }
        // }

        return action;
    }

    /// Clear direction or target state for the given character, if applicable.
    fn clearCharState(self: *Input, chr: u8) void {
        if (InputDirection.fromChar(chr) != null) {
            self.direction = null;
        }

        // if (getTalentIndex(chr) != null) {
        //     self.target = null;
        // }

        // if (getSkillIndex(chr) != null) {
        //     self.target = null;
        // }

        // if (getItemIndex(chr) != null) {
        //     self.target = null;
        // }
    }

    fn applyChar(self: *Input, chr: u8, settings: *const Settings) InputAction {
        _ = settings; // autofix
        var action: InputAction = InputAction.none;

        // check if the key being released is the one that set the input direction.
        if (InputDirection.fromChar(chr)) |input_dir| {
            if (self.direction != null and std.meta.eql(self.direction.?, input_dir)) {
                switch (input_dir) {
                    InputDirection.dir => |dir| {
                        // if (settings.mode == .cursor) {
                        //     action = InputAction{ .cursorMove = .{ .dir = dir, .is_relative = self.ctrl, .is_long = self.shift } };
                        // }

                        if (self.alt) {
                            action = InputAction{ .face = dir };
                        } else {
                            action = InputAction{ .move = dir };
                        }
                    },

                    InputDirection.current => {
                        // if (settings.mode == .cursor and self.ctrl) {
                        //     action = InputAction.cursorReturn;
                        // } else {
                        //     action = InputAction.pass;
                        // }
                    },
                }
            }
            // if releasing a key that is directional, but not the last directional key
            // pressed, then do nothing, waiting for the last key to be released instead.
        }
        // else {
        //     if (settings.mode == .cursor) {
        //         if (getItemIndex(chr)) |index| {
        //             const slot = SLOTS[index];
        //             const cursor_pos = settings.mode.cursor.pos;
        //             action = InputAction{ .throwItem = .{ .pos = cursor_pos, .slot = slot } };
        //         }
        //     }

        //     // If we are not releasing a direction, skill, or item then try other keys.
        //     if (action == InputAction.none) {
        //         action = alphaUpToAction(chr);
        //     }
        // }

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
