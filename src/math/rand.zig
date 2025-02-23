const std = @import("std");
const Random = std.Random;

const Pos = @import("line").Pos;

pub fn rngBool(rng: Random) bool {
    return Random.boolean(rng);
}

pub fn rngTrial(rng: Random, prob: f32) bool {
    return Random.float(rng, f32) < prob;
}

pub fn rngRange(rng: Random, low: f32, high: f32) f32 {
    return (Random.float(rng, f32) * (high - low)) + low;
}

pub fn rngPos(rng: Random, bounds: Pos) Pos {
    const x = rngRangeI32(rng, 0, bounds.x);
    const y = rngRangeI32(rng, 0, bounds.y);
    return Pos.new(x, y);
}

pub fn rngRangeI32(rng: Random, low: i32, high: i32) i32 {
    if (low == high) {
        return low;
    } else {
        return Random.intRangeAtMost(rng, i32, low, high);
    }
}

pub fn rngRangeU32(rng: Random, low: u32, high: u32) u32 {
    if (low == high) {
        return low;
    } else {
        return Random.intRangeAtMost(rng, u32, low, high);
    }
}

pub fn rngRangeUsize(rng: Random, low: usize, high: usize) usize {
    if (low == high) {
        return low;
    } else {
        return Random.intRangeAtMost(rng, usize, low, high);
    }
}

pub fn choose(comptime T: type, rng: Random, items: []const T) ?T {
    if (items.len > 0) {
        return items[rngRangeUsize(rng, 0, items.len - 1)];
    } else {
        return null;
    }
}
