import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/2_2")
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

      case generate(numbers) {
        True -> {
          read(stream, acc + 1)
        }
        False -> read(stream, acc)
      }
    }
    Error(_) -> {
      Ok(acc)
    }
  }
}

pub fn list_to_string(numbers: List(Int)) -> String {
  numbers
  |> list.map(fn(i) { int.to_string(i) })
  |> string.join(" ")
}

fn generate(numbers: List(Int)) -> Bool {
  case validate_sequence(numbers, None) {
    True -> {
      True
    }
    False -> {
      list.range(0, list.length(numbers) - 1)
      |> list.any(fn(i) {
        let new_seq =
          list.take(numbers, i)
          |> list.append(list.drop(numbers, i + 1))

        let res = validate_sequence(new_seq, None)

        res
      })
    }
  }
}

fn validate_sequence(numbers: List(Int), direction: Option(Direction)) -> Bool {
  case numbers {
    [prev, curr, ..rest] -> {
      let diff = int.absolute_value(curr - prev)

      case diff {
        1 | 2 | 3 -> {
          let assert Ok(cur_dir) = case int.compare(curr, prev) {
            order.Lt -> Ok(Descending)
            order.Gt -> Ok(Ascending)
            order.Eq -> Error("-")
          }

          case direction {
            Some(direction) if cur_dir != direction -> False
            Some(_) | None -> validate_sequence([curr, ..rest], Some(cur_dir))
          }
        }
        _ -> False
      }
    }
    _ -> True
  }
}
