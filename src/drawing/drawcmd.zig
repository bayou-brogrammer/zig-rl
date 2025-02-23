const std = @import("std");

const math = @import("math");
const MoveDirection = math.direction.MoveDirection;
const Pos = math.pos.Pos;
const Color = math.utils.Color;

pub const Justify = enum {
    right,
    center,
    left,
};

pub const DrawText = struct { text: [128]u8 = [1]u8{0} ** 128, len: usize, color: Color, pos: Pos, scale: f32 };
pub const DrawTextFloat = struct { text: [128]u8 = [1]u8{0} ** 128, len: usize, justify: Justify, color: Color, x: f32, y: f32, scale: f32 };
pub const DrawTextJustify = struct { text: [128]u8 = [1]u8{0} ** 128, len: usize, justify: Justify, color: Color, bg_color: ?Color, pos: Pos, width: i32, scale: f32 };
pub const DrawRect = struct { pos: Pos, width: i32, height: i32, offset_percent: f32, filled: bool, color: Color };
pub const DrawRectFloat = struct { x: f32, y: f32, width: f32, height: f32, filled: bool, color: Color };
pub const DrawFill = struct { pos: Pos, color: Color };

pub const DrawCmd = union(enum) {
    text: DrawText,
    textFloat: DrawTextFloat,
    textJustify: DrawTextJustify,

    rect: DrawRect,
    rectFloat: DrawRectFloat,

    fill: DrawFill,

    pub fn aligned(self: *DrawCmd) bool {
        return self.* != .textFloat;
    }

    pub fn pos(self: DrawCmd) Pos {
        switch (self) {
            .text => |draw_cmd| return draw_cmd.pos,
            .textJustify => |draw_cmd| return draw_cmd.pos,
            .rect => |draw_cmd| return draw_cmd.pos,
            .fill => |draw_cmd| return draw_cmd.pos,
            .textFloat => |draw_cmd| return Pos.init(@as(i32, @intFromFloat(draw_cmd.x)), @as(i32, @intFromFloat(draw_cmd.y))),
            .rectFloat => |draw_cmd| return Pos.init(@as(i32, @intFromFloat(draw_cmd.x)), @as(i32, @intFromFloat(draw_cmd.y))),
        }
    }

    pub fn setColor(self: *DrawCmd, color: Color) void {
        switch (self.*) {
            .text => |*draw_cmd| @field(draw_cmd, "color") = color,
            .textJustify => |*draw_cmd| @field(draw_cmd, "color") = color,
            .rect => |*draw_cmd| @field(draw_cmd, "color") = color,
            .fill => |*draw_cmd| @field(draw_cmd, "color") = color,
            .textFloat => |*draw_cmd| @field(draw_cmd, "color") = color,
            .rectFloat => |*draw_cmd| @field(draw_cmd, "color") = color,
        }
    }

    pub fn textCmd(txt: []const u8, position: Pos, color: Color, scale: f32) DrawCmd {
        var text_cmd = DrawCmd{ .text = DrawText{ .len = txt.len, .pos = position, .color = color, .scale = scale } };
        std.mem.copyForwards(u8, text_cmd.text.text[0..txt.len], txt);
        return text_cmd;
    }

    pub fn textFloatCmd(txt: []const u8, x: f32, y: f32, justify: Justify, color: Color, scale: f32) DrawCmd {
        var text_cmd = DrawCmd{ .textFloat = DrawTextFloat{ .len = txt.len, .justify = justify, .color = color, .x = x, .y = y, .scale = scale } };
        std.mem.copyForwards(u8, text_cmd.textFloat.text[0..txt.len], txt);
        return text_cmd;
    }

    pub fn textJustifyCmd(txt: []const u8, justify: Justify, position: Pos, color: Color, bg_color: ?Color, width: i32, scale: f32) DrawCmd {
        var text_cmd = DrawCmd{ .textJustify = DrawTextJustify{ .len = txt.len, .justify = justify, .color = color, .bg_color = bg_color, .pos = position, .width = width, .scale = scale } };
        std.mem.copyForwards(u8, text_cmd.textJustify.text[0..txt.len], txt);
        return text_cmd;
    }

    pub fn rectCmd(position: Pos, width: i32, height: i32, offset_percent: f32, filled: bool, color: Color) DrawCmd {
        return DrawCmd{ .rect = DrawRect{ .pos = position, .width = width, .height = height, .offset_percent = offset_percent, .filled = filled, .color = color } };
    }

    pub fn rectFloatCmd(x: f32, y: f32, width: f32, height: f32, filled: bool, color: Color) DrawCmd {
        return DrawCmd{ .rectFloat = DrawRectFloat{ .x = x, .y = y, .width = width, .height = height, .filled = filled, .color = color } };
    }

    pub fn fillCmd(position: Pos, color: Color) DrawCmd {
        return DrawCmd{ .fill = DrawFill{ .pos = position, .color = color } };
    }
};
