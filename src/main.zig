const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Allocator = std.mem.Allocator;
const DynamicBitSetUnmanaged = std.DynamicBitSetUnmanaged;

const d = @import("display");
const Gui = d.gui.Gui;
const sdl3 = d.gui.sdl3;

const logging = @import("logging.zig");

pub const std_options: std.Options = .{
    .logFn = logging.logFn,
    .log_level = .info,
};

const usage_text =
    \\Usage: rustl [options]
    \\
    \\Run the RustRL game
    \\
    \\Options:
    \\ -s, --seed <seed>    (default: 0) random number generator seed value
    \\ --map <mapconfig>    load a map configuration file.
    \\ --continueGame       continue from saved game without showing menus
    \\ --empty              start up an empty map
    \\
;

pub const Args = struct {
    seed: u64 = 0,
    // map_config: ?MapConfig = null,
    continue_game: bool = false,
    empty: bool = false,
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) @panic("found memory leaks");
    // const allocator = gpa.allocator();

    logging.setup();
    std.log.info("starting game", .{});

    const args = try parseArgs(allocator);

    var gui = try initGui(args, allocator);
    defer gui.deinit();

    try runGui(&gui);

    print("exiting\n", .{});

    std.process.cleanExit();
}

fn runGui(gui: *Gui) !void {
    print("Gui.runGui() starting\n", .{});
    var ticks = sdl3.SDL_GetTicks();

    while (try gui.step(ticks)) {
        // NOTE this is pretty primitive. Consider a better frame limiter.
        std.time.sleep(1000000000 / gui.game.config.frame_rate);
        ticks = sdl3.SDL_GetTicks();
    }

    print("Gui.runGui() exiting\n", .{});
}

fn initGui(args: Args, allocator: Allocator) !Gui {
    var gui = try Gui.init(args.seed, allocator);
    try gui.resolveMessages();

    return gui;
}

fn parseArgs(allocator: Allocator) !Args {
    var cmd_args = Args{};

    // Parse command line arguments.
    const args = try std.process.argsAlloc(allocator);
    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        const arg = args[arg_i];
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            std.debug.print("{s}\n", .{usage_text});
            std.process.exit(1);
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--seed")) {
            arg_i += 1;
            if (arg_i >= args.len) {
                std.debug.print("'{s}' requires an additional argument.\n{s}", .{ arg, usage_text });
                std.process.exit(1);
            }
            cmd_args.seed = std.fmt.parseInt(u64, args[arg_i], 10) catch |err| {
                std.debug.print("unable to parse --seed argument '{s}': {s}\n", .{
                    args[arg_i], @errorName(err),
                });
                std.process.exit(1);
            };
        }
        // else if (std.mem.eql(u8, arg, "--procgen")) {
        //     arg_i += 1;
        //     var procgen_file = core.config.ConfigStr.init(0) catch unreachable;
        //     try procgen_file.appendSlice(args[arg_i]);
        //     cmd_args.map_config = MapConfig{ .map_type = .{ .procgen = procgen_file } };
        // }
        // else if (std.mem.eql(u8, arg, "--map")) {
        //     arg_i += 1;
        //     var map_file = core.config.ConfigStr.init(0) catch unreachable;
        //     try map_file.appendSlice(args[arg_i]);
        //     cmd_args.map_config = MapConfig{ .map_type = .{ .layout = map_file } };
        // }
        else if (std.mem.eql(u8, arg, "--continue")) {
            cmd_args.continue_game = true;
        } else if (std.mem.eql(u8, arg, "--empty")) {
            cmd_args.empty = true;
        }
    }

    return cmd_args;
}
