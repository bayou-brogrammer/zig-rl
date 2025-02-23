const std = @import("std");
const Allocator = std.mem.Allocator;

const tcl = @import("tcl.zig");

// This initialization came from std.heap.raw_c_allocator as an example.
pub var tcl_allocator = Allocator{
    .ptr = undefined,
    .vtable = &tcl_allocator_vtable,
};
const tcl_allocator_vtable = Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
};

fn alloc(_: *anyopaque, len: usize, ptr_align: u8, ra: usize) ?[*]u8 {
    _ = ra;

    const adjusted_len = len + ptr_align;
    const ptr = tcl.Tcl_AttemptAlloc(@as(c_uint, @intCast(adjusted_len)));
    if (ptr == null) {
        return null;
    } else {
        const adjusted_ptr_loc = std.mem.alignForward(usize, @intFromPtr(ptr), ptr_align);
        const adjusted_ptr = @as([*]u8, @ptrFromInt(adjusted_ptr_loc));

        return adjusted_ptr;
    }
}

fn resize(_: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ra: usize) bool {
    _ = buf_align;
    _ = ra;
    if (new_len > buf.len) {
        return false;
    }
    return true;
}

fn free(_: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    _ = buf_align;
    _ = ret_addr;
    tcl.Tcl_Free(buf.ptr);
}

test "tcl allocator" {
    const ptr = try tcl_allocator.create(u8);
    tcl_allocator.destroy(ptr);
}
