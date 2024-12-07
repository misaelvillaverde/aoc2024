import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let left = []
  let right = []

  let assert Ok(stream) = file_stream.open_read("input/day1/1")

  result.unwrap(read(stream, left, right), 0)
}

type ReadError {
  ShouldntReach
}

fn read(
  stream: file_stream.FileStream,
  left: List(Int),
  right: List(Int),
) -> Result(Int, ReadError) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let numbers = string.drop_end(line, 1) |> string.split("   ")

      case numbers {
        [n1, n2] -> {
          let assert Ok(a) = int.parse(n1)
          let assert Ok(b) = int.parse(n2)

          let left = list.append(left, [a])
          let right = list.append(right, [b])

          read(stream, left, right)
        }
        [] -> Error(ShouldntReach)
        [_, _, _, ..] -> Error(ShouldntReach)
        [_] -> Error(ShouldntReach)
      }
    }
    Error(_) -> {
      let left = list.sort(left, int.compare)
      let right = list.sort(right, int.compare)
      Ok(sum(0, left, right))
    }
  }
}

fn sum(acc: Int, left: List(Int), right: List(Int)) -> Int {
  case left, right {
    [a, ..l], [b, ..r] -> {
      int.absolute_value(a - b)
      |> int.add(acc)
      |> sum(l, r)
    }
    _, _ -> acc
  }
}
