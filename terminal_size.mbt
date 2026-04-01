///|
let stdout_stream_kind : Int = 0

///|
let stderr_stream_kind : Int = 1

///|
let stdin_stream_kind : Int = 2

///|
let probe_payload_len : Int = 4

///|
/// Probes one standard stream and returns a four-byte payload on success.
extern "C" fn terminal_size_probe_ffi(stream_kind : Int) -> Bytes = "mb_terminal_size_probe"

///|
/// Visible size of a terminal measured in character cells.
///
/// `columns` is the terminal width and `rows` is the terminal height.
/// The public API uses a small record so callers can access
/// `size.columns` and `size.rows` directly, which is usually more natural in
/// MoonBit than wrapping each dimension in its own numeric newtype.
///
/// Values returned by [terminal_size](/D:/Code/moonbit-terminal-size/terminal_size.mbt)
/// are always positive.
pub struct Size {
  columns : Int
  rows : Int
} derive(Eq, Show)

///|
/// Decodes a big-endian unsigned 16-bit integer from two bytes.
fn decode_u16(msb : Byte, lsb : Byte) -> Int {
  msb.to_int() * 256 + lsb.to_int()
}

///|
/// Turns a native probe payload into a terminal size tuple when it is valid.
fn decode_probe_bytes(bytes : Bytes) -> Size? {
  if bytes.length() != probe_payload_len {
    None
  } else {
    let width = decode_u16(bytes[0], bytes[1])
    let height = decode_u16(bytes[2], bytes[3])
    if width == 0 || height == 0 {
      None
    } else {
      Some({ columns: width, rows: height })
    }
  }
}

///|
/// Probes one standard stream and decodes the native payload.
fn terminal_size_of_stream(stream_kind : Int, probe : (Int) -> Bytes) -> Size? {
  decode_probe_bytes(probe(stream_kind))
}

///|
/// Probes standard streams in priority order until one returns a size.
fn terminal_size_with(probe : (Int) -> Bytes) -> Size? {
  for stream_kind in [stdout_stream_kind, stderr_stream_kind, stdin_stream_kind] {
    match terminal_size_of_stream(stream_kind, probe) {
      Some(size) => return Some(size)
      None => ()
    }
  }
  None
}

///|
/// Returns the visible size of the current terminal in character cells.
///
/// The function probes the three standard streams in this order:
/// `stdout`, `stderr`, then `stdin`. The first stream that is attached to a
/// terminal and reports a non-zero size wins. If none of the standard streams
/// are attached to a terminal, this function returns `None`.
///
/// The implementation uses platform-native APIs:
///
/// - Windows: `GetConsoleScreenBufferInfo`
/// - Unix-like systems: `ioctl(TIOCGWINSZ)`
///
/// The returned `Size` describes the visible terminal window, not a scrollback
/// buffer or an off-screen backing store.
///
/// # Example
/// ```mbt check
/// test {
///   match @terminal_size.terminal_size() {
///     Some(size) => {
///       assert_true(size.columns > 0)
///       assert_true(size.rows > 0)
///     }
///     None => ()
///   }
/// }
/// ```
pub fn terminal_size() -> Size? {
  terminal_size_with(terminal_size_probe_ffi)
}
