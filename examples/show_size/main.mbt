///|
/// Prints the current terminal size when one of the standard streams is a TTY.
fn main {
  match @terminal_size.terminal_size() {
    Some(size) => {
      println("Terminal width : \{size.columns} columns")
      println("Terminal height: \{size.rows} rows")
    }
    None =>
      println(
        "Unable to determine terminal size from stdout, stderr, or stdin.",
      )
  }
}
