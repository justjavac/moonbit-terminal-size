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
/// Width of a terminal measured in character cells.
///
/// The wrapper keeps terminal column counts distinct from other integers and
/// mirrors the intent of Rust's `terminal-size` crate, which models width and
/// height as separate strong types.
///
/// Use [Width::to_int](/D:/Code/moonbit-terminal-size/terminal_size.mbt) when
/// you need the width as a regular `Int`.
pub struct Width {
  columns : UInt16
} derive(Eq, Show)

///|
/// Converts this terminal width into MoonBit's default `Int` type.
///
/// This is useful when you want to do arithmetic, comparisons, or string
/// interpolation without carrying the wrapper type around.
///
/// # Example
/// ```mbt check
/// test {
///   match @terminal_size.terminal_size() {
///     Some((width, _)) => assert_true(width.to_int() > 0)
///     None => ()
///   }
/// }
/// ```
pub fn Width::to_int(self : Width) -> Int {
  self.columns.to_int()
}

///|
/// Height of a terminal measured in character cells.
///
/// The wrapper keeps terminal row counts explicit in the type system and pairs
/// with [Width](/D:/Code/moonbit-terminal-size/terminal_size.mbt) in the return
/// value of [terminal_size](/D:/Code/moonbit-terminal-size/terminal_size.mbt).
///
/// Use [Height::to_int](/D:/Code/moonbit-terminal-size/terminal_size.mbt) when
/// you need the height as a regular `Int`.
pub struct Height {
  rows : UInt16
} derive(Eq, Show)

///|
/// Converts this terminal height into MoonBit's default `Int` type.
///
/// This is useful when you want to do arithmetic, comparisons, or string
/// interpolation without carrying the wrapper type around.
///
/// # Example
/// ```mbt check
/// test {
///   match @terminal_size.terminal_size() {
///     Some((_, height)) => assert_true(height.to_int() > 0)
///     None => ()
///   }
/// }
/// ```
pub fn Height::to_int(self : Height) -> Int {
  self.rows.to_int()
}

///|
/// Decodes a big-endian unsigned 16-bit integer from two bytes.
fn decode_u16(msb : Byte, lsb : Byte) -> UInt16 {
  Int::to_uint16(msb.to_int() * 256 + lsb.to_int())
}

///|
/// Turns a native probe payload into a terminal size tuple when it is valid.
fn decode_probe_bytes(bytes : Bytes) -> (Width, Height)? {
  if bytes.length() != probe_payload_len {
    None
  } else {
    let width = decode_u16(bytes[0], bytes[1])
    let height = decode_u16(bytes[2], bytes[3])
    if width == Int::to_uint16(0) || height == Int::to_uint16(0) {
      None
    } else {
      Some((Width::{ columns: width }, Height::{ rows: height }))
    }
  }
}

///|
/// Probes one standard stream and decodes the native payload.
fn terminal_size_of_stream(
  stream_kind : Int,
  probe : (Int) -> Bytes,
) -> (Width, Height)? {
  decode_probe_bytes(probe(stream_kind))
}

///|
/// Probes standard streams in priority order until one returns a size.
fn terminal_size_with(probe : (Int) -> Bytes) -> (Width, Height)? {
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
/// The returned values describe the visible terminal window, not a scrollback
/// buffer or an off-screen backing store.
///
/// # Example
/// ```mbt check
/// test {
///   match @terminal_size.terminal_size() {
///     Some((width, height)) => {
///       assert_true(width.to_int() > 0)
///       assert_true(height.to_int() > 0)
///     }
///     None => ()
///   }
/// }
/// ```
pub fn terminal_size() -> (Width, Height)? {
  terminal_size_with(terminal_size_probe_ffi)
}
