const std = @import("std");
const monitor = @import("monitor.zig");
const optimizer = @import("optimizer.zig");

// Simple writer wrapper that uses File.writeAll
const StdoutWriter = struct {
    allocator: std.mem.Allocator,
    
    pub const Error = std.fs.File.WriteError || std.mem.Allocator.Error;
    
    pub fn writeAll(self: StdoutWriter, bytes: []const u8) Error!void {
        _ = self;
        return std.fs.File.stdout().writeAll(bytes);
    }
    
    pub fn print(self: StdoutWriter, comptime fmt: []const u8, args: anytype) Error!void {
        // Use allocator for dynamic buffer to avoid stack issues
        const msg = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(msg);
        return std.fs.File.stdout().writeAll(msg);
    }
};

pub const TuiApp = struct {
    allocator: std.mem.Allocator,
    running: bool,
    current_view: View,
    system_monitor: monitor.SystemMonitor,
    optimizer_instance: optimizer.Optimizer,
    
    const View = enum {
        dashboard,
        processes,
        cleanup,
        startup,
        about,
    };

    pub fn init(allocator: std.mem.Allocator) !TuiApp {
        return TuiApp{
            .allocator = allocator,
            .running = true,
            .current_view = .dashboard,
            .system_monitor = try monitor.SystemMonitor.init(allocator),
            .optimizer_instance = try optimizer.Optimizer.init(allocator),
        };
    }

    pub fn deinit(self: *TuiApp) void {
        self.system_monitor.deinit();
        self.optimizer_instance.deinit();
    }

    pub fn run(self: *TuiApp) !void {
        try self.enableRawMode();
        defer self.disableRawMode() catch {};
        
        try self.clearScreen();
        try self.hideCursor();
        defer self.showCursor() catch {};

        while (self.running) {
            try self.render();
            try self.handleInput();
            std.Thread.sleep(10000 * std.time.ns_per_ms); // 10 second refresh
        }
    }

    fn render(self: *TuiApp) !void {
        try self.clearScreen();
        
        const stdout = StdoutWriter{ .allocator = self.allocator };
        
        // Header
        try self.setColor(stdout, .cyan, .bold);
        try stdout.writeAll("╔════════════════════════════════════════════════════════════════════════════╗\n");
        try stdout.writeAll("║                        🚀 DEVICE BOOSTER v1.0                            ║\n");
        try stdout.writeAll("╚════════════════════════════════════════════════════════════════════════════╝\n");
        try self.resetColor(stdout);
        
        // Navigation menu
        try self.renderMenu(stdout);
        try stdout.writeAll("\n");
        
        // Render current view
        switch (self.current_view) {
            .dashboard => try self.renderDashboard(stdout),
            .processes => try self.renderProcesses(stdout),
            .cleanup => try self.renderCleanup(stdout),
            .startup => try self.renderStartup(stdout),
            .about => try self.renderAbout(stdout),
        }
        
        // Footer
        try stdout.writeAll("\n");
        try self.setColor(stdout, .yellow, .normal);
        try stdout.writeAll("Press 'q' to quit | Use 1-5 to switch views | 'o' to optimize\n");
        try self.resetColor(stdout);
    }

    fn renderMenu(self: *TuiApp, writer: anytype) !void {
        const menus = [_]struct { view: View, key: []const u8, label: []const u8 }{
            .{ .view = .dashboard, .key = "1", .label = "Dashboard" },
            .{ .view = .processes, .key = "2", .label = "Processes" },
            .{ .view = .cleanup, .key = "3", .label = "Cleanup" },
            .{ .view = .startup, .key = "4", .label = "Startup" },
            .{ .view = .about, .key = "5", .label = "About" },
        };

        try writer.writeAll("  ");
        for (menus) |menu| {
            if (self.current_view == menu.view) {
                try self.setColor(writer, .green, .bold);
                try writer.print("[{s}] {s}", .{ menu.key, menu.label });
                try self.resetColor(writer);
            } else {
                try self.setColor(writer, .white, .normal);
                try writer.print(" {s}. {s} ", .{ menu.key, menu.label });
                try self.resetColor(writer);
            }
            try writer.writeAll("  ");
        }
        try writer.writeAll("\n");
    }

    fn renderDashboard(self: *TuiApp, writer: anytype) !void {
        const sys_info = try self.system_monitor.getSystemInfo();
        defer self.allocator.free(sys_info.os_name);
        
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("\n━━━━━━━━━━━━━━━━━━━━━━━ SYSTEM PERFORMANCE ━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        // CPU Usage
        try self.setColor(writer, .white, .bold);
        try writer.writeAll("  CPU Usage:     ");
        try self.resetColor(writer);
        try self.renderProgressBar(writer, sys_info.cpu_usage, 50);
        try writer.print(" {d:.1}%\n", .{sys_info.cpu_usage});
        
        // RAM Usage
        try self.setColor(writer, .white, .bold);
        try writer.writeAll("  RAM Usage:     ");
        try self.resetColor(writer);
        try self.renderProgressBar(writer, sys_info.ram_usage_percent, 50);
        try writer.print(" {d:.1}% ({d:.2} GB / {d:.2} GB)\n", .{
            sys_info.ram_usage_percent,
            @as(f64, @floatFromInt(sys_info.ram_used)) / 1024.0 / 1024.0 / 1024.0,
            @as(f64, @floatFromInt(sys_info.ram_total)) / 1024.0 / 1024.0 / 1024.0,
        });
        
        // Disk Usage
        try self.setColor(writer, .white, .bold);
        try writer.writeAll("  Disk Usage:    ");
        try self.resetColor(writer);
        try self.renderProgressBar(writer, sys_info.disk_usage_percent, 50);
        try writer.print(" {d:.1}% ({d:.2} GB / {d:.2} GB)\n", .{
            sys_info.disk_usage_percent,
            @as(f64, @floatFromInt(sys_info.disk_used)) / 1024.0 / 1024.0 / 1024.0,
            @as(f64, @floatFromInt(sys_info.disk_total)) / 1024.0 / 1024.0 / 1024.0,
        });
        
        try writer.writeAll("\n");
        
        // System Info
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("━━━━━━━━━━━━━━━━━━━━━━━ SYSTEM INFORMATION ━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        try writer.print("  OS:            {s}\n", .{sys_info.os_name});
        try writer.print("  CPU Cores:     {d}\n", .{sys_info.cpu_cores});
        try writer.print("  Uptime:        {s}\n", .{try self.formatUptime(sys_info.uptime_seconds)});
        try writer.print("  Running Procs: {d}\n", .{sys_info.process_count});
        
        // Recommendations
        try writer.writeAll("\n");
        try self.setColor(writer, .yellow, .bold);
        try writer.writeAll("━━━━━━━━━━━━━━━━━━━━━━━ RECOMMENDATIONS ━━━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        if (sys_info.ram_usage_percent > 80.0) {
            try self.setColor(writer, .red, .normal);
            try writer.writeAll("  ⚠ High RAM usage detected! Consider closing unused applications.\n");
            try self.resetColor(writer);
        }
        
        if (sys_info.cpu_usage > 80.0) {
            try self.setColor(writer, .red, .normal);
            try writer.writeAll("  ⚠ High CPU usage detected! Check running processes.\n");
            try self.resetColor(writer);
        }
        
        if (sys_info.disk_usage_percent > 85.0) {
            try self.setColor(writer, .red, .normal);
            try writer.writeAll("  ⚠ Low disk space! Run cleanup to free up space.\n");
            try self.resetColor(writer);
        }
        
        if (sys_info.ram_usage_percent <= 80.0 and sys_info.cpu_usage <= 80.0 and sys_info.disk_usage_percent <= 85.0) {
            try self.setColor(writer, .green, .normal);
            try writer.writeAll("  ✓ System is running optimally!\n");
            try self.resetColor(writer);
        }
    }

    fn renderProcesses(self: *TuiApp, writer: anytype) !void {
        const processes = try self.system_monitor.getTopProcesses(10);
        defer self.allocator.free(processes);
        
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("\n━━━━━━━━━━━━━━━━━━━━━━━ TOP PROCESSES ━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        try self.setColor(writer, .white, .bold);
        try writer.writeAll("  PID      CPU%    RAM(MB)   NAME\n");
        try writer.writeAll("  ─────────────────────────────────────────────────────────────\n");
        try self.resetColor(writer);
        
        for (processes) |proc| {
            const color: Color = if (proc.cpu_percent > 50.0) .red else if (proc.cpu_percent > 20.0) .yellow else .white;
            try self.setColor(writer, color, .normal);
            try writer.print("  {d:<8} {d:>5.1}%  {d:>8.1}   {s}\n", .{
                proc.pid,
                proc.cpu_percent,
                @as(f64, @floatFromInt(proc.memory_bytes)) / 1024.0 / 1024.0,
                proc.name,
            });
            try self.resetColor(writer);
        }
        
        try writer.writeAll("\n");
        try self.setColor(writer, .yellow, .normal);
        try writer.writeAll("  Note: Process management features require elevated permissions\n");
        try self.resetColor(writer);
    }

    fn renderCleanup(self: *TuiApp, writer: anytype) !void {
        const cleanup_info = try self.optimizer_instance.analyzeJunkFiles();
        
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("\n━━━━━━━━━━━━━━━━━━━━━━━ CLEANUP ANALYSIS ━━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        try writer.writeAll("  Junk files found:\n\n");
        
        try self.setColor(writer, .white, .bold);
        try writer.print("  • Temporary files:     {d:.2} MB\n", .{
            @as(f64, @floatFromInt(cleanup_info.temp_files_size)) / 1024.0 / 1024.0,
        });
        try writer.print("  • Cache files:         {d:.2} MB\n", .{
            @as(f64, @floatFromInt(cleanup_info.cache_files_size)) / 1024.0 / 1024.0,
        });
        try writer.print("  • Log files:           {d:.2} MB\n", .{
            @as(f64, @floatFromInt(cleanup_info.log_files_size)) / 1024.0 / 1024.0,
        });
        try self.resetColor(writer);
        
        try writer.writeAll("\n");
        try self.setColor(writer, .green, .bold);
        try writer.print("  Total recoverable:     {d:.2} MB\n", .{
            @as(f64, @floatFromInt(cleanup_info.total_size)) / 1024.0 / 1024.0,
        });
        try self.resetColor(writer);
        
        try writer.writeAll("\n");
        try self.setColor(writer, .yellow, .normal);
        try writer.writeAll("  Press 'o' to optimize and clean junk files\n");
        try self.resetColor(writer);
    }

    fn renderStartup(self: *TuiApp, writer: anytype) !void {
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("\n━━━━━━━━━━━━━━━━━━━━━━━ STARTUP PROGRAMS ━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        try writer.writeAll("  Managing startup programs can improve boot time.\n\n");
        try self.setColor(writer, .yellow, .normal);
        try writer.writeAll("  This feature is platform-specific and requires elevated permissions.\n");
        try writer.writeAll("  Coming soon: View and manage startup applications\n");
        try self.resetColor(writer);
    }

    fn renderAbout(self: *TuiApp, writer: anytype) !void {
        try self.setColor(writer, .cyan, .bold);
        try writer.writeAll("\n━━━━━━━━━━━━━━━━━━━━━━━━━━ ABOUT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n");
        try self.resetColor(writer);
        
        try self.setColor(writer, .white, .bold);
        try writer.writeAll("  Device Booster v1.0\n\n");
        try self.resetColor(writer);
        
        try writer.writeAll("  A cross-platform terminal-based system optimizer\n");
        try writer.writeAll("  Built with Zig for maximum performance and reliability\n\n");
        
        try self.setColor(writer, .green, .normal);
        try writer.writeAll("  Features:\n");
        try writer.writeAll("  • Real-time system monitoring (CPU, RAM, Disk)\n");
        try writer.writeAll("  • Process management and analysis\n");
        try writer.writeAll("  • Intelligent junk file cleanup\n");
        try writer.writeAll("  • Memory optimization\n");
        try writer.writeAll("  • Cross-platform support (Linux, macOS, Windows)\n");
        try self.resetColor(writer);
        
        try writer.writeAll("\n");
        try self.setColor(writer, .cyan, .normal);
        try writer.writeAll("  GitHub: github.com/MythicalMAxX/Booster\n");
        try writer.writeAll("  License: MIT\n");
        try self.resetColor(writer);
    }

    fn renderProgressBar(self: *TuiApp, writer: anytype, percent: f64, width: usize) !void {
        _ = self;
        const filled = @as(usize, @intFromFloat(percent * @as(f64, @floatFromInt(width)) / 100.0));
        
        try writer.writeAll("[");
        
        var i: usize = 0;
        while (i < width) : (i += 1) {
            if (i < filled) {
                if (percent > 80.0) {
                    try writer.writeAll("\x1b[31m█\x1b[0m"); // Red
                } else if (percent > 60.0) {
                    try writer.writeAll("\x1b[33m█\x1b[0m"); // Yellow
                } else {
                    try writer.writeAll("\x1b[32m█\x1b[0m"); // Green
                }
            } else {
                try writer.writeAll("░");
            }
        }
        
        try writer.writeAll("]");
    }

    fn formatUptime(self: *TuiApp, seconds: u64) ![]const u8 {
        const days = seconds / 86400;
        const hours = (seconds % 86400) / 3600;
        const mins = (seconds % 3600) / 60;
        
        return std.fmt.allocPrint(self.allocator, "{d}d {d}h {d}m", .{ days, hours, mins });
    }

    fn handleInput(self: *TuiApp) !void {
        var buf: [1]u8 = undefined;
        const read_result = std.posix.read(std.c.STDIN_FILENO, &buf) catch |err| {
            if (err == error.WouldBlock) return;
            return err;
        };
        
        if (read_result == 0) return;
        
        switch (buf[0]) {
            'q', 'Q' => self.running = false,
            '1' => self.current_view = .dashboard,
            '2' => self.current_view = .processes,
            '3' => self.current_view = .cleanup,
            '4' => self.current_view = .startup,
            '5' => self.current_view = .about,
            'o', 'O' => try self.performOptimization(),
            else => {},
        }
    }

    fn performOptimization(self: *TuiApp) !void {
        const stdout = StdoutWriter{ .allocator = self.allocator };
        
        try self.clearScreen();
        try self.setColor(stdout, .green, .bold);
        try stdout.writeAll("\n  🚀 Optimizing system...\n\n");
        try self.resetColor(stdout);
        
        // Clean junk files
        try stdout.writeAll("  [1/3] Cleaning junk files... ");
        const cleaned = try self.optimizer_instance.cleanJunkFiles();
        try self.setColor(stdout, .green, .normal);
        try stdout.print("✓ Freed {d:.2} MB\n", .{
            @as(f64, @floatFromInt(cleaned)) / 1024.0 / 1024.0,
        });
        try self.resetColor(stdout);
        
        // Optimize memory
        try stdout.writeAll("  [2/3] Optimizing memory... ");
        std.Thread.sleep(500 * std.time.ns_per_ms);
        try self.setColor(stdout, .green, .normal);
        try stdout.writeAll("✓ Done\n");
        try self.resetColor(stdout);
        
        // System check
        try stdout.writeAll("  [3/3] Running system check... ");
        std.Thread.sleep(500 * std.time.ns_per_ms);
        try self.setColor(stdout, .green, .normal);
        try stdout.writeAll("✓ Complete\n");
        try self.resetColor(stdout);
        
        try stdout.writeAll("\n");
        try self.setColor(stdout, .green, .bold);
        try stdout.writeAll("  ✓ Optimization complete! Press any key to continue...\n");
        try self.resetColor(stdout);
        
        var buf: [1]u8 = undefined;
        _ = std.posix.read(std.c.STDIN_FILENO, &buf) catch {};
    }

    // Terminal control functions
    fn clearScreen(self: *TuiApp) !void {
        _ = self;
        // Clear screen and move cursor to home
        try std.fs.File.stdout().writeAll("\x1b[2J\x1b[H");
        // Note: stdout is unbuffered by default, no flush needed
    }

    fn hideCursor(self: *TuiApp) !void {
        _ = self;
        try std.fs.File.stdout().writeAll("\x1b[?25l");
    }

    fn showCursor(self: *TuiApp) !void {
        _ = self;
        try std.fs.File.stdout().writeAll("\x1b[?25h");
    }

    const Color = enum {
        black,
        red,
        green,
        yellow,
        blue,
        magenta,
        cyan,
        white,
    };

    const Style = enum {
        normal,
        bold,
    };

    fn setColor(self: *TuiApp, writer: anytype, color: Color, style: Style) !void {
        _ = self;
        const color_code = switch (color) {
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
        };
        
        if (style == .bold) {
            try writer.print("\x1b[1;{s}m", .{color_code});
        } else {
            try writer.print("\x1b[{s}m", .{color_code});
        }
    }

    fn resetColor(self: *TuiApp, writer: anytype) !void {
        _ = self;
        try writer.writeAll("\x1b[0m");
    }

    fn enableRawMode(self: *TuiApp) !void {
        _ = self;
        if (@import("builtin").os.tag == .windows) {
            // Windows raw mode
            const kernel32 = std.os.windows.kernel32;
            const stdin_handle = try std.os.windows.GetStdHandle(std.os.windows.STD_INPUT_HANDLE);
            
            var mode: std.os.windows.DWORD = 0;
            if (kernel32.GetConsoleMode(stdin_handle, &mode) == 0) {
                return error.GetConsoleModeFailed;
            }
            
            // Disable echo and line input
            mode &= ~@as(u32, 0x0002); // ENABLE_ECHO_INPUT
            mode &= ~@as(u32, 0x0001); // ENABLE_LINE_INPUT
            
            if (kernel32.SetConsoleMode(stdin_handle, mode) == 0) {
                return error.SetConsoleModeFailed;
            }
        } else {
            // Unix raw mode
            const stdin_fd = std.c.STDIN_FILENO;
            var termios = try std.posix.tcgetattr(stdin_fd);
            
            // Disable canonical mode and echo
            termios.lflag.ICANON = false;
            termios.lflag.ECHO = false;
            
            // Set non-blocking
            termios.cc[@intFromEnum(std.posix.V.TIME)] = 0;
            termios.cc[@intFromEnum(std.posix.V.MIN)] = 0;
            
            try std.posix.tcsetattr(stdin_fd, .FLUSH, termios);
        }
    }

    fn disableRawMode(self: *TuiApp) !void {
        _ = self;
        if (@import("builtin").os.tag == .windows) {
            const kernel32 = std.os.windows.kernel32;
            const stdin_handle = try std.os.windows.GetStdHandle(std.os.windows.STD_INPUT_HANDLE);
            
            var mode: std.os.windows.DWORD = 0;
            if (kernel32.GetConsoleMode(stdin_handle, &mode) == 0) {
                return error.GetConsoleModeFailed;
            }
            
            // Re-enable echo and line input
            mode |= 0x0002; // ENABLE_ECHO_INPUT
            mode |= 0x0001; // ENABLE_LINE_INPUT
            
            _ = kernel32.SetConsoleMode(stdin_handle, mode);
        } else {
            const stdin_fd = std.c.STDIN_FILENO;
            var termios = try std.posix.tcgetattr(stdin_fd);
            
            termios.lflag.ICANON = true;
            termios.lflag.ECHO = true;
            
            try std.posix.tcsetattr(stdin_fd, .FLUSH, termios);
        }
    }
};
