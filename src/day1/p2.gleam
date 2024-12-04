import file_streams/file_stream
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let left = []
  let right = dict.new()

  let assert Ok(stream) = file_stream.open_read("input/1_2")

  result.unwrap(read(stream, left, right), 0)
}

type ReadError {
  ShouldntReach
}

fn read(
  stream: file_stream.FileStream,
  left: List(Int),
  right: dict.Dict(Int, Int),
) -> Result(Int, ReadError) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let numbers =
        line
        |> string.drop_end(1)
        |> string.split("   ")

      case numbers {
        [n1, n2] -> {
          let assert Ok(a) = int.parse(n1)
          let assert Ok(b) = int.parse(n2)

          let left = list.append(left, [a])
          let right =
            right
            |> dict.get(b)
            |> result.unwrap(0)
            |> int.add(1)
            |> dict.insert(right, b, _)

          read(stream, left, right)
        }
        _ -> Error(ShouldntReach)
      }
    }
    Error(_) -> {
      Ok(simmilarity(left, right, 0))
    }
  }
}

fn simmilarity(left: List(Int), right: dict.Dict(Int, Int), acc: Int) -> Int {
  case left {
    [a, ..l] -> {
      right
      |> dict.get(a)
      |> result.unwrap(0)
      |> int.multiply(a)
      |> int.add(acc)
      |> simmilarity(l, right, _)
    }
    [] -> acc
  }
}
