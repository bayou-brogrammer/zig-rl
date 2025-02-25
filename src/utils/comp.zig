const std = @import("std");
const math = std.math;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const StaticBitSet = std.StaticBitSet;

pub const Id = u64;

pub const MAX_NUM_ENTITIES = 256;
pub const Ids = StaticBitSet(MAX_NUM_ENTITIES);
