/// Doesn't work (number too high)
import file_streams/file_stream
import gleam/dict
import gleam/io
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

// includes direction to check for loop paths
type VisitedMap =
  set.Set(#(Point, Direction))

type PlacedObstacles =
  set.Set(Point)

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

          #(dict.insert(acc.0, point, entity), guard)
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
  placed_obstacles: PlacedObstacles,
  row_amount: Int,
  col_amount: Int,
) -> Int {
  case out_of_bounds(guard.point, row_amount, col_amount) {
    True -> {
      set.size(placed_obstacles)
    }
    False -> {
      let placed_obstacles =
        could_add_obstacle(guard, map, placed_obstacles, row_amount, col_amount)
      let guard = move(guard, map)

      escape(map, guard, placed_obstacles, row_amount, col_amount)
    }
  }
}

fn move(guard: Guard, map: Map) -> Guard {
  let next_pos = lookup(guard.point, guard.dir)
  let entity =
    dict.get(map, next_pos)
    |> result.unwrap(Empty)
  case entity {
    Wall -> rotate(guard)
    Empty -> Guard(next_pos, guard.dir)
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

fn could_add_obstacle(
  ghost: Guard,
  map: Map,
  placed_obstacles: PlacedObstacles,
  row_amount,
  col_amount,
) -> PlacedObstacles {
  let Guard(point, dir) = ghost
  let next_pos = lookup(point, dir)
  case out_of_bounds(next_pos, row_amount, col_amount) {
    False ->
      case set.contains(placed_obstacles, next_pos) {
        True -> placed_obstacles
        False ->
          case dict.get(map, next_pos) {
            Ok(entity) ->
              case entity {
                Empty ->
                  case
                    loop_lookup(
                      ghost,
                      map |> dict.insert(next_pos, Wall),
                      set.new(),
                      row_amount,
                      col_amount,
                    )
                  {
                    True -> {
                      let placed_at = next_pos
                      io.debug(
                        "was at: "
                        <> string.inspect(ghost)
                        <> " placed at: "
                        <> string.inspect(placed_at),
                      )
                      set.insert(placed_obstacles, placed_at)
                    }
                    False -> placed_obstacles
                  }
                Wall -> placed_obstacles
              }
            Error(_) -> placed_obstacles
          }
      }
    True -> placed_obstacles
  }
}

fn loop_lookup(
  ghost: Guard,
  map: Map,
  visited: VisitedMap,
  row_amount: Int,
  col_amount: Int,
) -> Bool {
  case out_of_bounds(ghost.point, row_amount, col_amount) {
    True -> False
    False ->
      case set.contains(visited, #(ghost.point, ghost.dir)) {
        True -> {
          // io.debug(
          //   "visited: "
          //   <> string.inspect(set.size(visited))
          //   <> string.inspect(#(ghost.point, ghost.dir)),
          // )
          True
        }
        False -> {
          let visited = set.insert(visited, #(ghost.point, ghost.dir))
          move(ghost, map)
          |> loop_lookup(map, visited, row_amount, col_amount)
        }
      }
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

fn out_of_bounds(point: Point, row_amount: Int, col_amount: Int) -> Bool {
  case point {
    Point(row, col) ->
      row < 0 || row >= row_amount || col < 0 || col >= col_amount
  }
}
