import file_streams/file_stream
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string

type Point {
  Point(row: Int, col: Int)
}

type Direction {
  Up
  Down
  Left
  Right
}

type Entity {
  Wall
  Empty
}

type Guard {
  Guard(point: Point, dir: Direction)
}

type Map =
  dict.Dict(Point, Entity)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day6/1")
  let #(map, guard, row_amount, col_amount) =
    load_map(stream, dict.new(), None, 0, 0)
  escape(map, guard, set.new(), row_amount, col_amount)
}

fn load_map(
  stream,
  map: Map,
  guard: Option(Guard),
  row: Int,
  col_amount: Int,
) -> #(Map, Guard, Int, Int) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let line = string.drop_end(line, 1)
      let #(map, guard) =
        string.split(line, "")
        |> list.index_fold(#(map, guard), fn(acc, char, col) {
          let entity = case char {
            "#" -> Wall
            "." | _ -> Empty
          }

          let point = Point(row, col)
          let guard = case char {
            "^" -> Some(Guard(point, Up))
            ">" -> Some(Guard(point, Right))
            "v" -> Some(Guard(point, Down))
            "<" -> Some(Guard(point, Left))
            _ -> acc.1
          }

          #(dict.insert(acc.0, Point(row, col), entity), guard)
        })

      load_map(stream, map, guard, row + 1, string.length(line))
    }
    Error(_) -> #(
      map,
      option.unwrap(guard, Guard(Point(0, 0), Up)),
      row,
      col_amount,
    )
  }
}

fn escape(
  map: Map,
  guard: Guard,
  visited: set.Set(Point),
  row_amount: Int,
  col_amount: Int,
) -> Int {
  case guard {
    Guard(point, _) -> {
      case out_of_bounds(point, row_amount, col_amount) {
        True -> {
          set.size(visited)
        }
        False -> {
          let guard = move(guard, map)
          let visited = set.insert(visited, point)
          escape(map, guard, visited, row_amount, col_amount)
        }
      }
    }
  }
}

fn move(guard: Guard, map: Map) -> Guard {
  case guard {
    Guard(point, direction) -> {
      let next_pos = lookup(point, direction)
      let entity =
        dict.get(map, next_pos)
        |> result.unwrap(Empty)
      case entity {
        Wall -> rotate(guard)
        Empty -> Guard(next_pos, direction)
      }
    }
  }
}

fn lookup(point: Point, direction: Direction) -> Point {
  case direction, point {
    Up, Point(row, col) -> Point(row - 1, col)
    Down, Point(row, col) -> Point(row + 1, col)
    Right, Point(row, col) -> Point(row, col + 1)
    Left, Point(row, col) -> Point(row, col - 1)
  }
}

fn rotate(guard: Guard) -> Guard {
  case guard {
    Guard(pos, dir) -> {
      case dir {
        Up -> Guard(pos, Right)
        Right -> Guard(pos, Down)
        Down -> Guard(pos, Left)
        Left -> Guard(pos, Up)
      }
    }
  }
}

fn out_of_bounds(point: Point, row_amount: Int, col_amount: Int) -> Bool {
  case point {
    Point(row, col) ->
      row < 0 || row >= row_amount || col < 0 || col >= col_amount
  }
}
