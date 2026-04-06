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
/// Runs `terminal_size_with` while recording which streams were probed.
fn traced_terminal_size_with(
  calls : Array[Int],
  probe : (Int) -> Bytes,
) -> Size? {
  terminal_size_with(kind => {
    calls.push(kind)
    probe(kind)
  })
}

///|
/// Builds a probe that succeeds for one stream kind and fails for the others.
fn probe_that_succeeds_on(
  stream_kind : Int,
  width : Int,
  height : Int,
) -> (Int) -> Bytes {
  kind => if kind == stream_kind { probe_payload(width, height) } else { [] }
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
  let result = traced_terminal_size_with(
    calls,
    probe_that_succeeds_on(stdout_stream_kind, 90, 30),
  )

  assert_eq(result, Some({ columns: 90, rows: 30 }))
  assert_eq(calls, [stdout_stream_kind])
}

///|
test "terminal_size_with falls back from stdout to stderr" {
  let calls : Array[Int] = []
  let result = traced_terminal_size_with(
    calls,
    probe_that_succeeds_on(stderr_stream_kind, 120, 33),
  )

  assert_eq(result, Some({ columns: 120, rows: 33 }))
  assert_eq(calls, [stdout_stream_kind, stderr_stream_kind])
}

///|
test "terminal_size_with falls back to stdin when needed" {
  let calls : Array[Int] = []
  let result = traced_terminal_size_with(
    calls,
    probe_that_succeeds_on(stdin_stream_kind, 132, 43),
  )

  assert_eq(result, Some({ columns: 132, rows: 43 }))
  assert_eq(calls, standard_stream_kinds)
}

///|
test "terminal_size_with returns none when all probes fail" {
  let calls : Array[Int] = []
  let result = traced_terminal_size_with(calls, _ => [])

  assert_eq(result, None)
  assert_eq(calls, standard_stream_kinds)
}
