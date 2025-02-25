const std = @import("std");
const Allocator = std.mem.Allocator;

const math = @import("math");
const Rect = math.rect.Rect;
const Dims = math.dims.Dims;

const display = @import("display.zig");
pub const Display = display.Display;
const TexturePanel = display.TexturePanel;

const drawing = @import("drawing");
const Panel = drawing.panel.Panel;

pub const MAX_MAP_WIDTH: i32 = 80;
pub const MAX_MAP_HEIGHT: i32 = 80;
pub const MAP_MAX_TILES = MAX_MAP_WIDTH * MAX_MAP_HEIGHT;

pub const UI_CELLS_PIPS: i32 = 2;
pub const UI_CELLS_BOTTOM: i32 = 11;

pub const MAP_AREA_CELLS_WIDTH: i32 = 44;
pub const MAP_AREA_CELLS_HEIGHT: i32 = 20;

pub const SCREEN_CELLS_WIDTH: i32 = MAP_AREA_CELLS_WIDTH;
pub const SCREEN_CELLS_HEIGHT: i32 = MAP_AREA_CELLS_HEIGHT + UI_CELLS_PIPS + UI_CELLS_BOTTOM;

pub const Panels = struct {
    screen: TexturePanel,

    level: TexturePanel,
    level_area: Rect,

    pub fn init(width: i32, height: i32, disp: *Display, allocator: Allocator) !Panels {
        // Set up screen and its area.
        const screen_num_pixels = Dims.init(width, height);
        const screen_dims = Dims.init(SCREEN_CELLS_WIDTH, SCREEN_CELLS_HEIGHT);
        const screen_panel = Panel.init(screen_num_pixels, screen_dims);

        // Lay out panels within the screen.
        const screen_area = Rect.init(screen_dims.width, screen_dims.height);
        const top_bottom_split = screen_area.splitBottom(@as(i32, @intCast(UI_CELLS_BOTTOM)));

        const pip_map_area = top_bottom_split.first.splitBottom(@as(i32, @intCast(UI_CELLS_PIPS)));
        const map_area = pip_map_area.first;

        // Create all texture panels and misc panels.
        const screen_texture_panel = try disp.texturePanel(screen_panel, allocator);

        // Create the map panel.
        const level_num_pixels = Dims.init(MAX_MAP_WIDTH * 24, MAX_MAP_HEIGHT * 24);
        // const level_num_pixels = Dims.init(MAX_MAP_WIDTH * sprite.FONT_WIDTH, MAX_MAP_HEIGHT * sprite.FONT_HEIGHT);
        const level_panel = Panel.init(level_num_pixels, Dims.init(MAX_MAP_WIDTH, MAX_MAP_HEIGHT));
        const level_texture_panel = try disp.texturePanel(level_panel, allocator);

        return Panels{
            .screen = screen_texture_panel,

            .level = level_texture_panel,
            .level_area = map_area,
        };
    }

    pub fn deinit(panels: *Panels) void {
        panels.screen.deinit();
    }
};
