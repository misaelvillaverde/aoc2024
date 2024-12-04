import file_streams/file_stream
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string

type Direction {
  UpRight
  UpLeft
  DownRight
  DownLeft
}

type Coord {
  // x: row, y: col
  Coord(x: Int, y: Int)
}

type Map =
  dict.Dict(Coord, String)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day4/2")
  fill_map(stream, dict.new(), 0)
  |> traverse
  |> int.divide(2)
  |> result.unwrap(0)
}

fn traverse(map: Map) -> Int {
  map
  |> dict.fold(0, fn(acc, k, v) {
    case v {
      "M" -> {
        list.range(0, 3)
        |> list.fold(0, fn(acc, item) {
          case xmas(map, get_direction(item), 0, k) {
            True -> acc + 1
            False -> acc
          }
        })
        |> int.add(acc)
      }
      _ -> acc
    }
  })
}

fn xmas(map: Map, direction: Direction, step: Int, coord: Coord) -> Bool {
  case dict.get(map, coord) {
    Ok(char) ->
      case char == get_letter_at(step) {
        True if step == 2 -> conjugate(map, direction, coord)
        True -> xmas(map, direction, step + 1, forward(coord, direction))
        False -> False
      }
    _ -> False
  }
}

// e.g. when direction is DownRight, search at row - 2 and col - 2 to see if they are 'M' and 'S'
fn conjugate(map: Map, direction: Direction, coord: Coord) -> Bool {
  let offset = case direction {
    UpRight -> #(2, -2)
    UpLeft -> #(2, 2)
    DownRight -> #(-2, -2)
    DownLeft -> #(-2, 2)
  }

  case
    dict.get(map, Coord(coord.x + offset.0, coord.y)),
    dict.get(map, Coord(coord.x, coord.y + offset.1))
  {
    Ok("M"), Ok("S") | Ok("S"), Ok("M") -> True
    _, _ -> False
  }
}

fn forward(coord: Coord, direction: Direction) -> Coord {
  case direction {
    UpRight -> Coord(coord.x - 1, coord.y + 1)
    UpLeft -> Coord(coord.x - 1, coord.y - 1)
    DownRight -> Coord(coord.x + 1, coord.y + 1)
    DownLeft -> Coord(coord.x + 1, coord.y - 1)
  }
}

fn get_direction(index: Int) -> Direction {
  case index {
    0 -> UpRight
    1 -> UpLeft
    2 -> DownRight
    _ -> DownLeft
  }
}

fn get_letter_at(step step: Int) -> String {
  case step {
    0 -> "M"
    1 -> "A"
    2 -> "S"
    _ -> "."
  }
}

fn fill_map(stream: file_stream.FileStream, map: Map, row: Int) -> Map {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      string.to_graphemes(line)
      |> list.index_fold(map, fn(acc, item, index) {
        acc
        |> dict.insert(Coord(row, index), item)
      })
      |> fill_map(stream, _, row + 1)
    }
    Error(_) -> map
  }
}
