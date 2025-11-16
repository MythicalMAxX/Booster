const std = @import("std");
const tui = @import("tui.zig");
const monitor = @import("monitor.zig");
const optimizer = @import("optimizer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try tui.TuiApp.init(allocator);
    defer app.deinit();

    try app.run();
}
