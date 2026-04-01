///|
/// Builds a native probe payload for white-box tests.
fn probe_payload(width : Int, height : Int) -> Bytes {
  [
    Int::to_byte(width / 256),
    Int::to_byte(width % 256),
    Int::to_byte(height / 256),
    Int::to_byte(height % 256),
  ]
}

///|
test "decode_u16 reconstructs the original value" {
  assert_eq(decode_u16(Int::to_byte(0), Int::to_byte(0)), 0)
  assert_eq(decode_u16(Int::to_byte(0), Int::to_byte(80)), 80)
  assert_eq(decode_u16(Int::to_byte(1), Int::to_byte(44)), 300)
}

///|
test "decode_probe_bytes rejects malformed payloads" {
  assert_eq(decode_probe_bytes([]), None)
  assert_eq(decode_probe_bytes([0, 80, 0]), None)
  assert_eq(decode_probe_bytes([0, 0, 0, 24]), None)
  assert_eq(decode_probe_bytes([0, 80, 0, 0]), None)
}

///|
test "decode_probe_bytes decodes valid sizes" {
  assert_eq(
    decode_probe_bytes(probe_payload(80, 24)),
    Some({ columns: 80, rows: 24 }),
  )
  assert_eq(
    decode_probe_bytes(probe_payload(240, 60)),
    Some({ columns: 240, rows: 60 }),
  )
}

///|
test "terminal_size_of_stream decodes one probe result" {
  let calls : Array[Int] = []
  assert_eq(
    terminal_size_of_stream(stdout_stream_kind, kind => {
      calls.push(kind)
      probe_payload(100, 40)
    }),
    Some({ columns: 100, rows: 40 }),
  )
  assert_eq(calls, [stdout_stream_kind])
}

///|
test "terminal_size_with prefers stdout over later streams" {
  let calls : Array[Int] = []
  let result = terminal_size_with(kind => {
    calls.push(kind)
    match kind {
      0 => probe_payload(90, 30)
      _ => []
    }
  })

  assert_eq(result, Some({ columns: 90, rows: 30 }))
  assert_eq(calls, [stdout_stream_kind])
}

///|
test "terminal_size_with falls back from stdout to stderr" {
  let calls : Array[Int] = []
  let result = terminal_size_with(kind => {
    calls.push(kind)
    match kind {
      0 => []
      1 => probe_payload(120, 33)
      _ => []
    }
  })

  assert_eq(result, Some({ columns: 120, rows: 33 }))
  assert_eq(calls, [stdout_stream_kind, stderr_stream_kind])
}

///|
test "terminal_size_with falls back to stdin when needed" {
  let calls : Array[Int] = []
  let result = terminal_size_with(kind => {
    calls.push(kind)
    match kind {
      2 => probe_payload(132, 43)
      _ => []
    }
  })

  assert_eq(result, Some({ columns: 132, rows: 43 }))
  assert_eq(calls, [stdout_stream_kind, stderr_stream_kind, stdin_stream_kind])
}

///|
test "terminal_size_with returns none when all probes fail" {
  let calls : Array[Int] = []
  let result = terminal_size_with(kind => {
    calls.push(kind)
    []
  })

  assert_eq(result, None)
  assert_eq(calls, [stdout_stream_kind, stderr_stream_kind, stdin_stream_kind])
}
