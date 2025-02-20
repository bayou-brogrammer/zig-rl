// SPDX-FileCopyrightText: © 2024 Mark Delk <jethrodaniel@gmail.com>
//
// SPDX-License-Identifier: Zlib

const std = @import("std");
const c = @import("sdl");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

pub fn main() !void {
    std.log.debug("minimal..", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("found memory leaks");
    const allocator = gpa.allocator();

    //--

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.log.err("Unable to initialize SDL: {s}", .{c.SDL_GetError()});
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const data_dir_cstr = c.SDL_GetBasePath() orelse {
        std.log.err("SDL_GetBasePath: {s}", .{c.SDL_GetError()});
        return error.SDL_GetBasePath;
    };
    const data_dir = std.mem.span(data_dir_cstr);
    std.log.debug("data_dir: {s}", .{data_dir});

    const sdl_version = c.SDL_GetVersion();
    const sdl_version_text = try std.fmt.allocPrint(allocator, "v{d}.{d}.{d}", .{
        c.SDL_VERSIONNUM_MAJOR(sdl_version),
        c.SDL_VERSIONNUM_MINOR(sdl_version),
        c.SDL_VERSIONNUM_MICRO(sdl_version),
    });
    defer allocator.free(sdl_version_text);
    std.log.debug("SDL version: {s}", .{sdl_version_text});

    const window_name = try std.fmt.allocPrintZ(allocator, "SDL {s}", .{sdl_version_text});
    defer allocator.free(window_name);

    const window = c.SDL_CreateWindow(
        window_name,
        400,
        400,
        c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        std.log.err("SDL_CreateWindow: {s}", .{c.SDL_GetError()});
        return error.SDL_CreateWindow;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(
        window,
        null,
    ) orelse {
        std.log.err("SDL_CreateRenderer: {s}", .{c.SDL_GetError()});
        return error.SDL_CreateRenderer;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var quit = false;

    while (!quit) {
        const start_time = c.SDL_GetTicks();

        var event: c.SDL_Event = undefined;

        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    std.log.debug("exit", .{});
                    quit = true;
                },
                c.SDL_EVENT_KEY_DOWN => {
                    switch (event.key.key) {
                        c.SDLK_A => {
                            std.log.debug("a", .{});
                        },
                        else => {
                            std.log.debug("something else", .{});
                        },
                    }
                },
                c.SDL_EVENT_WINDOW_RESIZED => {
                    std.log.debug("resized", .{});
                },
                else => {},
            }
        }

        // clear screen
        if (!c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 0)) {
            std.log.err("SDL_SetRenderDrawColor: {s}", .{c.SDL_GetError()});
            return error.SDL_SetRenderDrawColor;
        }
        _ = c.SDL_RenderClear(renderer);

        _ = c.SDL_RenderPresent(renderer);

        const end_time = c.SDL_GetTicks();
        const elapsed = end_time - start_time;

        const FRAMES_PER_SECOND = 60;
        const MS_PER_FRAME = 1_000 / FRAMES_PER_SECOND;

        const delay = if (elapsed >= MS_PER_FRAME)
            MS_PER_FRAME
        else
            MS_PER_FRAME - elapsed;

        c.SDL_DelayNS(delay * std.time.ns_per_ms);
    }

    c.SDL_Quit();
}
