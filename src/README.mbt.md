# justjavac/terminal_size

Cross-platform terminal size helpers for MoonBit.

```mbt check
///|
test "terminal size api can be called" {
  match @terminal_size.terminal_size() {
    Some(size) => {
      assert_true(size.columns > 0)
      assert_true(size.rows > 0)
    }
    None => ()
  }
}
```
