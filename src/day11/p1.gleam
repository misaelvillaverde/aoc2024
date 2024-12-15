import file_streams/file_stream
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string

type Stones =
  List(Int)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day11")
  let assert Ok(line) = file_stream.read_line(stream)
  let line = string.drop_end(line, 1)

  let stones =
    string.split(line, " ")
    |> list.map(stoi)

  blink(stones, 25)
}

fn blink(stones: Stones, times: Int) -> Int {
  use <- bool.guard(times == 0, list.length(stones))

  stones
  |> list.flat_map(fn(x) { convert(x) })
  |> blink(times - 1)
}

fn convert(stone: Int) -> List(Int) {
  case stone {
    0 -> [1]
    _ -> {
      let digits = int.to_string(stone)
      let length = string.length(digits)
      case int.is_even(length) {
        True -> {
          let right = stoi(string.drop_start(digits, length / 2))
          let left = stoi(string.drop_end(digits, length / 2))

          [left, right]
        }
        False -> [stone * 2024]
      }
    }
  }
}

fn stoi(s: String) -> Int {
  int.parse(s) |> result.unwrap(0)
}
