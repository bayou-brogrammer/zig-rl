const std = @import("std");
const assert = @import("std").debug.assert;

const math = @import("math");
const Pos = math.pos.Pos;
const Dims = math.dims.Dims;
const Rect = math.rect.Rect;

pub const Panel = struct {
    num_pixels: Dims,
    cells: Dims,

    pub fn init(num_pixels: Dims, cells: Dims) Panel {
        return Panel{
            .cells = cells,
            .num_pixels = num_pixels,
        };
    }

    pub fn subpanel(panel: *const Panel, subarea: Rect) Panel {
        assert(subarea.x_offset + subarea.width <= panel.cells.width);
        assert(subarea.y_offset + subarea.height <= panel.cells.height);

        const cell_dims = panel.cellDims();
        return Panel.init(cell_dims.scale(subarea.width, subarea.height), Dims.init(subarea.width, subarea.height));
    }

    pub fn cellDims(self: *const Panel) Dims {
        return Dims.init(@divFloor(self.num_pixels.width, self.cells.width), @divFloor(self.num_pixels.height, self.cells.height));
    }

    pub fn getRect(self: *const Panel) Rect {
        return Rect.init(@as(i32, @intCast(self.cells.width)), @as(i32, @intCast(self.cells.height)));
    }

    pub fn getPixelRect(self: *const Panel) Rect {
        return Rect.init(@as(i32, @intCast(self.num_pixels.width)), @as(i32, @intCast(self.num_pixels.height)));
    }

    pub fn cellFromPixel(self: *const Panel, pixel: Pos) Pos {
        const dims = self.cellDims();
        return Pos.init(@divFloor(pixel.x, @as(i32, @intCast(dims.width))), @divFloor(pixel.y, @as(i32, @intCast(dims.height))));
    }

    pub fn f32CellFromPixel(self: *const Panel, pixel: Pos) struct { x: f32, y: f32 } {
        const dims = self.cellDims();
        const x_offset = @as(f32, @floatFromInt(pixel.x)) / @as(f32, @floatFromInt(dims.width));
        const y_offset = @as(f32, @floatFromInt(pixel.y)) / @as(f32, @floatFromInt(dims.height));
        return .{ .x = x_offset, .y = y_offset };
    }

    pub fn pixelFromCell(self: *const Panel, cell: Pos) Pos {
        const dims = self.cellDims();
        return Pos.init(cell.x * @as(i32, @intCast(dims.width)), cell.y * @as(i32, @intCast(dims.height)));
    }

    pub fn getRectFull(self: *const Panel) Rect {
        return Rect{ .x_offset = 0, .y_offset = 0, .width = self.num_pixels.width, .height = self.num_pixels.height };
    }

    pub fn getRectUpLeft(self: *const Panel, width: usize, height: usize) Rect {
        assert(@as(u32, @intCast(width)) <= self.cells.width);
        assert(@as(u32, @intCast(height)) <= self.cells.height);

        const cell_dims = self.cellDims();

        const pixel_width = @as(i32, @intCast(width)) * cell_dims.width;
        const pixel_height = @as(i32, @intCast(height)) * cell_dims.height;

        return Rect{ .x_offset = 0, .y_offset = 0, .width = pixel_width, .height = pixel_height };
    }

    pub fn getRectFromArea(self: *const Panel, input_area: Rect) Rect {
        const cell_dims = self.cellDims();

        const x_offset = @as(f32, @floatFromInt(input_area.x_offset)) * @as(f32, @floatFromInt(cell_dims.width));
        const y_offset = @as(f32, @floatFromInt(input_area.y_offset)) * @as(f32, @floatFromInt(cell_dims.height));

        const width: i32 = @as(i32, @intFromFloat(@as(f32, @floatFromInt(input_area.width)) * @as(f32, @floatFromInt(cell_dims.width))));
        const height: i32 = @as(i32, @intFromFloat(@as(f32, @floatFromInt(input_area.height)) * @as(f32, @floatFromInt(cell_dims.height))));

        // don't draw off the screen
        assert(@as(i32, @intFromFloat(x_offset)) + width <= self.num_pixels.width);
        assert(@as(i32, @intFromFloat(y_offset)) + height <= self.num_pixels.height);

        return Rect{ .x_offset = @as(i32, @intFromFloat(x_offset)), .y_offset = @as(i32, @intFromFloat(y_offset)), .width = width, .height = height };
    }

    pub fn getRectWithin(self: *const Panel, input_area: Rect, target_dims: Dims) Rect {
        const base_rect = self.getRectFromArea(input_area);

        const scale_x = @as(f32, @floatFromInt(base_rect.width)) / @as(f32, @floatFromInt(target_dims.width));
        const scale_y = @as(f32, @floatFromInt(base_rect.height)) / @as(f32, @floatFromInt(target_dims.height));

        var scaler: f32 = undefined;
        if (scale_x * @as(f32, @floatFromInt(target_dims.height)) > @as(f32, @floatFromInt(base_rect.height))) {
            scaler = scale_y;
        } else {
            scaler = scale_x;
        }

        const final_target_width = @as(f32, @floatFromInt(target_dims.width)) * scaler;
        const final_target_height = @as(f32, @floatFromInt(target_dims.height)) * scaler;

        const x_inner_offset = (@as(f32, @floatFromInt(base_rect.width)) - final_target_width) / 2.0;
        const y_inner_offset = (@as(f32, @floatFromInt(base_rect.height)) - final_target_height) / 2.0;
        const x_offset = @as(f32, @floatFromInt(base_rect.x_offset)) + x_inner_offset;
        const y_offset = @as(f32, @floatFromInt(base_rect.y_offset)) + y_inner_offset;

        // check that we don't reach past the destination rect we should be drawing within
        assert((@as(f32, x_offset) + @as(f32, final_target_width)) <= @as(f32, @floatFromInt(base_rect.x_offset)) + @as(f32, @floatFromInt(base_rect.width)));
        assert((@as(f32, y_offset) + @as(f32, final_target_height)) <= @as(f32, @floatFromInt(base_rect.y_offset)) + @as(f32, @floatFromInt(base_rect.height)));

        return Rect.initAt(@as(i32, @intFromFloat(x_offset)), @as(i32, @intFromFloat(y_offset)), @as(i32, @intFromFloat(final_target_width)), @as(i32, @intFromFloat(final_target_height)));
    }
};
