const std = @import("std");
const print = std.debug.print;
const BoundedArray = std.BoundedArray;
const BitSetIteratorOptions = std.bit_set.IteratorOptions;
const Allocator = std.mem.Allocator;

const math = @import("math");
const Pos = math.pos.Pos;
const Direction = math.direction.Direction;

const movement = @import("movement.zig");
const MoveMode = movement.MoveMode;

const utils = @import("utils");
const comp = utils.comp;
const Id = comp.Id;
const Comp = comp.Comp;

pub const Entities = struct {
    pub const player_id = 0;

    ids: comp.Ids,
    pos: Comp(Pos),
    typ: Comp(Type),
    name: Comp(Name),
    turn: Comp(Turn),
    facing: Comp(Direction),
    status: Comp(StatusEffect),

    blocking: Comp(bool),

    move_mode: Comp(MoveMode),
    next_move_mode: Comp(MoveMode),

    pub fn init(allocator: Allocator) Entities {
        var entities: Entities = undefined;

        inline for (comptime compNames(Entities)) |field_name| {
            @field(entities, field_name) = @TypeOf(@field(entities, field_name)).init(allocator);
        }

        entities.ids = comp.Ids.initEmpty();
        return entities;
    }

    pub fn deinit(self: *Entities, allocator: Allocator) void {
        inline for (comptime compNames(Entities)) |field_name| {
            @field(self, field_name).deinit(allocator);
        }
    }

    pub fn clear(self: *Entities) void {
        inline for (comptime compNames(Entities)) |field_name| {
            @field(self, field_name).clear();
        }
        self.ids = comp.Ids.initEmpty();
    }

    pub fn clearExcept(self: *Entities, allocator: Allocator, ids: comp.Ids) void {
        inline for (comptime compNames(Entities)) |field_name| {
            @field(self, field_name).clearExcept(allocator, ids);
        }
        self.ids = ids;
    }

    pub fn addBasicComponents(self: *Entities, allocator: Allocator, id: Id, position: Pos, name: Name, typ: Type) !void {
        // Add fields that all entities share.
        try self.pos.insert(allocator, id, position);
        try self.typ.insert(allocator, id, typ);
        try self.name.insert(allocator, id, name);
        try self.status.insert(allocator, id, StatusEffect{});
        try self.blocking.insert(allocator, id, false);
        try self.turn.insert(allocator, id, Turn.init());
        // try self.state.insert(allocator, id, .spawn);
    }
};

// Entity names combine items and remaining entities.
pub const Name = blk: {
    // const numFields = @typeInfo(Item).@"enum".fields.len + @typeInfo(ExtraNames).@"enum".fields.len + @typeInfo(GolemName).@"enum".fields.len;
    const numFields = @typeInfo(ExtraNames).Enum.fields.len;
    var fields: [numFields]std.builtin.Type.EnumField = undefined;

    var index = 0;
    // for (std.meta.fields(Item)) |field| {
    //     fields[index] = std.builtin.Type.EnumField{ .name = field.name, .value = index };
    //     index += 1;
    // }

    for (std.meta.fields(ExtraNames)) |field| {
        fields[index] = std.builtin.Type.EnumField{ .name = field.name, .value = index };
        index += 1;
    }

    // for (std.meta.fields(GolemName)) |field| {
    //     fields[index] = std.builtin.Type.EnumField{ .name = field.name, .value = index };
    //     index += 1;
    // }

    const enumInfo = std.builtin.Type.Enum{
        .tag_type = u8,
        .fields = &fields,
        .decls = &[0]std.builtin.Type.Declaration{},
        .is_exhaustive = true,
    };

    break :blk @Type(std.builtin.Type{ .Enum = enumInfo });
};

pub const ExtraNames = enum {
    player,
};

pub const StatusEffect = struct {
    blinked: bool = false,
    active: bool = true,
    alive: bool = true,
    test_mode: bool = false,
};

pub const Turn = struct {
    pass: bool = false,
    walk: bool = false,
    run: bool = false,
    jump: bool = false,
    attack: bool = false,
    skill: bool = false,
    interactTrap: bool = false,
    blink: bool = false,

    pub fn init() Turn {
        return Turn{};
    }

    pub fn any(turn: Turn) bool {
        inline for (std.meta.fields(Turn)) |field| {
            if (@field(turn, field.name)) {
                return true;
            }
        }
        return false;
    }
};

pub const Type = enum {
    player,
    enemy,
};

pub fn compNames(comptime T: type) [][]const u8 {
    const fields = std.meta.fields(T);
    comptime var names: [fields.len - 1][]const u8 = undefined;
    comptime var index: usize = 0;
    while (index < names.len) : (index += 1) {
        names[index] = fields[index + 1].name;
    }

    return &names;
}
