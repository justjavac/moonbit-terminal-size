///|
test "public api symbols are exported" {
  ignore(@terminal_size.Width::to_int)
  ignore(@terminal_size.Height::to_int)
  ignore(@terminal_size.terminal_size)
}

///|
test "terminal_size returns either a valid size or none" {
  match @terminal_size.terminal_size() {
    Some((width, height)) => {
      assert_true(width.to_int() > 0)
      assert_true(height.to_int() > 0)
    }
    None => ()
  }
}
