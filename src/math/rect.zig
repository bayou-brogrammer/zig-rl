const std = @import("std");
const assert = @import("std").debug.assert;

const utils = @import("utils.zig");
const Pos = @import("pos.zig").Pos;
const Dims = utils.Dims;

pub const RectSplit = struct {
    first: Rect,
    second: Rect,

    pub fn init(first: Rect, second: Rect) RectSplit {
        return RectSplit{ .first = first, .second = second };
    }
};

pub const Rect = struct {
    x_offset: i32 = 0,
    y_offset: i32 = 0,
    width: i32,
    height: i32,

    pub fn init(width: i32, height: i32) Rect {
        return Rect{ .width = width, .height = height };
    }

    pub fn initAt(x_offset: i32, y_offset: i32, width: i32, height: i32) Rect {
        return Rect{ .x_offset = x_offset, .y_offset = y_offset, .width = width, .height = height };
    }

    pub fn position(area: Rect) Pos {
        return Pos.init(area.x_offset, area.y_offset);
    }

    pub fn bottomLeftCorner(area: Rect) Pos {
        return Pos.init(area.x_offset, area.y_offset + area.height);
    }

    pub fn dims(self: *const Rect) Dims {
        return Dims.init(self.width, self.height);
    }

    pub fn splitLeft(self: *const Rect, left_width: i32) RectSplit {
        assert(left_width <= self.width);

        const right_width = self.width - left_width;
        const left = Rect.initAt(self.x_offset, self.y_offset, left_width, self.height);
        const right = Rect.initAt(self.x_offset + left_width, self.y_offset, right_width, self.height);

        return RectSplit.init(left, right);
    }

    pub fn splitRight(self: *const Rect, right_width: i32) RectSplit {
        assert(right_width <= self.width);

        const left_width = self.width - right_width;
        const left = Rect.initAt(self.x_offset, self.y_offset, left_width, self.height);
        const right = Rect.initAt(self.x_offset + left_width, self.y_offset, right_width, self.height);

        return RectSplit.init(left, right);
    }

    pub fn splitTop(self: *const Rect, top_height: i32) RectSplit {
        assert(top_height <= self.height);

        const top = Rect.initAt(self.x_offset, self.y_offset, self.width, top_height);
        const bottom = Rect.initAt(self.x_offset, self.y_offset + top_height, self.width, self.height - top_height);

        return RectSplit.init(top, bottom);
    }

    pub fn splitBottom(self: *const Rect, bottom_height: i32) RectSplit {
        assert(bottom_height <= self.height);

        const top_height = self.height - bottom_height;
        const top = Rect.initAt(self.x_offset, self.y_offset, self.width, top_height);
        const bottom = Rect.initAt(self.x_offset, self.y_offset + top_height, self.width, bottom_height);

        return RectSplit.init(top, bottom);
    }

    pub fn centered(self: *const Rect, width: i32, height: i32) Rect {
        assert(width <= self.width);
        assert(height <= self.height);

        const x_offset = @divFloor((self.width - width), 2);
        const y_offset = @divFloor((self.height - height), 2);

        return Rect.initAt(x_offset, y_offset, width, height);
    }

    pub fn cellAtPixel(self: *const Rect, pixel_pos: Pos) ?Pos {
        const cell_pos = Pos.init(@as(i32, @intCast(pixel_pos.x / self.width)), @as(i32, @intCast(pixel_pos.y / self.height)));

        return self.cellAt(cell_pos);
    }

    pub fn cellAt(self: *const Rect, cell_pos: Pos) ?Pos {
        if (cell_pos.x >= self.x_offset and cell_pos.x < self.x_offset + self.width and
            cell_pos.y >= self.y_offset and cell_pos.y < self.y_offset + self.height)
        {
            return Pos.init(cell_pos.x - self.x_offset, cell_pos.y - self.y_offset);
        }

        return null;
    }

    pub fn fitWithin(target: Rect, source: Rect) Rect {
        const x_scale = @as(f32, @floatFromInt(target.width)) / @as(f32, @floatFromInt(source.width));
        const y_scale = @as(f32, @floatFromInt(target.height)) / @as(f32, @floatFromInt(source.height));
        const scale = @min(x_scale, y_scale);

        const width = @as(f32, @floatFromInt(source.width)) * scale;
        const height = @as(f32, @floatFromInt(source.height)) * scale;

        const x = target.x_offset + @as(i32, @intFromFloat((@as(f32, @floatFromInt(target.width)) - width) / 2.0));
        const y = target.y_offset + @as(i32, @intFromFloat((@as(f32, @floatFromInt(target.height)) - height) / 2.0));

        return Rect.initAt(x, y, @as(i32, @intFromFloat(width)), @as(i32, @intFromFloat(height)));
    }

    pub fn scaleCentered(rect: Rect, x_scale: f32, y_scale: f32) Rect {
        const new_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.width)) * x_scale));
        const new_height = @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.height)) * y_scale));
        return Rect.initAt(
            rect.x_offset - (new_width / 2),
            rect.y_offset - (new_height / 2),
            new_width,
            new_height,
        );
    }

    pub fn scaleXY(rect: Rect, x_scale: f32, y_scale: f32) Rect {
        return Rect.initAt(
            @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.x_offset)) * x_scale)),
            @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.y_offset)) * y_scale)),
            @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.width)) * x_scale)),
            @as(i32, @intFromFloat(@as(f32, @floatFromInt(rect.height)) * y_scale)),
        );
    }
};
