const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const mem = std.mem;
const fs = std.fs;
const Allocator = mem.Allocator;

const sdl2 = @import("sdl2.zig");
const Texture = sdl2.SDL_Texture;
const Renderer = sdl2.SDL_Renderer;
const Font = sdl2.TTF_Font;
const Window = sdl2.SDL_Window;

const drawing = @import("drawing");
const Justify = drawing.drawcmd.Justify;
const DrawCmd = drawing.drawcmd.DrawCmd;
const Panel = drawing.panel.Panel;

const canvas = @import("canvas.zig");

const math = @import("math");
const Pos = math.pos.Pos;
const MoveDirection = math.direction.MoveDirection;
const Color = math.utils.Color;
const Dims = math.dims.Dims;
const Rect = math.rect.Rect;

pub const Display = struct {
    window: *Window,
    renderer: *Renderer,
    font: *Font,
    ascii_texture: canvas.AsciiTexture,

    allocator: Allocator,

    pub fn init(window_name: [*c]const u8, window_width: c_int, window_height: c_int, allocator: Allocator) !Display {
        if (sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO) != 0) {
            sdl2.SDL_Log("Unable to initialize SDL: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        if (sdl2.TTF_Init() == -1) {
            sdl2.SDL_Log("Unable to initialize SDL_ttf: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        const window = sdl2.SDL_CreateWindow(window_name, sdl2.SDL_WINDOWPOS_UNDEFINED, sdl2.SDL_WINDOWPOS_UNDEFINED, window_width, window_height, sdl2.SDL_WINDOW_OPENGL) orelse {
            sdl2.SDL_Log("Unable to create window: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        // If testing, do not bring up window.
        if (@import("builtin").is_test) {
            sdl2.SDL_HideWindow(window);
        }

        const renderer = sdl2.SDL_CreateRenderer(window, -1, sdl2.SDL_RENDERER_ACCELERATED) orelse {
            sdl2.SDL_Log("Unable to create renderer: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        // NOTE default to rendering to the screen. If we move to multiple targets, we may use this as a final
        // back buffer so we can save/restore/etc the screen buffer.
        //if (sdl2.SDL_SetRenderTarget(renderer, screen_texture) != 0) {
        //    sdl2.SDL_Log("Unable to set render target: %s", sdl2.SDL_GetError());
        //    return error.SDLInitializationFailed; //}

        const font = sdl2.TTF_OpenFont("data/Inconsolata-Bold.ttf", 20) orelse {
            sdl2.SDL_Log("Unable to create font from tff: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const ascii_texture = try canvas.AsciiTexture.renderAsciiCharacters(renderer, font);

        return .{
            .window = window,
            .renderer = renderer,
            .font = font,
            .ascii_texture = ascii_texture,
            .allocator = allocator,
        };
    }

    pub fn charDims(display: *const Display, panel: *const Panel, scale: f32) Dims {
        const font_dims = canvas.fontDims(&display.ascii_texture);
        return canvas.textDims(panel, font_dims, scale);
    }

    pub fn clear(display: *Display, texture_panel: *TexturePanel, color: Color) void {
        _ = sdl2.SDL_SetRenderTarget(display.renderer, texture_panel.texture);
        _ = sdl2.SDL_SetRenderDrawBlendMode(display.renderer, sdl2.SDL_BLENDMODE_BLEND);
        _ = sdl2.SDL_SetRenderDrawColor(display.renderer, color.r, color.g, color.b, sdl2.SDL_ALPHA_OPAQUE);
        _ = sdl2.SDL_RenderClear(display.renderer);
    }

    pub fn makeCanvas(display: *Display, texture_panel: *TexturePanel) canvas.Canvas {
        const texture_canvas = canvas.Canvas.init(&texture_panel.panel, display.renderer, texture_panel.texture, display.ascii_texture);
        return texture_canvas;
    }

    pub fn draw(display: *Display, texture_panel: *TexturePanel) void {
        var texture_canvas = display.makeCanvas(texture_panel);
        for (texture_panel.drawcmds.items) |cmd| {
            texture_canvas.draw(&cmd);
        }
        texture_panel.drawcmds.clearRetainingCapacity();
    }

    pub fn useTexturePanel(display: *Display, texture_panel: *TexturePanel) void {
        _ = sdl2.SDL_SetTextureBlendMode(texture_panel.texture, sdl2.SDL_BLENDMODE_NONE);
        _ = sdl2.SDL_SetRenderTarget(display.renderer, texture_panel.texture);
        _ = sdl2.SDL_SetRenderDrawColor(display.renderer, 0, 0, 0, sdl2.SDL_ALPHA_OPAQUE);
        //_ = sdl2.SDL_RenderClear(display.renderer);
    }

    /// Paste an area of one texture onto an area of another texture, stretching or squishing the source texture to fit into the destination.
    pub fn stretchTexture(display: *Display, target: *TexturePanel, target_area: Rect, source: *TexturePanel, source_area: Rect) void {
        display.useTexturePanel(target);
        const src_rect = sdl2Rect(source.panel.getRectFromArea(source_area));
        const dst_rect = sdl2Rect(target.panel.getRectFromArea(target_area));
        _ = sdl2.SDL_RenderCopy(display.renderer, source.texture, &src_rect, &dst_rect);
    }

    /// Paste an area of one texture onto an area of another texture, while maintaining the aspect ratio of the original texture,
    /// centering the source texture within the remaining area of the destination texture.
    pub fn fitTexture(display: *Display, target: *TexturePanel, target_area: Rect, source: *TexturePanel, source_area: Rect) void {
        display.useTexturePanel(target);

        const src_rect = source.panel.getRectFromArea(source_area);
        const dst_rect = target.panel.getRectFromArea(target_area).fitWithin(src_rect);
        //const dst_rect = sdl2Rect(target.panel.getRectFromArea(target_area));

        //const x_scale = @intToFloat(f32, dst_rect.w) / @intToFloat(f32, src_rect.w);
        //const y_scale = @intToFloat(f32, dst_rect.h) / @intToFloat(f32, src_rect.h);
        //const scale = std.math.min(x_scale, y_scale);

        //const width = @floatToInt(i32, @intToFloat(f32, src_rect.w) * scale);
        //const height = @floatToInt(i32, @intToFloat(f32, src_rect.h) * scale);
        //const x = dst_rect.x + @divFloor((dst_rect.w - width), @as(c_int, 2));
        //const y = dst_rect.y + @divFloor((dst_rect.h - height), @as(c_int, 2));
        //const final_dst_rect = sdl2.SDL_Rect{ .x = x, .y = y, .w = width, .h = height };

        const sdl2_src_rect = sdl2Rect(src_rect);
        const sdl2_dst_rect = sdl2Rect(dst_rect);
        _ = sdl2.SDL_RenderCopy(display.renderer, source.texture, &sdl2_src_rect, &sdl2_dst_rect);
    }

    pub fn overlayTexture(display: *Display, target: *TexturePanel, target_area: Rect, source: *TexturePanel, source_area: Rect, alpha: u8) void {
        _ = sdl2.SDL_SetTextureAlphaMod(source.texture, alpha);
        _ = sdl2.SDL_SetTextureBlendMode(target.texture, sdl2.SDL_BLENDMODE_BLEND);
        _ = sdl2.SDL_SetRenderTarget(display.renderer, target.texture);
        _ = sdl2.SDL_SetRenderDrawColor(display.renderer, 0, 0, 0, sdl2.SDL_ALPHA_OPAQUE);

        const src_rect = source.panel.getRectFromArea(source_area);
        const dst_rect = target.panel.getRectFromArea(target_area);

        const sdl2_src_rect = sdl2Rect(src_rect);
        const sdl2_dst_rect = sdl2Rect(dst_rect);
        _ = sdl2.SDL_RenderCopy(display.renderer, source.texture, &sdl2_src_rect, &sdl2_dst_rect);
    }

    /// Draw a texture panel onto the screen and present it to the user. The entire texture is drawn on the
    /// screen, so it should usually be the same size as the renderer's window.
    ///
    /// Note that this requires a separate back buffer texture, even if only using one texture for drawing.
    pub fn present(display: *Display, texture_panel: *TexturePanel) void {
        _ = sdl2.SDL_SetRenderTarget(display.renderer, null);

        _ = sdl2.SDL_RenderCopy(display.renderer, texture_panel.texture, null, null);

        sdl2.SDL_RenderPresent(display.renderer);
    }

    pub fn texturePanel(display: *Display, panel: Panel, allocator: Allocator) !TexturePanel {
        const drawcmds = ArrayList(DrawCmd).init(allocator);

        const width = @as(c_int, @intCast(panel.num_pixels.width));
        const height = @as(c_int, @intCast(panel.num_pixels.height));

        const texture = sdl2.SDL_CreateTexture(display.renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_TARGET, width, height) orelse {
            sdl2.SDL_Log("Unable to create screen texture: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        return TexturePanel.init(texture, panel, drawcmds);
    }

    //fn renderText(self: *Display, text: []const u8, color: sdl2.SDL_Color) !*Texture {
    //    const c_text = @ptrCast([*c]const u8, text);
    //    const text_surface = sdl2.TTF_RenderText_Blended(self.font, c_text, color) orelse {
    //        sdl2.SDL_Log("Unable to create text from font: %s", sdl2.SDL_GetError());
    //        return error.SDLInitializationFailed;
    //    };

    //    const texture = sdl2.SDL_CreateTextureFromSurface(self.renderer, text_surface) orelse {
    //        sdl2.SDL_Log("Unable to create texture from surface: %s", sdl2.SDL_GetError());
    //        return error.SDLInitializationFailed;
    //    };

    //    return texture;
    //}

    pub fn deinit(self: *Display) void {
        self.ascii_texture.deinit();
        sdl2.TTF_CloseFont(self.font);
        sdl2.SDL_DestroyRenderer(self.renderer);
        sdl2.SDL_DestroyWindow(self.window);
        sdl2.SDL_Quit();
    }

    pub fn wait_for_frame(self: *Display) void {
        _ = self;
        sdl2.SDL_Delay(17);
    }

    pub fn handle_input(self: *Display) bool {
        _ = self;

        var quit = false;

        var event: sdl2.SDL_Event = undefined;
        while (sdl2.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl2.SDL_QUIT => {
                    quit = true;
                },

                // SDL_Scancode scancode;      /**< SDL physical key code - see ::SDL_Scancode for details */
                // SDL_Keycode sym;            /**< SDL virtual key code - see ::SDL_Keycode for details */
                // Uint16 mod;                 /**< current key modifiers */
                sdl2.SDL_KEYDOWN => {
                    const code: i32 = event.key.keysym.sym;
                    const key: sdl2.SDL_KeyCode = @as(c_uint, @intCast(code));

                    //const a_code = sdl2.SDLK_a;
                    //const z_code = sdl2.SDLK_z;

                    if (key == sdl2.SDLK_RETURN) {
                        sdl2.SDL_Log("Pressed enter");
                    } else if (key == sdl2.SDLK_ESCAPE) {
                        quit = true;
                    } else {
                        sdl2.SDL_Log("Pressed: %c", key);
                    }
                },

                sdl2.SDL_KEYUP => {},

                sdl2.SDL_MOUSEMOTION => {
                    //self.state.mouse = sdl2.SDL_Point{ .x = event.motion.x, .y = event.motion.y };
                },

                sdl2.SDL_MOUSEBUTTONDOWN => {},

                sdl2.SDL_MOUSEBUTTONUP => {},

                sdl2.SDL_MOUSEWHEEL => {},

                // just for fun...
                sdl2.SDL_DROPFILE => {
                    sdl2.SDL_Log("Dropped file '%s'", event.drop.file);
                },
                sdl2.SDL_DROPTEXT => {
                    sdl2.SDL_Log("Dropped text '%s'", event.drop.file);
                },
                sdl2.SDL_DROPBEGIN => {
                    sdl2.SDL_Log("Drop start");
                },
                sdl2.SDL_DROPCOMPLETE => {
                    sdl2.SDL_Log("Drop done");
                },

                // could be used for clock tick
                sdl2.SDL_USEREVENT => {},

                else => {},
            }
        }

        return quit;
    }

    pub fn textDims(self: *Display, text: []const u8) Dims {
        return Dims.init(self.ascii_texture.char_width * @as(i32, @intCast(text.len)), self.ascii_texture.char_height);
    }
};

pub const TexturePanel = struct {
    texture: *Texture,
    drawcmds: ArrayList(DrawCmd),
    panel: Panel,

    pub fn init(texture: *Texture, panel: Panel, drawcmds: ArrayList(DrawCmd)) TexturePanel {
        return TexturePanel{ .texture = texture, .panel = panel, .drawcmds = drawcmds };
    }

    pub fn initWithTexture(texture: *Texture, panel: Panel, allocator: Allocator) TexturePanel {
        const cmds = ArrayList(DrawCmd).init(allocator);
        return TexturePanel.init(texture, panel, cmds);
    }

    pub fn deinit(panel: *TexturePanel) void {
        sdl2.SDL_DestroyTexture(panel.texture);
        panel.drawcmds.deinit();
    }

    pub fn addDrawCmd(panel: *TexturePanel, drawcmd: DrawCmd) !void {
        try panel.drawcmds.append(drawcmd);
    }
};

fn sdl2Rect(rect: Rect) sdl2.SDL_Rect {
    return sdl2.SDL_Rect{ .x = @as(c_int, @intCast(rect.x_offset)), .y = @as(c_int, @intCast(rect.y_offset)), .w = @as(c_int, @intCast(rect.width)), .h = @as(c_int, @intCast(rect.height)) };
}
