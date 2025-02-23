const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const math = @import("math");
const Pos = math.pos.Pos;

pub const MsgType = std.meta.Tag(Msg);

pub const Msg = union(enum) {
    cursorStart: Pos,
    cursorMove: Pos,
    cursorEnd,
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
};
