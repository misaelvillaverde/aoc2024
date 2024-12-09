// too slow (20 seconds)
// can be sped up by keeping a copy of the reversed blocks
// can be further sped up by virtually reading each last pointer in place of each free space instead of moving memory around (two pointers)
import file_streams/file_stream
import gleam/bool
import gleam/int
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
  get_blocks(stream)
  |> compress([])
  |> checksum(0, 0)
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

fn compress(blocks: Blocks, result: Blocks) -> Blocks {
  case blocks {
    [block, ..rest] ->
      case block {
        ID(n) -> {
          let result = list.append(result, [ID(n)])
          compress(rest, result)
        }
        Free -> {
          case
            list.reverse(rest)
            |> list.fold_until(#(0, 0), fn(acc, b) {
              case b {
                Free -> list.Continue(#(acc.0 + 1, 0))
                ID(n) -> list.Stop(#(acc.0, n))
              }
            })
          {
            #(to_remove, last) -> {
              let result = list.append(result, [ID(last)])
              let blocks = list.take(rest, list.length(rest) - 1 - to_remove)
              compress(blocks, result)
            }
          }
        }
      }

    [] -> result
  }
}

fn checksum(blocks: Blocks, acc: Int, index: Int) -> Int {
  case blocks {
    [block, ..rest] ->
      case block {
        ID(n) -> checksum(rest, acc + n * index, index + 1)
        Free -> acc
      }
    [] -> acc
  }
}
