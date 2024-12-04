import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/2_1")

  result.unwrap(read(stream, 0), 0)
}

type Direction {
  Ascending
  Descending
}

fn read(stream: file_stream.FileStream, acc: Int) -> Result(Int, String) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let numbers =
        line
        |> string.drop_end(1)
        |> string.split(" ")
        |> list.map(fn(i) { result.unwrap(int.parse(i), 0) })

      let assert Ok(#(prev, numbers)) = case numbers {
        [prev, ..numbers] -> Ok(#(prev, numbers))
        _ -> Error("Shouldn't reach.")
      }

      case fold(numbers, prev, None) {
        Ok(True) -> read(stream, acc + 1)
        Ok(False) -> read(stream, acc)
        Error(_) -> {
          read(stream, acc)
        }
      }
    }
    Error(_) -> {
      Ok(acc)
    }
  }
}

fn fold(
  numbers: List(Int),
  prev: Int,
  direction: Option(Direction),
) -> Result(Bool, String) {
  case numbers {
    [n, ..rest] -> {
      let res = int.absolute_value(n - prev)

      case res {
        1 | 2 | 3 -> {
          let new_dir = case int.compare(n, prev) {
            order.Lt -> Ok(Descending)
            order.Gt -> Ok(Ascending)
            order.Eq -> Error("Distance is zero.")
          }

          case direction, new_dir {
            Some(direction), Ok(new_dir) if direction != new_dir -> Ok(False)
            _, Ok(new_dir) -> fold(rest, n, Some(new_dir))
            _, Error(e) -> Error(e)
          }
        }
        _ -> Error("Distance is not allowed.")
      }
    }
    [] -> Ok(True)
  }
}
