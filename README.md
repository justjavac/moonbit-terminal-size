# moonbit-terminal-size

[![CI](https://github.com/justjavac/moonbit-terminal-size/actions/workflows/ci.yml/badge.svg)](https://github.com/justjavac/moonbit-terminal-size/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-terminal-size/main?label=coverage)](https://app.codecov.io/gh/justjavac/moonbit-terminal-size)
[![linux](https://img.shields.io/codecov/c/github/justjavac/moonbit-terminal-size/main?flag=linux&label=linux)](https://app.codecov.io/gh/justjavac/moonbit-terminal-size)
[![macos](https://img.shields.io/codecov/c/github/justjavac/moonbit-terminal-size/main?flag=macos&label=macOS)](https://app.codecov.io/gh/justjavac/moonbit-terminal-size)
[![windows](https://img.shields.io/codecov/c/github/justjavac/moonbit-terminal-size/main?flag=windows&label=windows)](https://app.codecov.io/gh/justjavac/moonbit-terminal-size)
[![Docs](https://img.shields.io/badge/docs-mooncakes.io-green)](https://mooncakes.io/docs/justjavac/terminal_size)

`moonbit-terminal-size` is a small native MoonBit module for querying the
visible size of the current terminal.

It is inspired by Rust's
[`terminal-size`](https://github.com/eminence/terminal-size) crate and aims to
offer the same simple experience in MoonBit: ask for the current terminal
width and height, and receive `None` when the active standard streams are not
connected to a terminal.

## Features

- Cross-platform native support for Windows, macOS, Linux, and other Unix-like systems with `ioctl`
- Simple API that returns `Option[(Width, Height)]`
- Stream probing order that matches the Rust crate: `stdout`, `stderr`, then `stdin`
- No external runtime dependencies
- Native-only package with CI and coverage reporting for Linux, macOS, and Windows

## Installation

```bash
moon add justjavac/terminal_size
```

This package supports the `native` target only.

## Usage

```moonbit
match @terminal_size.terminal_size() {
  Some((width, height)) => {
    println("terminal: \{width.to_int()} x \{height.to_int()}")
  }
  None => {
    println("not attached to a terminal")
  }
}
```

## Example Program

Run the bundled example from the repository root:

```bash
moon run examples/show_size --target native
```

Typical output:

```text
Terminal width : 120 columns
Terminal height: 30 rows
```

## Platform Notes

- Windows uses the Win32 console API.
- Unix-like systems use `ioctl(TIOCGWINSZ)` against standard file descriptors.
- The function returns the first terminal-backed stream among `stdout`,
  `stderr`, and `stdin`.
- If no standard stream is attached to a terminal, the package returns `None`.

## Platform Support

| Platform | Status | Backend |
| -------- | ------ | ------- |
| Windows | Supported | `GetConsoleScreenBufferInfo` |
| macOS | Supported | `ioctl(TIOCGWINSZ)` |
| Linux | Supported | `ioctl(TIOCGWINSZ)` |
| Other Unix-like systems with `TIOCGWINSZ` | Supported | `ioctl(TIOCGWINSZ)` |
| Other targets | Returns `None` | Stub fallback |

## API

- `terminal_size() -> (Width, Height)?`
- `Width::to_int() -> Int`
- `Height::to_int() -> Int`

`Width` and `Height` are lightweight wrappers around native terminal
dimensions. They make the return value self-describing while still being easy
to convert back to `Int` values for application logic.

## Behavior Details

- Probe order is `stdout`, then `stderr`, then `stdin`.
- A size is considered valid only when both width and height are greater than zero.
- The result describes the visible terminal window, not the scrollback buffer.
- When the current process is redirected or detached from a terminal, the function returns `None` instead of guessing.

## Relationship to Rust's `terminal-size`

This project is intentionally modeled after
[`eminence/terminal-size`](https://github.com/eminence/terminal-size):

- It keeps the same high-level mental model of returning width and height together.
- It follows the same standard-stream probe order.
- It uses native OS APIs instead of shelling out to external tools.

The MoonBit version adds small convenience methods, `Width::to_int()` and
`Height::to_int()`, so callers can move from strong wrapper types back to plain
integers ergonomically.

## Development

```bash
moon fmt
moon test --target native
moon test --target native --enable-coverage
moon coverage analyze -p justjavac/terminal_size -- -f summary
moon info --target native
```

The test suite includes:

- Black-box tests for the public API
- White-box tests for payload decoding and probe order
- Coverage checks that currently reach 100% for the MoonBit layer

## License

MIT. See [LICENSE](LICENSE).
