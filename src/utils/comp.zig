const std = @import("std");
const math = std.math;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const StaticBitSet = std.StaticBitSet;

pub const Id = u64;

pub const MAX_NUM_ENTITIES = 256;
pub const Ids = StaticBitSet(MAX_NUM_ENTITIES);

pub fn Comp(comptime T: type) type {
    return struct {
        ids: ArrayListUnmanaged(Id),
        store: ArrayListUnmanaged(T),

        const Self = @This();
        pub const Item = T;
        pub const has_deinit = (@typeInfo(T) == .Struct or @typeInfo(T) == .Union) and @hasDecl(T, "deinit");
        pub const deinit_no_allocator = has_deinit and @typeInfo(@TypeOf(@field(T, "deinit"))).Fn.params.len == 1;

        pub fn init(allocator: Allocator) Comp(T) {
            const ids = ArrayListUnmanaged(Id).initCapacity(allocator, 0) catch unreachable;
            const store = ArrayListUnmanaged(T).initCapacity(allocator, 0) catch unreachable;
            return Self{ .ids = ids, .store = store };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.ids.deinit(allocator);

            var index: usize = 0;
            while (index < self.store.items.len) : (index += 1) {
                Self.deinitItem(&self.store.items[index], allocator);
            }
            self.store.deinit(allocator);
        }

        pub fn deinitItem(item: *T, allocator: Allocator) void {
            if (Self.has_deinit) {
                if (deinit_no_allocator) {
                    item.deinit();
                } else {
                    item.deinit(allocator);
                }
            }
        }

        pub fn getPtr(self: *Self, id: Id) *T {
            return self.getPtrOrNull(id).?;
        }

        pub fn getPtrOrNull(self: *Self, id: Id) ?*T {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => |loc| return &self.store.items[loc],
                .not_found => return null,
            }
        }

        pub fn get(self: *const Self, id: Id) T {
            return self.getOrNull(id).?;
        }

        pub fn getOrNull(self: *const Self, id: Id) ?T {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => |loc| return self.store.items[loc],
                .not_found => return null,
            }
        }

        pub fn set(self: *Self, id: Id, t: T) void {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => |loc| self.store.items[loc] = t,
                .not_found => std.debug.panic("Set {} for entity id {} to {any}, which did not have this component!\n", .{ T, id, t }),
            }
        }

        pub fn has(self: *const Self, id: Id) bool {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => return true,
                .not_found => return false,
            }
        }

        pub fn insert(self: *Self, allocator: Allocator, id: Id, data: T) !void {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => |loc| {
                    self.store.items[loc] = data;
                },

                .not_found => |loc| {
                    try self.ids.insert(allocator, loc, id);
                    try self.store.insert(allocator, loc, data);
                },
            }
        }

        pub fn lookup(self: *const Self, id: Id) ?usize {
            switch (binarySearchKeys(id, self.ids.items)) {
                .found => |loc| return loc,
                .not_found => return null,
            }
        }

        pub fn clear(self: *Self) void {
            self.ids.clearRetainingCapacity();
            self.store.clearRetainingCapacity();
        }

        pub fn clearExcept(self: *Self, allocator: Allocator, ids: Ids) void {
            var index: usize = 0;
            var id_iter = ids.iterator(.{});
            while (id_iter.next()) |id| {
                if (self.lookup(id)) |comp_id| {
                    if (id != index) {
                        // If we are overwritting an existing component, deinit it first.
                        if (Self.has_deinit) {
                            Self.deinitItem(&self.store.items[index], allocator);
                        }

                        // Move the component to its new location.
                        self.store.items[index] = self.store.items[comp_id];
                    }
                    index += 1;
                }
            }

            // Deinit remaining components.
            const new_size = index;
            while (index < self.store.items.len) : (index += 1) {
                Self.deinitItem(&self.store.items[index], allocator);
            }

            // Set new storage length.
            self.store.items.len = new_size;

            var keep_ids = Ids.initEmpty();
            for (self.ids.items) |id| {
                if (ids.isSet(id)) {
                    keep_ids.set(id);
                }
            }

            // Clear id array and add back in only used ids.
            self.ids.clearRetainingCapacity();
            id_iter = keep_ids.iterator(.{});
            while (id_iter.next()) |id| {
                // The capacity should be enough to hold all ids, so this should never result in an error.
                self.ids.append(allocator, id) catch unreachable;
            }
        }
    };
}

const SearchResult = union(enum) {
    found: usize,
    not_found: usize,
};

pub fn binarySearchKeys(key: Id, items: []const Id) SearchResult {
    var left: usize = 0;
    var right: usize = items.len;

    while (left < right) {
        // Avoid overflowing in the midpoint calculation
        const mid = left + (right - left) / 2;
        // Compare the key with the midpoint element
        switch (math.order(key, items[mid])) {
            .eq => return SearchResult{ .found = mid },
            .gt => left = mid + 1,
            .lt => right = mid,
        }
    }

    return SearchResult{ .not_found = left };
}
