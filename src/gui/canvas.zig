const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const assert = std.debug.assert;

const sdl2 = @import("sdl2.zig");
const Texture = sdl2.SDL_Texture;
const Renderer = sdl2.SDL_Renderer;
const Font = sdl2.TTF_Font;

const drawing = @import("drawing");
const sprite = drawing.sprite;
const pnl = drawing.panel;
const Panel = pnl.Panel;
const DrawCmd = drawing.drawcmd.DrawCmd;
const Sprite = sprite.Sprite;
const SpriteSheet = sprite.SpriteSheet;

const utils = @import("utils");
const Str = utils.intern.Str;

const math = @import("math");
const Pos = math.pos.Pos;
const Color = math.utils.Color;
const Dims = math.dims.Dims;
const Rect = math.rect.Rect;

pub const Canvas = struct {
    panel: *Panel,
    renderer: *Renderer,
    target: *Texture,
    ascii_texture: AsciiTexture,

    pub fn init(panel: *Panel, renderer: *Renderer, target: *Texture, ascii_texture: AsciiTexture) Canvas {
        return Canvas{ .panel = panel, .renderer = renderer, .target = target, .ascii_texture = ascii_texture };
    }

    pub fn draw(canvas: *Canvas, draw_cmd: *const DrawCmd) void {
        processDrawCmd(canvas.panel, canvas.renderer, canvas.target, canvas.ascii_texture, draw_cmd);
    }
};

pub const AsciiTexture = struct {
    texture: *Texture,
    num_chars: i32,
    width: i32,
    height: i32,
    char_width: i32,
    char_height: i32,

    pub fn init(texture: *Texture, num_chars: i32, width: i32, height: i32, char_width: i32, char_height: i32) AsciiTexture {
        return AsciiTexture{ .texture = texture, .num_chars = num_chars, .width = width, .height = height, .char_width = char_width, .char_height = char_height };
    }

    pub fn deinit(self: *AsciiTexture) void {
        sdl2.SDL_DestroyTexture(self.texture);
    }

    pub fn renderAsciiCharacters(renderer: *Renderer, font: *Font) !AsciiTexture {
        sdl2.TTF_SetFontStyle(font, sdl2.TTF_STYLE_BOLD);

        var chrs: [256]u8 = undefined;
        var chr_index: usize = 0;
        while (chr_index < 256) : (chr_index += 1) {
            chrs[chr_index] = @as(u8, @intCast(chr_index));
        }
        chrs[math.utils.ASCII_END + 1] = 0;

        const txt = chrs[math.utils.ASCII_START..math.utils.ASCII_END];

        const text_surface = sdl2.TTF_RenderText_Blended(font, txt.ptr, txt.len, Sdl2Color(Color.white()));
        defer sdl2.SDL_DestroySurface(text_surface);

        const font_texture = sdl2.SDL_CreateTextureFromSurface(renderer, text_surface) orelse {
            sdl2.SDL_Log("Unable to create sprite texture: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        var w: f32 = undefined;
        var h: f32 = undefined;
        _ = sdl2.SDL_GetTextureSize(font_texture, &w, &h);

        const ascii_width = math.utils.ASCII_END - math.utils.ASCII_START;

        const width = @as(i32, @intFromFloat(w));
        const height = @as(i32, @intFromFloat(h));
        const char_width = @divFloor(@as(i32, @intFromFloat(w)), @as(i32, @intCast(ascii_width)));
        const char_height = @as(i32, @intFromFloat(h));

        const ascii_texture = AsciiTexture.init(
            font_texture,
            ascii_width,
            width,
            height,
            char_width,
            char_height,
        );

        return ascii_texture;
    }

    pub fn charDims(self: AsciiTexture) Dims {
        return Dims.init(@intCast(self.char_width), @intCast(self.char_height));
    }
};

pub fn processDrawCmd(panel: *Panel, renderer: *Renderer, texture: *Texture, ascii_texture: AsciiTexture, draw_cmd: *const DrawCmd) void {
    const canvas = Canvas.init(panel, renderer, texture, ascii_texture);
    switch (draw_cmd.*) {
        .text => |params| processText(canvas, params),
        .textFloat => |params| processTextFloat(canvas, params),
        .textJustify => |params| processTextJustify(canvas, params),

        .rect => |params| processRectCmd(canvas, params),
        .rectFloat => |params| processRectFloatCmd(canvas, params),

        .fill => |params| processFillCmd(canvas, params),
    }
}

pub fn processTextGeneric(canvas: Canvas, text: [128]u8, len: usize, color: Color, pixel_pos: Pos, scale: f32) void {
    //const cell_dims = canvas.panel.cellDims();

    const font_dims = fontDims(&canvas.ascii_texture);
    const char_dims = textDims(canvas.panel, font_dims, scale);

    _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_BLEND);
    _ = sdl2.SDL_SetTextureColorMod(canvas.ascii_texture.texture, color.r, color.g, color.b);
    _ = sdl2.SDL_SetTextureAlphaMod(canvas.ascii_texture.texture, color.a);

    const y_offset = pixel_pos.y;
    var x_offset = pixel_pos.x;

    if (x_offset < 0 or y_offset < 0) {
        return;
    }

    for (text[0..len]) |chr| {
        if (chr == 0) {
            break;
        }

        const chr_num = std.ascii.toLower(chr);
        const chr_index = @as(i32, @intCast(chr_num)) - @as(i32, @intCast(math.utils.ASCII_START));

        const src_rect = Rect.initAt(font_dims.width * @as(i32, @intCast(chr_index)), 0, @as(i32, @intCast(font_dims.width)), @as(i32, @intCast(font_dims.height)));

        const dst_pos = Pos.init(x_offset, y_offset);
        const dst_rect = Rect.initAt(
            @as(i32, @intCast(dst_pos.x)),
            @as(i32, @intCast(dst_pos.y)),
            @as(i32, @intCast(char_dims.width)),
            @as(i32, @intCast(char_dims.height)),
        );

        _ = sdl2.SDL_RenderTextureRotated(canvas.renderer, canvas.ascii_texture.texture, &Sdl2Rect(src_rect), &Sdl2Rect(dst_rect), 0.0, null, 0);
        x_offset += @as(i32, @intCast(char_dims.width));
    }
}

pub fn processTextJustify(canvas: Canvas, params: drawing.drawcmd.DrawTextJustify) void {
    const cell_dims = canvas.panel.cellDims();

    const char_width_unscaled = @divFloor((cell_dims.height * canvas.ascii_texture.char_width), canvas.ascii_texture.char_height);
    const char_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(char_width_unscaled)) * params.scale));

    //const char_height_unscaled = (cell_dims.height * canvas.ascii_texture.char_width) / canvas.ascii_texture.char_height;
    //const char_height = @as(u32, @intFromFloat(@floatFromInt(f32, char_width_unscaled) * params.scale));

    const pixel_width = params.width * cell_dims.width;

    var x_offset: i32 = undefined;
    const length: i32 = @intCast(params.len);
    switch (params.justify) {
        .right => {
            x_offset = (@as(i32, @intCast(params.pos.x)) * cell_dims.width) + pixel_width - char_width * length;
        },

        .center => {
            x_offset = (@as(i32, @intCast(params.pos.x)) * cell_dims.width) + @divFloor(pixel_width, 2) - @divFloor(char_width * length, 2);
        },

        .left => {
            x_offset = @as(i32, @intCast(params.pos.x)) * cell_dims.width;
        },
    }

    const y_offset = @as(i32, @intCast(params.pos.y)) * cell_dims.height;

    if (params.bg_color) |bg_color| {
        _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_NONE);
        const char_height = @as(i32, @intFromFloat(@as(f32, @floatFromInt(cell_dims.height)) * params.scale));
        const rect = Rect.initAt(x_offset, y_offset, @as(i32, @intCast(length * char_width)), char_height);
        _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, bg_color.r, bg_color.g, bg_color.b, bg_color.a);
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(rect));
    }
    _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_BLEND);

    const x = @as(i32, @intCast(x_offset));
    const y = @as(i32, @intCast(y_offset));
    processTextGeneric(canvas, params.text, params.len, params.color, Pos.init(x, y), params.scale);
}

pub fn processTextFloat(canvas: Canvas, params: drawing.drawcmd.DrawTextFloat) void {
    const cell_dims = canvas.panel.cellDims();

    const length: i32 = @intCast(params.len);

    const char_width_unscaled = @divFloor((cell_dims.height * canvas.ascii_texture.char_width), canvas.ascii_texture.char_height);
    const char_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(char_width_unscaled)) * params.scale));
    const text_pixel_width = length * char_width;

    const pixel_width = cell_dims.width;

    var x_offset = @as(i32, @intFromFloat(params.x * @as(f32, @floatFromInt(cell_dims.width))));
    switch (params.justify) {
        .right => {
            x_offset += @as(i32, @intCast(pixel_width)) - char_width * length;
        },

        .center => {
            x_offset -= @divFloor(text_pixel_width, 2);
        },

        // left is the default above.
        .left => {},
    }

    const y_offset = @as(i32, @intFromFloat(params.y * @as(f32, @floatFromInt(cell_dims.height))));
    processTextGeneric(canvas, params.text, params.len, params.color, Pos.init(x_offset, y_offset), params.scale);
}

pub fn processText(canvas: Canvas, params: drawing.drawcmd.DrawText) void {
    const cell_dims = canvas.panel.cellDims();

    const x_offset = params.pos.x * @as(i32, @intCast(cell_dims.width));
    const y_offset = params.pos.y * @as(i32, @intCast(cell_dims.height));

    processTextGeneric(canvas, params.text, params.len, params.color, Pos.init(x_offset, y_offset), params.scale);
}

pub fn processFillCmd(canvas: Canvas, params: drawing.drawcmd.DrawFill) void {
    const cell_dims = canvas.panel.cellDims();
    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);
    const x = params.pos.x;
    const y = params.pos.y;
    const src_rect = Rect.initAt(x * cell_dims.width, y * cell_dims.height, cell_dims.width, cell_dims.height);
    var sdl2_rect = Sdl2Rect(src_rect);
    _ = sdl2.SDL_RenderFillRect(canvas.renderer, &sdl2_rect);
}

pub fn processRectCmd(canvas: Canvas, params: drawing.drawcmd.DrawRect) void {
    assert(params.offset_percent < 1.0);

    const cell_dims = canvas.panel.cellDims();

    _ = sdl2.SDL_SetRenderDrawBlendMode(canvas.renderer, sdl2.SDL_BLENDMODE_BLEND);
    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);

    const offset_x = @as(i32, @intFromFloat(@as(f32, @floatFromInt(cell_dims.width)) * params.offset_percent));
    const x: i32 = @as(i32, @intCast(cell_dims.width)) * @as(i32, @intCast(params.pos.x)) + offset_x;

    const offset_y = @as(i32, @intFromFloat(@as(f32, @floatFromInt(cell_dims.height)) * params.offset_percent));
    const y: i32 = @as(i32, @intCast(cell_dims.height)) * @as(i32, @intCast(params.pos.y)) + offset_y;

    const width = @as(i32, @intCast(cell_dims.width * params.width - (2 * @as(i32, @intCast(offset_x)))));
    const height = @as(i32, @intCast(cell_dims.height * params.height - (2 * @as(i32, @intCast(offset_y)))));

    if (params.filled) {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x, y, width, height)));
    } else {
        const size = @divFloor(@divFloor(canvas.panel.num_pixels.width, canvas.panel.cells.width), 10);
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x, y, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x, y, width, size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x + width, y, size, height + size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x, y + height, width + size, size)));
    }
}

pub fn processRectFloatCmd(canvas: Canvas, params: drawing.drawcmd.DrawRectFloat) void {
    const cell_dims = canvas.panel.cellDims();

    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);

    const x_offset = @as(i32, @intFromFloat(params.x * @as(f32, @floatFromInt(cell_dims.width))));
    const y_offset = @as(i32, @intFromFloat(params.y * @as(f32, @floatFromInt(cell_dims.height))));

    const width = @as(i32, @intFromFloat(params.width * @as(f32, @floatFromInt(cell_dims.width))));
    const height = @as(i32, @intFromFloat(params.height * @as(f32, @floatFromInt(cell_dims.height))));

    const size = @divFloor(@divFloor(canvas.panel.num_pixels.width, canvas.panel.cells.width), 5);
    if (params.filled) {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x_offset, y_offset, width, height)));
    } else {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x_offset, y_offset, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x_offset, y_offset, width + size, size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x_offset + width, y_offset, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.initAt(x_offset, y_offset + height - size, width + size, size)));
    }
}

pub fn Sdl2Color(color: Color) sdl2.SDL_Color {
    return sdl2.SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
}

pub fn Sdl2Rect(rect: Rect) sdl2.SDL_FRect {
    return sdl2.SDL_FRect{
        .x = @as(f32, @floatFromInt(rect.x_offset)),
        .y = @as(f32, @floatFromInt(rect.y_offset)),
        .w = @as(f32, @floatFromInt(rect.width)),
        .h = @as(f32, @floatFromInt(rect.height)),
    };
}

pub fn fontDims(ascii_texture: *const AsciiTexture) Dims {
    const ascii_width = math.utils.ASCII_END - math.utils.ASCII_START;

    const font_width = @divFloor(@as(i32, @intCast(ascii_texture.width)), ascii_width);
    const font_height = @as(i32, @intCast(ascii_texture.height));

    return Dims.init(font_width, font_height);
}

pub fn textDims(panel: *const Panel, font_dims: Dims, scale: f32) Dims {
    const cell_dims = panel.cellDims();

    // The height is simply the height of a cell.
    const char_height = @as(i32, @intFromFloat(@as(f32, @floatFromInt(cell_dims.height)) * scale));

    // The width is adjusted based on the width of the rendered character width and the cell height to
    // create the width coorsponding to the given height and original width.
    const char_width_unscaled = @divFloor((cell_dims.height * font_dims.width), font_dims.height);
    const char_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(char_width_unscaled)) * scale));

    return Dims.init(char_width, char_height);
}
