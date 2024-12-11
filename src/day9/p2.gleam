import file_streams/file_stream
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Block {
  ID(Int)
  Free
}

type Blocks =
  List(Block)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day9/1")
  let blocks = get_blocks(stream)
  print_blocks("", blocks)

  let blocks = compress(blocks, list.reverse(blocks), blocks)
  print_blocks("", blocks)
  checksum(blocks, 0, 0)
}

fn get_blocks(stream: file_stream.FileStream) -> Blocks {
  let assert Ok(line) = file_stream.read_line(stream)
  let blocks =
    string.drop_end(line, 1)
    |> string.split("")
    |> list.map(fn(i) { result.unwrap(int.parse(i), 0) })
    |> list.index_fold([], fn(acc, n, index) {
      use <- bool.guard(n == 0, acc)
      list.range(0, n - 1)
      |> list.map(fn(_) {
        case int.is_even(index) {
          True -> {
            ID(index / 2)
          }
          False -> {
            Free
          }
        }
      })
      |> list.append(acc, _)
    })
  blocks
}

type SlotRange {
  SlotRange(started: Bool, started_at_num: Bool, a: Int, b: Int)
}

fn compress(blocks: Blocks, reverse: Blocks, result: Blocks) -> Blocks {
  case reverse {
    [a, ..rest] ->
      case a {
        ID(a) ->
          case
            rest
            |> list.fold_until(0, fn(acc, b) {
              case b {
                Free -> list.Stop(acc)
                ID(n) if n != a -> list.Stop(acc)
                ID(_) -> list.Continue(acc + 1)
              }
            })
          {
            to_remove -> {
              let rest = list.drop(rest, to_remove)

              // [a, b)
              let range =
                list.fold_until(
                  blocks,
                  SlotRange(started: False, started_at_num: False, a: 0, b: 0),
                  fn(acc, block) {
                    use <- bool.guard(
                      acc.b - acc.a == to_remove + 1,
                      list.Stop(SlotRange(
                        started: acc.started,
                        started_at_num: acc.started_at_num,
                        a: acc.a,
                        b: acc.b,
                      )),
                    )

                    case block {
                      Free if !acc.started_at_num -> {
                        case acc.started {
                          True ->
                            list.Continue(SlotRange(
                              started: acc.started,
                              started_at_num: acc.started_at_num,
                              a: acc.a,
                              b: acc.b + 1,
                            ))
                          False ->
                            list.Continue(SlotRange(
                              started: True,
                              started_at_num: False,
                              a: acc.a,
                              b: acc.a + 1,
                            ))
                        }
                      }
                      ID(n)
                        if a == n
                        && { acc.started && acc.started_at_num || !acc.started }
                      -> {
                        case acc.started {
                          True ->
                            list.Continue(SlotRange(
                              started: acc.started,
                              started_at_num: True,
                              a: acc.a,
                              b: acc.b + 1,
                            ))
                          False ->
                            list.Continue(SlotRange(
                              started: True,
                              started_at_num: True,
                              a: acc.a,
                              b: acc.a + 1,
                            ))
                        }
                      }
                      _ -> {
                        list.Continue(SlotRange(
                          started: False,
                          started_at_num: False,
                          a: acc.b + 1,
                          b: acc.b + 1,
                        ))
                      }
                    }
                  },
                )

              // io.debug(#(a, range))

              case range {
                SlotRange(_, _, x, y) -> {
                  case int.absolute_value(x - y) <= 0 {
                    True -> compress(blocks, rest, result)
                    False -> {
                      let blocks =
                        list.index_map(blocks, fn(block, i) {
                          case i >= range.a && i < range.b {
                            True -> ID(a)
                            False -> block
                          }
                        })

                      let result =
                        list.index_map(result, fn(block, i) {
                          case i >= range.a && i < range.b {
                            True -> ID(a)
                            False ->
                              case block {
                                ID(v) if a == v -> Free
                                _ -> block
                              }
                          }
                        })

                      compress(blocks, rest, result)
                    }
                  }
                }
              }
            }
          }
        Free -> compress(blocks, rest, result)
      }
    [] -> result
  }
}

fn checksum(blocks: Blocks, acc: Int, index: Int) -> Int {
  case blocks {
    [block, ..rest] ->
      case block {
        ID(n) -> checksum(rest, acc + n * index, index + 1)
        Free -> checksum(rest, acc, index + 1)
      }
    [] -> acc
  }
}

fn print_blocks(acc: String, blocks: Blocks) {
  case blocks {
    [block, ..rest] ->
      case block {
        ID(n) -> print_blocks(acc <> string.inspect(n), rest)
        Free -> print_blocks(acc <> ".", rest)
      }
    _ -> io.debug(acc)
  }
}
