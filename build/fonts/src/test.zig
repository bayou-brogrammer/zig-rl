// SPDX-FileCopyrightText: © 2024 Mark Delk <jethrodaniel@gmail.com>
//
// SPDX-License-Identifier: Zlib

const std = @import("std");
const fonts = @import("fonts");

test "build options" {
    const regular = @import("fonts").intel_one_mono_regular;
    try std.testing.expectEqual(regular.len, 65468);

    const bold = @import("fonts").intel_one_mono_bold;
    try std.testing.expectEqual(bold.len, 65156);
}
