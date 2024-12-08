/// Doesn't work (number too high)
import file_streams/file_stream
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
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
  let #(map, guard) = load_map(stream, dict.new(), None, 0)
  let initial_point = guard.point
  escape(map, Some(guard), initial_point, 0, set.new())
}

fn load_map(stream, map: Map, guard: Option(Guard), row: Int) -> #(Map, Guard) {
  case file_stream.read_line(stream) {
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

          #(dict.insert(acc.0, point, entity), guard)
        })

      load_map(stream, map, guard, row + 1)
    }
    Error(_) -> #(map, option.unwrap(guard, Guard(Point(0, 0), Up)))
  }
}

fn escape(
  map: Map,
  guard: Option(Guard),
  initial_point: Point,
  acc: Int,
  checked: set.Set(Point),
) -> Int {
  case guard {
    None -> acc
    Some(guard) -> {
      let next_pos = lookup(guard.point, guard.dir)
      let next_checked = set.contains(checked, next_pos)

      let #(acc, checked) = case dict.get(map, next_pos) {
        Ok(entity) if next_pos != initial_point && !next_checked ->
          case entity {
            Empty -> {
              let checked = set.insert(checked, next_pos)
              case
                detect_loop(
                  Some(guard),
                  dict.insert(map, next_pos, Wall),
                  set.new(),
                )
              {
                True -> #(acc + 1, checked)
                False -> #(acc, checked)
              }
            }
            Wall -> #(acc, checked)
          }
        _ -> #(acc, checked)
      }

      let guard = move(guard, map)
      escape(map, guard, initial_point, acc, checked)
    }
  }
}

fn detect_loop(
  guard: Option(Guard),
  map,
  visited: set.Set(#(Point, Direction)),
) -> Bool {
  case guard {
    None -> False
    Some(guard) -> {
      case set.contains(visited, #(guard.point, guard.dir)) {
        True -> True
        False -> {
          let visited = set.insert(visited, #(guard.point, guard.dir))
          move(guard, map)
          |> detect_loop(map, visited)
        }
      }
    }
  }
}

fn move(guard: Guard, map: Map) -> Option(Guard) {
  let next_pos = lookup(guard.point, guard.dir)
  let entity = dict.get(map, next_pos)
  case entity {
    Ok(Wall) -> Some(rotate(guard))
    Ok(Empty) -> Some(Guard(next_pos, guard.dir))
    Error(_) -> None
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
  let Guard(pos, dir) = guard
  case dir {
    Up -> Guard(pos, Right)
    Right -> Guard(pos, Down)
    Down -> Guard(pos, Left)
    Left -> Guard(pos, Up)
  }
}
