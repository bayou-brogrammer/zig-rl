// Exports
pub const gui = @import("gui.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}

const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const mem = std.mem;
const Allocator = mem.Allocator;

const sdl3 = @import("sdl3");
const Texture = sdl3.SDL_Texture;
const Renderer = sdl3.SDL_Renderer;
const Font = sdl3.TTF_Font;
const Window = sdl3.SDL_Window;

pub const Display = struct {
    window: *Window,
    renderer: *Renderer,
    font: *Font,

    allocator: Allocator,

    pub fn init(window_name: [*c]const u8, window_width: c_int, window_height: c_int, allocator: Allocator) !Display {
        if (!sdl3.SDL_Init(sdl3.SDL_INIT_VIDEO)) {
            sdl3.SDL_Log("Unable to initialize SDL: %s", sdl3.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        if (!sdl3.TTF_Init()) {
            sdl3.SDL_Log("Unable to initialize SDL_ttf: %s", sdl3.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        const window = sdl3.SDL_CreateWindow(
            window_name,
            window_width,
            window_height,
            sdl3.SDL_WINDOW_OPENGL | sdl3.SDL_WINDOW_RESIZABLE,
        ) orelse {
            sdl3.SDL_Log("Unable to create window: %s", sdl3.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        // If testing, do not bring up window.
        if (@import("builtin").is_test) {
            sdl3.SDL_HideWindow(window);
        }

        const renderer = sdl3.SDL_CreateRenderer(
            window,
            null,
        ) orelse {
            sdl3.SDL_Log("Unable to create renderer: %s", sdl3.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const font = sdl3.TTF_OpenFont("data/Inconsolata-Bold.ttf", 20) orelse {
            sdl3.SDL_Log("Unable to create font from tff: %s", sdl3.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        return Display{
            .font = font,
            .window = window,
            .renderer = renderer,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Display) void {
        sdl3.TTF_CloseFont(self.font);
        sdl3.SDL_DestroyRenderer(self.renderer);
        sdl3.SDL_DestroyWindow(self.window);
        sdl3.SDL_Quit();
    }
};
