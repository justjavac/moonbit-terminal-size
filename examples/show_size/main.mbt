///|
/// Prints the current terminal size when one of the standard streams is a TTY.
fn main {
  match @terminal_size.terminal_size() {
    Some((width, height)) => {
      println("Terminal width : \{width.to_int()} columns")
      println("Terminal height: \{height.to_int()} rows")
    }
    None =>
      println(
        "Unable to determine terminal size from stdout, stderr, or stdin.",
      )
  }
}
