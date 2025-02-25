const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const core = @import("core");
const MoveType = core.movement.MoveType;
const MoveMode = core.movement.MoveMode;
const Name = core.entities.Name;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;

const utils = @import("utils");
const Id = utils.comp.Id;

pub const MsgType = std.meta.Tag(Msg);

pub const Msg = union(enum) {
    cursorStart: Pos,
    cursorMove: Pos,
    cursorEnd,

    newLevel: void,
    startLevel: void,

    tryMove: struct { id: Id, dir: Direction, amount: usize },
    move: struct { id: Id, move_type: MoveType, move_mode: MoveMode, pos: Pos },
    facing: struct { id: Id, facing: Direction },
    spawn: struct { id: Id, name: Name },

    pub fn genericMsg(comptime msg_type: MsgType, args: anytype) Msg {
        const fields = std.meta.fields(Msg);

        const field_type = fields[@intFromEnum(msg_type)].type;
        const field_type_info = @typeInfo(field_type);

        var value: field_type = undefined;

        const arg_type_info = @typeInfo(@TypeOf(args));
        // NOTE(zig) std.meta.trait.isTuple returns false here for some reason.
        if (arg_type_info == .Struct and arg_type_info.Struct.is_tuple) {
            comptime var index = 0;
            inline while (index < args.len) {
                @field(value, field_type_info.Struct.fields[index].name) = args[index];
                index += 1;
            }
        } else {
            value = args;
        }

        return @unionInit(Msg, @tagName(msg_type), value);
    }
};

pub const MsgLog = struct {
    remaining: ArrayListUnmanaged(Msg),
    instant: ArrayListUnmanaged(Msg),
    all: ArrayListUnmanaged(Msg),
    allocator: Allocator,

    pub fn init(allocator: Allocator) !MsgLog {
        return MsgLog{
            .remaining = try ArrayListUnmanaged(Msg).initCapacity(allocator, 128),
            .instant = try ArrayListUnmanaged(Msg).initCapacity(allocator, 128),
            .all = try ArrayListUnmanaged(Msg).initCapacity(allocator, 128),
            .allocator = allocator,
        };
    }

    pub fn deinit(msg_log: *MsgLog) void {
        msg_log.remaining.deinit(msg_log.allocator);
        msg_log.instant.deinit(msg_log.allocator);
        msg_log.all.deinit(msg_log.allocator);
    }

    pub fn clear(msg_log: *MsgLog) void {
        msg_log.remaining.clearRetainingCapacity();
        msg_log.instant.clearRetainingCapacity();
        msg_log.all.clearRetainingCapacity();
    }

    pub fn pop(msg_log: *MsgLog) !?Msg {
        // First attempt to get a message from the 'instant' log to empty it first.
        // Then attempt to get from the main log, remaining.
        // If a message is retrieved, log it in 'all' as the final ordering of message
        // processing.
        var msg: ?Msg = undefined;

        // NOTE(performance) this ordered remove is O(n). A dequeue would be better.
        if (msg_log.instant.items.len > 0) {
            msg = msg_log.instant.orderedRemove(0);
        } else if (msg_log.remaining.items.len > 0) {
            msg = msg_log.remaining.orderedRemove(0);
        } else {
            msg = null;
        }

        if (msg) |valid_msg| {
            try msg_log.all.append(msg_log.allocator, valid_msg);
        }
        return msg;
    }

    pub fn log(msg_log: *MsgLog, comptime msg_type: MsgType, args: anytype) !void {
        try msg_log.remaining.append(msg_log.allocator, Msg.genericMsg(msg_type, args));
    }

    pub fn now(msg_log: *MsgLog, comptime msg_type: MsgType, args: anytype) !void {
        try msg_log.instant.append(msg_log.allocator, Msg.genericMsg(msg_type, args));
    }
};
