import file_streams/file_stream
import gleam/dict
import gleam/int
import gleam/list
import gleam/string

type Direction {
  Up
  Right
  Left
  Down
  UpRight
  UpLeft
  DownRight
  DownLeft
}

type Coord {
  Coord(x: Int, y: Int)
}

type Map =
  dict.Dict(Coord, String)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day4/1")
  fill_map(stream, dict.new(), 0)
  |> traverse
}

fn traverse(map: Map) -> Int {
  map
  |> dict.fold(0, fn(acc, k, v) {
    case v {
      "X" -> {
        list.range(0, 7)
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
        True if step == 3 -> True
        True -> xmas(map, direction, step + 1, forward(coord, direction))
        False -> False
      }
    _ -> False
  }
}

fn forward(coord: Coord, direction: Direction) -> Coord {
  case direction {
    Up -> Coord(coord.x - 1, coord.y)
    UpRight -> Coord(coord.x - 1, coord.y + 1)
    UpLeft -> Coord(coord.x - 1, coord.y - 1)
    Down -> Coord(coord.x + 1, coord.y)
    DownRight -> Coord(coord.x + 1, coord.y + 1)
    DownLeft -> Coord(coord.x + 1, coord.y - 1)
    Right -> Coord(coord.x, coord.y + 1)
    Left -> Coord(coord.x, coord.y - 1)
  }
}

fn get_direction(index: Int) -> Direction {
  case index {
    0 -> Up
    1 -> UpRight
    2 -> UpLeft
    3 -> Down
    4 -> DownRight
    5 -> DownLeft
    6 -> Right
    _ -> Left
  }
}

fn get_letter_at(step step: Int) -> String {
  case step {
    0 -> "X"
    1 -> "M"
    2 -> "A"
    3 -> "S"
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
