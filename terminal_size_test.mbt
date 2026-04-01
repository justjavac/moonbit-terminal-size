///|
test "public api symbols are exported" {
  let _ : @terminal_size.Size? = None
  ignore(@terminal_size.terminal_size)
}

///|
test "terminal_size returns either a valid size or none" {
  match @terminal_size.terminal_size() {
    Some(size) => {
      assert_true(size.columns > 0)
      assert_true(size.rows > 0)
    }
    None => ()
  }
}
