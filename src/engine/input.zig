const math = @import("math");
const Pos = math.pos.Pos;

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
