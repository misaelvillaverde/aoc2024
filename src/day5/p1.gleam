import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import gleam/string

type Pair {
  Pair(Int, Int)
}

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day5/1")
  extract_pairs(stream, set.new())
  |> updates(stream, _, 0)
}

fn extract_pairs(stream, logic: set.Set(Pair)) -> set.Set(Pair) {
  let line = file_stream.read_line(stream)
  case line {
    Ok("\n") -> logic
    Ok(line) -> {
      let line = string.drop_end(line, 1)
      let assert [a, b] =
        string.split(line, "|")
        |> list.map(fn(n) { int.parse(n) |> result.unwrap(0) })

      set.insert(logic, Pair(a, b))
      |> extract_pairs(stream, _)
    }
    Error(_) -> logic
  }
}

fn sort(l: List(Int), logic: set.Set(Pair)) {
  list.sort(l, fn(a, b) {
    case set.contains(logic, Pair(a, b)) {
      True -> order.Lt
      False -> order.Gt
    }
  })
}

fn are_equal(a: List(Int), b: List(Int), acc: Bool) -> Bool {
  case acc {
    False -> False
    _ ->
      case a, b {
        [x, ..resta], [y, ..restb] -> {
          are_equal(resta, restb, x == y)
        }
        [], [] -> True
        _, _ -> False
      }
  }
}

fn updates(stream, logic: set.Set(Pair), acc: Int) -> Int {
  let line = file_stream.read_line(stream)
  case line {
    Ok("\n") -> acc
    Ok(line) -> {
      let line = string.drop_end(line, 1)
      let coming =
        string.split(line, ",")
        |> list.map(fn(n) { int.parse(n) |> result.unwrap(0) })

      let sorted = sort(coming, logic)
      let middle =
        { list.length(sorted) + 1 } / 2
        |> list.take(sorted, _)
        |> list.last

      case are_equal(sorted, coming, True) {
        True -> {
          acc + result.unwrap(middle, 0)
          |> updates(stream, logic, _)
        }
        False -> {
          updates(stream, logic, acc)
        }
      }
    }
    Error(_) -> acc
  }
}
