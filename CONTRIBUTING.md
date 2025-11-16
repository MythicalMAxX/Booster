# Contributing to Booster

Thank you for your interest in contributing to Booster! This document provides guidelines and instructions for contributing.

## 🤝 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites

- Zig 0.13.0 or later
- Git
- Terminal with ANSI support
- Familiarity with Zig programming language

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/MythicalMAxX/Booster.git
   cd Booster
   ```

3. Build the project:
   ```bash
   zig build
   ```

4. Run tests:
   ```bash
   zig build test
   ```

5. Run the application:
   ```bash
   zig build run
   ```

## 📝 Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates
- `refactor/*` - Code refactoring

### Making Changes

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines

3. Format your code:
   ```bash
   zig fmt src/
   ```

4. Run tests:
   ```bash
   zig build test
   ```

5. Commit your changes using conventional commits:
   ```bash
   git commit -m "feat(scope): add new feature"
   ```

### Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `perf`: Performance improvements
- `chore`: Build process or auxiliary tool changes

**Examples:**
```bash
feat(monitor): add network usage monitoring
fix(tui): correct color rendering on Windows
docs(readme): update installation instructions
refactor(optimizer): improve cleanup efficiency
test(monitor): add tests for CPU usage calculation
```

## 🏗️ Code Style

### Zig Style Guidelines

1. **Naming Conventions:**
   - `camelCase` for functions and variables
   - `PascalCase` for types and structs
   - `SCREAMING_SNAKE_CASE` for constants
   - `snake_case` for file names

2. **Formatting:**
   - Use `zig fmt` for automatic formatting
   - 4 spaces for indentation (no tabs)
   - Max line length: 100 characters

3. **Code Organization:**
   - Group related functions together
   - Keep functions focused and small (<50 lines)
   - Add comments for complex logic
   - Document public APIs

4. **Error Handling:**
   - Use Zig's error handling (`!` and `catch`)
   - Provide meaningful error messages
   - Don't ignore errors

5. **Memory Management:**
   - Always pair `init` with `deinit`
   - Use defer for cleanup
   - Avoid memory leaks

### Example Code

```zig
const std = @import("std");

/// Calculates the average of a slice of integers.
/// Returns an error if the slice is empty.
pub fn calculateAverage(values: []const i32) !f64 {
    if (values.len == 0) {
        return error.EmptySlice;
    }
    
    var sum: i64 = 0;
    for (values) |value| {
        sum += value;
    }
    
    return @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(values.len));
}
```

## 🧪 Testing

### Writing Tests

1. Place tests in the same file as the code
2. Use descriptive test names
3. Test both success and error cases
4. Keep tests independent

```zig
test "calculateAverage - normal case" {
    const values = [_]i32{ 1, 2, 3, 4, 5 };
    const avg = try calculateAverage(&values);
    try std.testing.expectApproxEqAbs(3.0, avg, 0.001);
}

test "calculateAverage - empty slice" {
    const values = [_]i32{};
    try std.testing.expectError(error.EmptySlice, calculateAverage(&values));
}
```

### Running Tests

```bash
# Run all tests
zig build test

# Run specific test file
zig test src/monitor.zig

# Run with memory leak detection
zig build test -Dtest-leak-check
```

## 🐛 Bug Reports

### Before Submitting

1. Check if the issue already exists
2. Verify it's reproducible
3. Test with the latest version

### Bug Report Template

```markdown
**Describe the bug**
A clear description of the bug.

**To Reproduce**
Steps to reproduce:
1. Run `booster`
2. Navigate to '...'
3. Press '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Zig version: [e.g., 0.13.0]
- Terminal: [e.g., GNOME Terminal]

**Additional context**
Any other relevant information.
```

## 💡 Feature Requests

### Feature Request Template

```markdown
**Feature Description**
A clear description of the feature.

**Use Case**
Why this feature would be useful.

**Proposed Implementation**
How you think it should work (optional).

**Alternatives Considered**
Other approaches you've thought about.
```

## 🔍 Code Review Process

### For Contributors

1. Ensure all tests pass
2. Update documentation if needed
3. Keep PRs focused and small
4. Respond to review feedback promptly

### For Reviewers

1. Be constructive and respectful
2. Focus on code quality and design
3. Verify tests are adequate
4. Check documentation updates

## 📚 Documentation

### Documentation Standards

1. **Code Comments:**
   - Document public APIs
   - Explain complex algorithms
   - Add usage examples

2. **README Updates:**
   - Keep installation instructions current
   - Update feature list
   - Add examples for new features

3. **API Documentation:**
   - Use doc comments (`///`)
   - Provide examples
   - Document parameters and return values

## 🎯 Areas for Contribution

### Good First Issues

- Documentation improvements
- Adding tests
- Fixing typos
- Simple bug fixes

### Advanced Contributions

- New platform support
- Performance optimizations
- New monitoring features
- UI enhancements

### Current Priorities

1. Windows-specific optimizations
2. Process management features
3. Startup program management
4. Network monitoring
5. Configuration file support

## 📞 Getting Help

- **Questions**: Open a [Discussion](https://github.com/MythicalMAxX/Booster/discussions)
- **Bugs**: Open an [Issue](https://github.com/MythicalMAxX/Booster/issues)
- **Chat**: Join our community (link coming soon)

## 🏆 Recognition

Contributors will be:
- Listed in the README
- Mentioned in release notes
- Given credit in commit messages

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Booster! 🚀
