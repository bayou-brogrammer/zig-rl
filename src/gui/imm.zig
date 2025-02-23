const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

const math = @import("math");
const Pos = math.pos.Pos;
const Color = math.utils.Color;
const Easing = math.easing.Easing;
const Tween = math.tweening.Tween;
const Dims = math.dims.Dims;
const Rect = math.rect.Rect;

const engine = @import("engine");
const MouseState = engine.input.MouseState;
const KeyDir = engine.input.KeyDir;

const drawing = @import("drawing");
const DrawCmd = drawing.drawcmd.DrawCmd;
const Panel = drawing.panel.Panel;

const AlphaMap = StringHashMap(Alpha);

const Alpha = struct {
    alpha: Tween,

    pub fn init() Alpha {
        var new_alpha = Alpha{ .alpha = Tween.init(255.0, 0.0, 0.3, Easing.linearInterpolation) };
        new_alpha.alpha.elapsed = new_alpha.alpha.duration;
        return new_alpha;
    }

    pub fn reset(alpha: *Alpha) void {
        alpha.alpha.reset();
    }
};

const MouseButtonState = struct {
    mouseover: bool = false,
    clicked: bool = false,
};

pub const Imm = struct {
    alphas: AlphaMap,
    pos: Pos,
    char_dims: Dims,

    pub const Config = struct {
        drawcmds: *ArrayList(DrawCmd),
        color: Color = Color.white(),
        outline: bool = false,
        justify: drawing.drawcmd.Justify = .center,
        position: ?Pos = null,

        pub fn init(drawcmds: *ArrayList(DrawCmd), color: Color) Config {
            return .{ .drawcmds = drawcmds, .color = color };
        }
    };

    pub fn init(allocator: Allocator, char_dims: Dims) Imm {
        return Imm{ .alphas = AlphaMap.init(allocator), .pos = Pos.init(0, 0), .char_dims = char_dims };
    }

    pub fn deinit(imm: *Imm) void {
        imm.alphas.deinit();
    }

    pub fn clear(imm: *Imm) void {
        imm.alphas.clearAndFree();
    }

    pub fn deltaTime(imm: *Imm, ms: u64) void {
        var iter = imm.alphas.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.alpha.deltaTimeMs(ms);
        }
    }

    pub fn button(imm: *Imm, panel: Panel, mouse: MouseState, name: []const u8, label: []const u8, config: Config) !?KeyDir {
        const fg_color = config.color;
        var bg_color = fg_color;
        const width = @as(i32, @intCast(label.len));
        const height = 1;

        const cell_dims = panel.cellDims();
        const text_width = width * @as(i32, @intCast(imm.char_dims.width));
        const cell_width = @as(i32, @intCast(cell_dims.width));
        var rect_width = @divFloor(text_width, cell_width);
        if (@rem(text_width, cell_width) > 0) {
            rect_width += 1;
        }

        const position = config.position orelse imm.pos;

        const mouse_button_state = try imm.mouseInteraction(name, position, rect_width, height, panel, mouse);

        bg_color.a = @intFromFloat(imm.alphas.get(name).?.alpha.value());

        bg_color.a /= 2;
        if (!mouse_button_state.clicked) {
            bg_color.a /= 2;
        }

        try config.drawcmds.append(DrawCmd.rectCmd(position, @intCast(rect_width), 1, 0.0, true, bg_color));
        if (config.outline) {
            try config.drawcmds.append(DrawCmd.rectCmd(position, @intCast(rect_width), 1, 0.0, false, fg_color));
        }
        try config.drawcmds.append(DrawCmd.textJustifyCmd(label, config.justify, position, config.color, null, @intCast(rect_width), 1.0));
        if (config.position == null) {
            imm.pos = imm.pos.moveY(1);
        }

        var click_state: ?KeyDir = null;
        if (mouse_button_state.clicked) {
            click_state = mouse.left.?.dir;
        }

        return click_state;
    }

    pub fn checkbox(imm: *Imm, panel: Panel, mouse: MouseState, name: []const u8, label: []const u8, state: *bool, config: Config) !bool {
        const fg_color = config.color;
        var bg_color = fg_color;

        //const mouse_cell_pos = panel.cellFromPixel(Pos.init(mouse.x, mouse.y));

        const position = config.position orelse imm.pos;

        const label_pos = position.moveX(2);

        const mouse_button_state = try imm.mouseInteraction(position, 1, 1, panel, mouse);

        bg_color.a = @intFromFloat(imm.alphas.get(name).?.alpha.value());

        bg_color.a /= 2;
        if (mouse_button_state.clicked) {
            state.* = !state.*;
        } else {
            bg_color.a /= 2;
        }

        try config.drawcmds.append(DrawCmd.textJustifyCmd(label, config.justify, label_pos, config.color, null, @intCast(label.len), 1.0));

        try config.drawcmds.append(DrawCmd.rect(position, 1, 1, 0.0, true, bg_color));
        try config.drawcmds.append(DrawCmd.rect(position, 1, 1, 0.0, false, fg_color));

        if (state.*) {
            const x: f32 = @as(f32, @floatFromInt(position.x)) + 0.23;
            const y: f32 = @as(f32, @floatFromInt(position.y)) - 0.4;
            try config.drawcmds.append(DrawCmd.textFloat("X", x, y, .left, config.color, 1.5));
        }

        if (config.position == null) {
            imm.pos = imm.pos.moveY(1);
        }

        return mouse_button_state.clicked;
    }

    pub fn text(imm: *Imm, label: []const u8, config: Config) !void {
        const position = config.position orelse imm.pos;
        try config.drawcmds.append(DrawCmd.textJustifyCmd(label, config.justify, position, config.color, null, @intCast(label.len), 1.0));
        if (config.position == null) {
            imm.pos = imm.pos.moveY(1);
        }
    }

    pub fn placard(imm: *Imm, header_text: []const u8, rect: Rect, config: Config) !void {
        _ = imm;

        const pos = rect.position();
        const bg_color = Color.init(27, 27, 25, 255);
        try config.drawcmds.append(DrawCmd.rectCmd(pos, rect.width, rect.height, 0.0, true, bg_color));
        try config.drawcmds.append(DrawCmd.rectCmd(pos, rect.width, rect.height, 0.5, false, config.color));
        try config.drawcmds.append(DrawCmd.textJustifyCmd(header_text, .center, pos, bg_color, config.color, rect.width, 1.0));
    }

    fn mouseInteraction(imm: *Imm, name: []const u8, position: Pos, width: i32, height: i32, panel: Panel, mouse: MouseState) !MouseButtonState {
        const pixel_pos = panel.pixelFromCell(position);
        const cell_dims = panel.cellDims();
        const pixel_width = cell_dims.width * width;
        const pixel_height = cell_dims.height * height;
        return try imm.mouseInteractionPixel(name, pixel_pos.x, pixel_pos.y, pixel_width, pixel_height, mouse);
    }

    fn mouseInteractionPixel(imm: *Imm, name: []const u8, pixel_x: i32, pixel_y: i32, width: i32, height: i32, mouse: MouseState) !MouseButtonState {
        if (!imm.alphas.contains(name)) {
            try imm.alphas.put(name, Alpha.init());
        }

        var mouse_button_state = MouseButtonState{};

        //const mouse_cell_pos = panel.cellFromPixel(Pos.init(mouse.x, mouse.y));
        mouse_button_state.mouseover = withinRect(pixel_x, pixel_y, width, height, Pos.init(mouse.x, mouse.y));

        if (mouse.left != null) {
            //const mouse_left_cell_pos = panel.cellFromPixel(Pos.init(mouse.left.?.pos.x, mouse.left.?.pos.y));
            const mouse_left_pos = Pos.init(mouse.left.?.pos.x, mouse.left.?.pos.y);
            const within_rect = withinRect(pixel_x, pixel_y, width, height, mouse_left_pos);
            if (within_rect) {
                mouse_button_state.clicked = true;
            }
        }

        if (mouse_button_state.mouseover) {
            imm.alphas.getPtr(name).?.reset();
        }

        return mouse_button_state;
    }

    pub fn skip(imm: *Imm) void {
        imm.pos = imm.pos.moveY(1);
    }
};

fn withinRect(x: i32, y: i32, w: i32, h: i32, pos: Pos) bool {
    const x_within = pos.x >= x and pos.x < (x + w);
    const y_within = pos.y >= y and pos.y < (y + h);
    const mouse_over = x_within and y_within;
    return mouse_over;
}
