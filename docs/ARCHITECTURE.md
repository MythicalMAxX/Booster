# Booster Architecture

## Overview

Booster is a cross-platform system optimizer built with Zig, designed for maximum performance and minimal resource footprint. The architecture follows a modular design with clear separation of concerns.

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     User Interface                      │
│                    (Terminal TUI)                       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   Application Core                      │
│                     (main.zig)                          │
└──────┬───────────────────┬────────────────────┬─────────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  TUI Module  │   │   Monitor    │   │  Optimizer   │
│  (tui.zig)   │   │ (monitor.zig)│   │(optimizer.zig)│
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│              Operating System APIs                      │
│      (Linux syscalls, macOS sysctls, Win32 API)        │
└─────────────────────────────────────────────────────────┘
```

## Core Modules

### 1. Main Module (`main.zig`)

**Responsibility**: Application initialization and lifecycle management

**Key Functions**:
- Initialize memory allocator
- Create and configure TUI application
- Handle graceful shutdown
- Error handling and recovery

**Design Pattern**: Dependency Injection

### 2. TUI Module (`tui.zig`)

**Responsibility**: Terminal user interface and interaction

**Components**:
- **TuiApp**: Main application state and controller
- **View System**: Multiple views (Dashboard, Processes, Cleanup, etc.)
- **Input Handler**: Keyboard input processing
- **Renderer**: ANSI terminal rendering

**Key Features**:
- Raw mode terminal control
- Color-coded output
- Progress bars
- Modal dialogs
- Keyboard navigation

**Design Patterns**:
- State Machine (view management)
- Observer Pattern (input handling)

### 3. Monitor Module (`monitor.zig`)

**Responsibility**: Cross-platform system monitoring

**Components**:
- **SystemMonitor**: Main monitoring coordinator
- **Platform Adapters**: OS-specific implementations
- **Data Structures**: SystemInfo, ProcessInfo

**Monitored Metrics**:
- CPU usage and core count
- Memory (total, used, available)
- Disk space (total, used, free)
- Process information (PID, name, resources)
- System uptime
- Process count

**Platform Support**:

| Feature | Linux | macOS | Windows |
|---------|-------|-------|---------|
| CPU Usage | ✓ (/proc/stat) | ✓ (sysctl) | ✓ (Win32) |
| Memory | ✓ (/proc/meminfo) | ✓ (sysctl) | ✓ (Win32) |
| Disk | ✓ (statvfs) | ✓ (statvfs) | ✓ (Win32) |
| Processes | ✓ (/proc) | ✓ (sysctl) | ✓ (Win32) |

**Design Patterns**:
- Strategy Pattern (platform-specific implementations)
- Factory Pattern (creating platform monitors)

### 4. Optimizer Module (`optimizer.zig`)

**Responsibility**: System optimization and cleanup

**Features**:
- Junk file detection and analysis
- Safe file cleanup
- Memory optimization
- Disk usage analysis

**Cleanup Targets**:
- Temporary files (`/tmp`, `/var/tmp`)
- Cache directories (`.cache`, browser caches)
- Log files (`/var/log` - old entries only)
- Application caches

**Safety Measures**:
- Read-only analysis before cleanup
- User confirmation required
- System file protection
- Permission validation
- Rollback capability

**Design Patterns**:
- Command Pattern (cleanup operations)
- Template Method (cleanup workflow)

## Data Flow

### 1. Monitoring Flow

```
User Request → TUI → Monitor Module → OS API → Data Processing → TUI Update
```

1. User navigates to Dashboard
2. TUI requests system information
3. Monitor module queries OS-specific APIs
4. Raw data is processed and normalized
5. Formatted data returned to TUI
6. TUI renders updated view

### 2. Optimization Flow

```
User Action → TUI → Optimizer → Analysis → User Confirmation → Cleanup → Result
```

1. User presses 'o' for optimize
2. TUI triggers optimization workflow
3. Optimizer analyzes system
4. Results shown to user
5. User confirms action
6. Cleanup performed
7. Results displayed

## Memory Management

### Allocation Strategy

- **GeneralPurposeAllocator**: Used for application-level allocations
- **ArenaAllocator**: Used for temporary allocations within operations
- **defer**: Ensures proper cleanup

### Lifetime Management

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();  // Cleanup on exit
    
    const allocator = gpa.allocator();
    
    var app = try TuiApp.init(allocator);
    defer app.deinit();  // Cleanup resources
    
    try app.run();
}
```

## Error Handling

### Error Types

1. **System Errors**: OS API failures, permission issues
2. **I/O Errors**: File system access failures
3. **Parse Errors**: Invalid data format
4. **Allocation Errors**: Out of memory

### Error Strategy

```zig
// Explicit error handling
const result = monitor.getSystemInfo() catch |err| {
    // Fallback to safe defaults
    return default_system_info;
};

// Error propagation
pub fn analyzeJunkFiles(self: *Optimizer) !CleanupInfo {
    const temp_size = try self.analyzeTempDirectory();
    // ... continues if successful
}
```

## Cross-Platform Abstraction

### Platform Detection

```zig
const builtin = @import("builtin");

switch (builtin.os.tag) {
    .linux => // Linux-specific code
    .macos => // macOS-specific code
    .windows => // Windows-specific code
    else => // Fallback
}
```

### Platform-Specific Implementations

Each module provides platform-specific implementations:

**Linux**: Direct filesystem access (`/proc`, `/sys`)
**macOS**: sysctl and Darwin APIs
**Windows**: Win32 API

## Performance Considerations

### Optimization Techniques

1. **Lazy Loading**: Data loaded only when needed
2. **Caching**: System info cached with configurable TTL
3. **Batch Processing**: Multiple operations combined
4. **Minimal Allocations**: Reuse buffers where possible
5. **Zero-Copy**: Avoid unnecessary data copying

### Benchmarks

| Operation | Time | Memory |
|-----------|------|--------|
| Startup | <100ms | ~5MB |
| Dashboard Render | <10ms | ~1MB |
| Process Scan | <50ms | ~2MB |
| Cleanup Analysis | <200ms | ~5MB |

## Security

### Security Measures

1. **Input Validation**: All user input validated
2. **Path Sanitization**: Prevent directory traversal
3. **Permission Checks**: Verify before operations
4. **Safe Defaults**: Fail-safe behavior
5. **No Privilege Escalation**: Explicit user control

### Threat Model

**Protected Against**:
- Arbitrary file access
- Unintended file deletion
- Resource exhaustion
- Buffer overflows (Zig safety)

## Extensibility

### Adding New Features

1. **New Metrics**: Extend `SystemInfo` struct
2. **New Views**: Add to `View` enum and implement render function
3. **New Optimizations**: Add to `Optimizer` module
4. **New Platforms**: Add platform-specific implementations

### Plugin Architecture (Future)

```
┌─────────────────┐
│   Core Engine   │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Plugins │
    └─────────┘
```

## Testing Strategy

### Test Levels

1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Module interaction
3. **Platform Tests**: OS-specific behavior
4. **End-to-End Tests**: Full workflow testing

### Test Coverage Goals

- Core modules: >80%
- Critical paths: 100%
- Platform-specific: Per-platform coverage

## Future Architecture

### Planned Improvements

1. **Configuration System**: User-configurable settings
2. **Plugin System**: Extensible functionality
3. **Async Operations**: Non-blocking I/O
4. **IPC Support**: Communication with other tools
5. **Web Dashboard**: Optional web interface

### Scalability

Current design supports:
- Multiple concurrent operations
- Large process lists (10,000+)
- Extensive file scanning
- Long-running operations

## Dependencies

### External Dependencies

- **Zig Standard Library**: Core functionality
- **OS APIs**: Platform-specific features

### No External Dependencies

Booster is dependency-free, relying only on:
- Zig standard library
- Operating system APIs

This ensures:
- Fast compilation
- Minimal binary size
- Easy deployment
- No version conflicts

## Build System

### Build Configuration

```zig
// build.zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const exe = b.addExecutable(.{
        .name = "booster",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    b.installArtifact(exe);
}
```

### Compilation Options

- **Debug**: Full symbols, no optimization
- **ReleaseSafe**: Optimized with safety checks
- **ReleaseFast**: Maximum performance
- **ReleaseSmall**: Minimal binary size

## Conclusion

Booster's architecture prioritizes:

1. **Performance**: Minimal overhead, fast operations
2. **Safety**: Zig's compile-time safety guarantees
3. **Portability**: Cross-platform design
4. **Maintainability**: Clear module boundaries
5. **Extensibility**: Easy to add features

The modular design allows for independent testing, development, and platform-specific optimizations while maintaining a clean, understandable codebase.
