# 🚀 Booster - Quick Start Guide

## Build and Run

### Prerequisites
- Zig 0.15.0+ ([Download](https://ziglang.org/download/))

### Build

```bash
# Debug build
zig build

# Release build (recommended for performance)
zig build -Doptimize=ReleaseFast

# Or use Make
make build
```

### Run

```bash
# Run directly
./zig-out/bin/booster

# Or with zig build
zig build run
```

### Install System-Wide

```bash
# Install to /usr/local/bin
sudo make install

# Then run from anywhere
booster
```

## Usage

### Navigation
- `1` - Dashboard (System Performance)
- `2` - Processes (Top Resource-Consuming Processes)  
- `3` - Cleanup (Junk File Analysis)
- `4` - Startup (Startup Programs Management)
- `5` - About

### Actions
- `o` - Optimize/Clean System
- `q` - Quit Application

### Features

**Dashboard View:**
- Real-time CPU, RAM, and Disk usage
- System information (OS, cores, uptime)
- Smart recommendations

**Process View:**
- Top 10 resource-consuming processes
- CPU and memory usage per process
- Color-coded warnings

**Cleanup View:**
- Analyze junk files (temp, cache, logs)
- Show recoverable space
- One-click cleanup

## Platform-Specific Notes

### Linux
- Full feature support
- Some operations require sudo for elevated permissions
- Reads from `/proc` for system information

### macOS
- Full feature support  
- May require granting terminal permissions
- Uses system APIs for monitoring

### Windows
- Core features supported
- Run as Administrator for full functionality
- Use Windows Terminal for best experience

## Troubleshooting

**Build Errors:**
- Ensure Zig 0.15.0+ is installed (`zig version`)
- Clean build cache: `rm -rf zig-cache zig-out`

**Permission Errors:**
- Run with sudo/Administrator for system operations
- Some features require elevated permissions

**Terminal Colors Not Working:**
- Use a modern terminal with ANSI support
- Try Windows Terminal (Windows), iTerm2 (macOS), or GNOME Terminal (Linux)

## Performance

Booster is designed for minimal overhead:
- **CPU**: <1% during monitoring
- **RAM**: ~5-10 MB
- **Startup**: <100ms
- **Binary Size**: ~2.6 MB (ReleaseFast)

## Development

```bash
# Format code
zig fmt src/

# Run tests
zig build test

# Clean build artifacts
make clean
```

## What's Next?

Check out the full [README.md](README.md) for:
- Detailed architecture
- Contributing guidelines
- Advanced features
- API documentation

## Support

- Issues: [GitHub Issues](https://github.com/MythicalMAxX/Booster/issues)
- Discussions: [GitHub Discussions](https://github.com/MythicalMAxX/Booster/discussions)

---

**Enjoy optimizing your system with Booster!** 🚀
