const std = @import("std");
const BoundedArray = std.BoundedArray;

pub const ConfigStr = BoundedArray(u8, 64);

pub const Config = packed struct {
    frame_rate: usize,
    reload_config_period: u64,

    pub fn fromFile(file_name: []const u8) !Config {
        return fromFileGeneric(Config, file_name);
    }
};

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

const WordIter = std.mem.SplitIterator(u8, .scalar);

fn parseInt(comptime IntType: type, str: []const u8) !IntType {
    if (str.len > 2 and str[0] == '0' and str[1] == 'x') {
        return try std.fmt.parseInt(IntType, str[2..], 16);
    } else {
        return try std.fmt.parseInt(IntType, str, 10);
    }
}

pub fn readFromLine(comptime T: type, line: []const u8) !?T {
    var iter = std.mem.splitScalar(u8, line, ' ');
    return readFromLineHelper(T, &iter);
}

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
