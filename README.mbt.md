# justjavac/terminal_size

Cross-platform terminal size helpers for MoonBit.

```mbt check
///|
test "terminal size api can be called" {
  match @terminal_size.terminal_size() {
    Some((width, height)) => {
      assert_true(width.to_int() > 0)
      assert_true(height.to_int() > 0)
    }
    None => ()
  }
}
```
