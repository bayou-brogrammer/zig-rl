const std = @import("std");
const sdl3 = @import("sdl3");

const math = @import("math");
const Pos = math.pos.Pos;

const engine = @import("engine");
const InputEvent = engine.input.InputEvent;
const KeyDir = engine.input.KeyDir;
const MouseButton = engine.input.MouseButton;

pub fn translateEvent(event: sdl3.SDL_Event) ?InputEvent {
    switch (event.type) {
        sdl3.SDL_EVENT_QUIT => {
            return InputEvent.quit;
        },

        else => {
            return null;
        },
    }
}
