const std = @import("std");
const sdl2 = @import("sdl2.zig");

const math = @import("math");
const Pos = math.pos.Pos;

const engine = @import("engine");
const InputEvent = engine.input.InputEvent;
const KeyDir = engine.input.KeyDir;
const MouseButton = engine.input.MouseButton;

pub fn translateEvent(event: sdl2.SDL_Event) ?InputEvent {
    switch (event.type) {
        sdl2.SDL_EVENT_QUIT => {
            return InputEvent.quit;
        },

        sdl2.SDL_EVENT_KEY_DOWN => {
            const keycode: u32 = event.key.key;

            var dir = KeyDir.down;

            if (event.key.repeat) {
                dir = KeyDir.held;
            }

            if (keycodeToChar(keycode)) |chr| {
                return InputEvent{ .char = .{ .chr = chr, .key_dir = dir } };
            } else if (keycode == sdl2.SDLK_LCTRL or keycode == sdl2.SDLK_RCTRL) {
                return InputEvent{ .ctrl = dir };
            } else if (keycode == sdl2.SDLK_LALT or keycode == sdl2.SDLK_RALT) {
                return InputEvent{ .alt = dir };
            } else if (keycode == sdl2.SDLK_LSHIFT or keycode == sdl2.SDLK_RSHIFT) {
                return InputEvent{ .shift = dir };
            } else if (keycode == sdl2.SDLK_KP_ENTER or keycode == sdl2.SDLK_RETURN) {
                // TODO what about RETURN2
                return InputEvent{ .enter = KeyDir.down };
            } else {
                return null;
            }

            return null;
        },

        sdl2.SDL_EVENT_KEY_UP => {
            const keycode: u32 = event.key.key;

            if (event.key.repeat) {
                return null;
            }

            if (keycodeToChar(keycode)) |chr| {
                return InputEvent{ .char = .{ .chr = chr, .key_dir = KeyDir.up } };
            } else if (keycode == sdl2.SDLK_LCTRL or keycode == sdl2.SDLK_RCTRL) {
                return InputEvent{ .ctrl = KeyDir.up };
            } else if (keycode == sdl2.SDLK_LALT or keycode == sdl2.SDLK_RALT) {
                return InputEvent{ .alt = KeyDir.up };
            } else if (keycode == sdl2.SDLK_KP_TAB) {
                return InputEvent.tab;
            } else if (keycode == sdl2.SDLK_ESCAPE) {
                return InputEvent.esc;
            } else if (keycode == sdl2.SDLK_LSHIFT or keycode == sdl2.SDLK_RSHIFT) {
                return InputEvent{ .shift = KeyDir.up };
            } else if (keycode == sdl2.SDLK_KP_ENTER or keycode == sdl2.SDLK_RETURN) {
                return InputEvent{ .enter = KeyDir.up };
            } else {
                // NOTE could check for LShift, RShift
                return null;
            }

            return null;
        },

        // I think this is slightly wrong if multiple buttons change at the same time.
        sdl2.SDL_EVENT_MOUSE_BUTTON_DOWN => {
            var button: MouseButton = undefined;
            switch (event.button.button) {
                sdl2.SDL_BUTTON_LEFT => {
                    button = MouseButton.left;
                },

                sdl2.SDL_BUTTON_RIGHT => {
                    button = MouseButton.right;
                },

                sdl2.SDL_BUTTON_MIDDLE => {
                    button = MouseButton.middle;
                },

                else => return null,
            }

            const mouse_pos = Pos.init(@intFromFloat(event.button.x), @intFromFloat(event.button.y));
            const input_event = InputEvent{ .mouse_button = .{ .button = button, .pos = mouse_pos, .key_dir = KeyDir.down } };
            return input_event;
        },

        sdl2.SDL_EVENT_MOUSE_MOTION => {
            return InputEvent{ .mouse_pos = .{ .x = @intFromFloat(event.motion.x), .y = @intFromFloat(event.motion.y) } };
        },

        // I think this is slightly wrong if multiple buttons change at the same time.
        sdl2.SDL_EVENT_MOUSE_BUTTON_UP => {
            var button: MouseButton = undefined;
            switch (event.button.button) {
                sdl2.SDL_BUTTON_LEFT => {
                    button = MouseButton.left;
                },

                sdl2.SDL_BUTTON_RIGHT => {
                    button = MouseButton.right;
                },

                sdl2.SDL_BUTTON_MIDDLE => {
                    button = MouseButton.middle;
                },

                else => return null,
            }

            const mouse_pos = Pos.init(@intFromFloat(event.button.x), @intFromFloat(event.button.y));
            const input_event = InputEvent{ .mouse_button = .{ .button = button, .pos = mouse_pos, .key_dir = KeyDir.up } };
            return input_event;
        },

        else => {
            return null;
        },
    }
}

pub fn keycodeToChar(key: u32) ?u8 {
    return switch (key) {
        sdl2.SDLK_SPACE => ' ',
        sdl2.SDLK_COMMA => ',',
        sdl2.SDLK_MINUS => '-',
        sdl2.SDLK_PERIOD => '.',
        sdl2.SDLK_0 => '0',
        sdl2.SDLK_1 => '1',
        sdl2.SDLK_2 => '2',
        sdl2.SDLK_3 => '3',
        sdl2.SDLK_4 => '4',
        sdl2.SDLK_5 => '5',
        sdl2.SDLK_6 => '6',
        sdl2.SDLK_7 => '7',
        sdl2.SDLK_8 => '8',
        sdl2.SDLK_9 => '9',
        sdl2.SDLK_A => 'a',
        sdl2.SDLK_B => 'b',
        sdl2.SDLK_C => 'c',
        sdl2.SDLK_D => 'd',
        sdl2.SDLK_E => 'e',
        sdl2.SDLK_F => 'f',
        sdl2.SDLK_G => 'g',
        sdl2.SDLK_H => 'h',
        sdl2.SDLK_I => 'i',
        sdl2.SDLK_J => 'j',
        sdl2.SDLK_K => 'k',
        sdl2.SDLK_L => 'l',
        sdl2.SDLK_M => 'm',
        sdl2.SDLK_N => 'n',
        sdl2.SDLK_O => 'o',
        sdl2.SDLK_P => 'p',
        sdl2.SDLK_Q => 'q',
        sdl2.SDLK_R => 'r',
        sdl2.SDLK_S => 's',
        sdl2.SDLK_T => 't',
        sdl2.SDLK_U => 'u',
        sdl2.SDLK_V => 'v',
        sdl2.SDLK_W => 'w',
        sdl2.SDLK_X => 'x',
        sdl2.SDLK_Y => 'y',
        sdl2.SDLK_Z => 'z',
        sdl2.SDLK_RIGHT => '6',
        sdl2.SDLK_LEFT => '4',
        sdl2.SDLK_DOWN => '2',
        sdl2.SDLK_UP => '8',
        sdl2.SDLK_KP_0 => '0',
        sdl2.SDLK_KP_1 => '1',
        sdl2.SDLK_KP_2 => '2',
        sdl2.SDLK_KP_3 => '3',
        sdl2.SDLK_KP_4 => '4',
        sdl2.SDLK_KP_5 => '5',
        sdl2.SDLK_KP_6 => '6',
        sdl2.SDLK_KP_7 => '7',
        sdl2.SDLK_KP_8 => '8',
        sdl2.SDLK_KP_9 => '9',
        sdl2.SDLK_KP_PERIOD => '.',
        sdl2.SDLK_KP_SPACE => ' ',
        sdl2.SDLK_LEFTBRACKET => '[',
        sdl2.SDLK_RIGHTBRACKET => ']',
        sdl2.SDLK_GRAVE => '`',
        sdl2.SDLK_BACKSLASH => '\\',
        sdl2.SDLK_QUESTION => '?',
        sdl2.SDLK_SLASH => '/',
        else => null,
    };
}
