import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/3_2")
  result.unwrap(read(stream, 0, False), 0)
}

fn find(text: List(String), acc: Int, disabled: Bool) -> #(Int, Bool) {
  case text {
    ["m", "u", "l", "(", ..rest] if !disabled -> {
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
          |> find(mul.1, _, disabled)
        }
        Error(_) -> find(rest, acc, disabled)
      }
    }
    ["d", "o", "n", "'", "t", "(", ")", ..rest] -> find(rest, acc, True)
    ["d", "o", "(", ")", ..rest] -> find(rest, acc, False)
    [_, ..rest] -> find(rest, acc, disabled)
    [] -> #(acc, disabled)
  }
}

fn read(
  stream: file_stream.FileStream,
  acc: Int,
  disabled: Bool,
) -> Result(Int, String) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let res = find(string.to_graphemes(line), 0, disabled)
      read(stream, res.0 + acc, res.1)
    }
    Error(_) -> {
      Ok(acc)
    }
  }
}
