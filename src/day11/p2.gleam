import file_streams/file_stream
import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import rememo/memo.{memoize}

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day11")
  let assert Ok(line) = file_stream.read_line(stream)

  use cache <- memo.create()

  line
  |> string.drop_end(1)
  |> string.split(" ")
  |> list.map(stoi)
  |> list.map(blink(_, 75, cache))
  |> int.sum
}

fn blink(stone: Int, times: Int, cache) -> Int {
  use <- memoize(cache, #(stone, times))
  use <- bool.guard(times == 0, 1)
  case stone {
    0 -> blink(1, times - 1, cache)
    _ -> {
      let digits = int.to_string(stone)
      let length = string.length(digits)
      case int.is_even(length) {
        True -> {
          let left = stoi(string.drop_end(digits, length / 2))
          let right = stoi(string.drop_start(digits, length / 2))
          blink(left, times - 1, cache) + blink(right, times - 1, cache)
        }
        False -> blink(stone * 2024, times - 1, cache)
      }
    }
  }
}

fn stoi(s: String) -> Int {
  int.parse(s) |> result.unwrap(0)
}
