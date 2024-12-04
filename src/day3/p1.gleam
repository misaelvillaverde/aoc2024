import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/3_1")
  result.unwrap(read(stream, 0), 0)
}

fn find(text: List(String), acc: Int) -> Int {
  case text {
    ["m", "u", "l", "(", ..rest] -> {
      let mul = {
        let #(a_side, rest) = list.split_while(rest, fn(c) { c != "," })
        let #(_, rest) = list.split(rest, 1)
        let to_a =
          a_side
          |> string.join("")
          |> int.parse()

        use a <- result.try(to_a)

        let #(b_side, rest) = list.split_while(rest, fn(c) { c != ")" })
        let to_b =
          b_side
          |> string.join("")
          |> int.parse()

        use b <- result.map(to_b)

        #(a * b, rest)
      }

      case mul {
        Ok(mul) -> {
          acc + mul.0
          |> find(mul.1, _)
        }
        Error(_) -> find(rest, acc)
      }
    }
    [_, ..rest] -> find(rest, acc)
    [] -> acc
  }
}

fn read(stream: file_stream.FileStream, acc: Int) -> Result(Int, String) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      acc + find(string.to_graphemes(line), 0)
      |> read(stream, _)
    }
    Error(_) -> {
      Ok(acc)
    }
  }
}
