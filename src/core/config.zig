const std = @import("std");
const math = @import("math");
const Color = math.utils.Color;
const Easing = math.easing.Easing;
const BoundedArray = std.BoundedArray;

pub const ConfigStr = BoundedArray(u8, 64);

pub const Config = packed struct {
    reload_config_period: u64,
    tile_noise_scaler: f64,
    highlight_player_move: u8,
    highlight_alpha_attack: u8,
    sound_alpha: u8,
    grid_alpha: u8,
    grid_alpha_visible: u8,
    grid_alpha_overlay: u8,
    idle_speed: f32,
    vault_speed: f32,
    vault_duration: f32,
    grass_idle_speed: f32,
    frame_rate: usize,
    item_throw_speed: f32,
    key_speed: f32,
    player_attack_speed: f32,
    player_attack_hammer_speed: f32,
    player_vault_sprite_speed: f32,
    player_vault_move_speed: f32,
    sound_timeout: f32,
    yell_radius: usize,
    swap_radius: usize,
    ping_sound_radius: usize,
    seed_cache_radius: usize,
    smoke_bomb_radius: usize,
    blink_radius: usize,
    fog_of_war: bool,
    player_health: i32,
    golem_health: i32,
    player_health_max: i32,
    player_stamina: u32,
    player_stamina_max: u32,
    player_energy: u32,
    player_energy_max: u32,
    player_throw_dist: usize,
    player_sling_dist: usize,
    explored_alpha: u8,
    fov_edge_alpha: u8,
    sound_rubble_radius: usize,
    sound_golem_idle_radius: usize,
    sound_grass_radius: usize,
    sound_radius_crushed: usize,
    sound_radius_attack: usize,
    sound_radius_trap: usize,
    sound_radius_monster: usize,
    sound_radius_stone: usize,
    sound_radius_player: usize,
    sound_radius_hammer: usize,
    sound_radius_blunt: usize,
    sound_radius_pierce: usize,
    sound_radius_slash: usize,
    sound_radius_extra: usize,
    sound_radius_explosion: usize,
    freeze_trap_radius: usize,
    freeze_trap_num_turns: usize,
    push_stun_turns: usize,
    stun_turns_blunt: usize,
    stun_turns_pierce: usize,
    stun_turns_slash: usize,
    stun_turns_extra: usize,
    stun_turns_throw_stone: usize,
    stun_turns_throw_spear: usize,
    stun_turns_throw_default: usize,
    stun_turns_push_against_wall: usize,
    overlay_directions: bool,
    overlay_player_fov: bool,
    overlay_floodfill: bool,
    fov_radius_golem: i32,
    fov_radius_player: i32,
    sound_radius_sneak: usize,
    sound_radius_walk: usize,
    sound_radius_run: usize,
    dampen_blocked_tile: i32,
    dampen_short_wall: i32,
    dampen_tall_wall: i32,
    repeat_delay: f32,
    write_map_distribution: bool,
    print_key_log: bool,
    fire_speed: f32,
    armil_explode_speed: f32,
    beam_duration: usize,
    draw_directional_arrow: bool,
    ghost_alpha: u8,
    particles_enabled: bool,
    particle_duration_min: f32,
    particle_duration_max: f32,
    particle_prob: f32,
    particle_max_length: i32,
    attack_animation_speed: f32,
    cursor_fast_move_dist: i32,
    cursor_fade_seconds: f32,
    cursor_move_seconds: f32,
    cursor_alpha: u8,
    cursor_line: bool,
    cursor_easing: Easing,
    sidebar_alpha: u8,
    sidebar_percent_of_screen: f32,
    sidebar_speed: f32,
    impression_alpha: u8,
    save_load: bool,
    minimal_output: bool,
    blocking_positions: bool,
    smoke_bomb_fov_block: usize,
    sound_ease_in: Easing,
    sound_ease_out: Easing,
    smoke_turns: usize,
    looking_glass_magnify_amount: usize,
    hp_render_duration: usize,
    render_impression_facing: bool,
    render_impression_sprites: bool,
    move_tiles_sneak: usize,
    move_tiles_walk: usize,
    move_tiles_run: usize,
    x_offset_buttons: f32,
    y_offset_buttons: f32,
    x_spacing_buttons: f32,
    y_spacing_buttons: f32,
    x_scale_buttons: f32,
    y_scale_buttons: f32,
    ui_inv_name_x_offset: f32,
    ui_inv_name_y_offset: f32,
    ui_inv_name_scale: f32,
    ui_inv_name_second_x_offset: f32,
    ui_inv_name_second_y_offset: f32,
    ui_button_char_x_offset: f32,
    ui_button_char_y_offset: f32,
    ui_button_char_scale: f32,

    ui_long_name_scale: f32,

    ui_help_text_scale: f32,

    stunned_overlay_scale: f32,
    stunned_overlay_offset: f32,

    display_console_lines: usize,

    display_center_map_on_player: bool,

    use_profiling: bool,

    map_window_edge: i32,
    map_window_x: i32,
    map_window_y: i32,

    gol_move_distance: usize,
    gol_attack_distance: usize,
    spire_move_distance: usize,
    spire_attack_distance: usize,
    pawn_move_distance: usize,
    pawn_attack_distance: usize,
    rook_move_distance: usize,
    rook_attack_distance: usize,
    armil_move_distance: usize,

    armil_turns_armed: usize,
    armil_explosion_radius: usize,

    lantern_illuminate_radius: i32,
    skill_grass_shoes_turns: usize,
    skill_grass_throw_radius: i32,
    skill_illuminate_radius: usize,
    skill_heal_amount: usize,
    skill_farsight_fov_amount: usize,
    skill_push_stun_turns: usize,
    skill_sprint_amount: usize,
    skill_roll_amount: usize,
    skill_stone_skin_turns: usize,
    skill_swift_distance: usize,
    skill_quick_reflexes_percent: f32,

    color_dark_brown: Color,
    color_medium_brown: Color,
    color_light_green: Color,
    color_tile_blue_light: Color,
    color_tile_blue_dark: Color,
    color_light_brown: Color,
    color_ice_blue: Color,
    color_dark_blue: Color,
    color_very_dark_blue: Color,
    color_orange: Color,
    color_red: Color,
    color_light_red: Color,
    color_medium_grey: Color,
    color_mint_green: Color,
    color_blueish_grey: Color,
    color_pink: Color,
    color_rose_red: Color,
    color_light_orange: Color,
    color_bone_white: Color,
    color_warm_grey: Color,
    color_soft_green: Color,
    color_light_grey: Color,
    color_shadow: Color,

    recording_enabled: bool,

    pub fn fromFile(file_name: []const u8) !Config {
        return fromFileGeneric(Config, file_name);
    }
};

fn parseInt(comptime IntType: type, str: []const u8) !IntType {
    if (str.len > 2 and str[0] == '0' and str[1] == 'x') {
        return try std.fmt.parseInt(IntType, str[2..], 16);
    } else {
        return try std.fmt.parseInt(IntType, str, 10);
    }
}

pub const ParseConfigError = error{
    NameFormatError,
    ValueFormatError,
    ParseBoolError,
    ParseColorError,
    ParseEnumError,
    MissingFieldError,
};

pub fn fromFileGeneric(comptime T: type, file_name: []const u8) !T {
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var value: T = undefined;
    var filled_fields = [_]bool{false} ** std.meta.fields(T).len;

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0 or line[0] == '#') {
            continue;
        }

        var parts = std.mem.splitSequence(u8, line, ": ");

        const field_name = parts.next() orelse return ParseConfigError.NameFormatError;
        const field_value = parts.next() orelse return ParseConfigError.ValueFormatError;

        inline for (std.meta.fields(T), 0..) |field, index| {
            if (std.mem.eql(u8, field_name, field.name)) {
                const parsed_value = try readFromLine(field.type, field_value);
                @field(value, field.name) = parsed_value.?;
                filled_fields[index] = true;
                break;
            }
        }
    }

    inline for (std.meta.fields(T), 0..) |field, index| {
        if (!filled_fields[index]) {
            std.debug.print("Missing field when reading {any}: {s}\n", .{ T, field.name });
            return ParseConfigError.MissingFieldError;
        }
    }

    return value;
}

pub fn fromFileArrayList(comptime T: type, file_name: []const u8, list: *std.ArrayList(T)) !void {
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var text: [1024 * 5]u8 = undefined;
    const bytes_read = try file.read(&text);

    list.clearRetainingCapacity();

    var iter = std.mem.splitScalar(u8, text[0..bytes_read], '\n');
    while (iter.next()) |line| {
        // Skip lines starting with comments.
        if (line.len == 0 or line[0] == '#') {
            continue;
        }

        if (try readFromLine(T, line)) |parsed_value| {
            try list.append(parsed_value);
        }
    }
}

pub fn fromFileArrayListWithPrefix(T: type, allocator: std.mem.Allocator, comptime prefix: []const u8, file_name: []const u8) !std.ArrayList(T) {
    var cmds = std.ArrayList(T).init(allocator);
    var rel_path_buffer: [128]u8 = undefined;
    const rel_path = try std.fmt.bufPrint(&rel_path_buffer, prefix ++ "/{s}", .{file_name});
    try fromFileArrayList(T, rel_path, &cmds);
    return cmds;
}

pub fn readFromLine(comptime T: type, line: []const u8) !?T {
    var iter = std.mem.splitScalar(u8, line, ' ');
    return readFromLineHelper(T, &iter);
}

const WordIter = std.mem.SplitIterator(u8, .scalar);

pub fn readFromLineHelper(comptime T: type, iter: *WordIter) !?T {
    if (T == ConfigStr) {
        var str: ConfigStr = ConfigStr.init(0) catch unreachable;
        if (iter.next()) |word| {
            try str.appendSlice(word);
        }
        return str;
    }

    switch (@typeInfo(T)) {
        .Struct => {
            var value: T = undefined;
            const fields = std.meta.fields(T);
            inline for (fields) |field| {
                const parsed_value = try readFromLineHelper(field.type, iter);
                @field(value, field.name) = parsed_value.?;
            }
            return value;
        },

        .Optional => {
            if (iter.peek()) |next_word| {
                if (std.mem.eql(u8, "null", next_word)) {
                    _ = iter.next();
                    const ret_val: ?std.meta.Child(T) = null;
                    return ret_val;
                } else {
                    return try readFromLineHelper(std.meta.Child(T), iter);
                }
            } else {
                return null;
            }
        },

        .Enum => |e| {
            while (iter.next()) |word| {
                if (word.len > 0) {
                    inline for (e.fields) |field| {
                        if (std.mem.eql(u8, field.name, word)) {
                            return @enumFromInt(field.value);
                        }
                    }
                }
            }
            unreachable;
        },

        .Int => {
            while (iter.next()) |word| {
                if (word.len == 0) {
                    continue;
                }
                return try parseInt(T, word);
            }
        },

        .Float => {
            while (iter.next()) |word| {
                if (word.len == 0) {
                    continue;
                }
                return try std.fmt.parseFloat(T, word);
            }
        },

        .Union => |u| {
            if (u.tag_type != null) {
                while (iter.next()) |name| {
                    if (name.len == 0) {
                        continue;
                    }
                    inline for (u.fields) |field| {
                        if (std.mem.eql(u8, field.name, name)) {
                            if (field.type == void) {
                                return @unionInit(T, field.name, {});
                            } else {
                                const value = try readFromLineHelper(field.type, iter);
                                return @unionInit(T, field.name, value.?);
                            }
                        }
                    }
                    std.debug.panic("Field with tag {s} not found in {any}", .{ name, T });
                }
            } else {
                std.debug.panic("Untagged union {any} not supported!", .{T});
            }
        },

        .Bool => {
            while (iter.next()) |word| {
                if (word.len == 0) {
                    continue;
                }
                if (std.mem.eql(u8, word, "true")) {
                    return true;
                } else if (std.mem.eql(u8, word, "false")) {
                    return false;
                }
            }
        },

        .Void => {},

        .Array => |a| {
            var array: T = undefined;
            for (0..a.len) |index| {
                array[index] = try readFromLineHelper(a.child, iter) orelse 0;
            }
            return array;
        },

        else => {
            std.debug.panic("Unsupported type {any}!", .{T});
        },
    }
    return null;
}

test "simple config" {
    try std.testing.expect(try readFromLine(i32, "10") == 10);
    try std.testing.expect(try readFromLine(i32, " 10 ") == 10);
    try std.testing.expect(try readFromLine(f32, "1.0") == 1.0);
}

test "enum config" {
    const E = enum { A, B };
    try std.testing.expect(try readFromLine(E, "A") == .A);
    try std.testing.expect(try readFromLine(E, " B ") == .B);
}

test "struct config" {
    const S = struct { a: u8, b: i32 };
    try std.testing.expect(std.meta.eql(try readFromLine(S, "1 22"), S{ .a = 1, .b = 22 }));
}

test "union config" {
    const U = union(enum) { a: u8, b: i32 };
    try std.testing.expect(std.meta.eql(try readFromLine(U, "a 12"), U{ .a = 12 }));
    try std.testing.expect(std.meta.eql(try readFromLine(U, "b 21"), U{ .b = 21 }));
}
