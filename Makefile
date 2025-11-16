# Booster Makefile

.PHONY: all build run test clean install uninstall format help

# Default target
all: build

# Build the project (release mode)
build:
	@echo "Building Booster..."
	@zig build -Doptimize=ReleaseFast

# Build in debug mode
debug:
	@echo "Building Booster (debug mode)..."
	@zig build

# Run the application
run:
	@echo "Running Booster..."
	@zig build run

# Run tests
test:
	@echo "Running tests..."
	@zig build test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf zig-cache zig-out .zig-cache

# Format code
format:
	@echo "Formatting code..."
	@zig fmt src/

# Install to system
install: build
	@echo "Installing Booster to /usr/local/bin..."
	@sudo cp zig-out/bin/booster /usr/local/bin/
	@sudo chmod +x /usr/local/bin/booster
	@echo "✓ Booster installed successfully!"
	@echo "Run 'booster' to start"

# Uninstall from system
uninstall:
	@echo "Uninstalling Booster..."
	@sudo rm -f /usr/local/bin/booster
	@echo "✓ Booster uninstalled"

# Check Zig version
check-zig:
	@echo "Checking Zig installation..."
	@zig version || (echo "❌ Zig not found. Please install Zig 0.13.0 or later" && exit 1)
	@echo "✓ Zig found"

# Development setup
setup: check-zig
	@echo "Setting up development environment..."
	@zig build
	@echo "✓ Development environment ready"

# Help target
help:
	@echo "Booster - Terminal-Based System Optimizer"
	@echo ""
	@echo "Available targets:"
	@echo "  make build      - Build the project (release mode)"
	@echo "  make debug      - Build in debug mode"
	@echo "  make run        - Run the application"
	@echo "  make test       - Run tests"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make format     - Format source code"
	@echo "  make install    - Install to /usr/local/bin (requires sudo)"
	@echo "  make uninstall  - Remove from /usr/local/bin (requires sudo)"
	@echo "  make check-zig  - Verify Zig installation"
	@echo "  make setup      - Setup development environment"
	@echo "  make help       - Show this help message"
