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
  escape(map, guard, set.new(), set.new(), row_amount, col_amount)
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
  visited: VisitedMap,
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
        could_add_obstacle(
          guard,
          map,
          visited,
          placed_obstacles,
          row_amount,
          col_amount,
        )
      let guard = move(guard, map)
      let visited = set.insert(visited, #(guard.point, guard.dir))

      escape(map, guard, visited, placed_obstacles, row_amount, col_amount)
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
  visited: VisitedMap,
  placed_obstacles: PlacedObstacles,
  row_amount,
  col_amount,
) -> PlacedObstacles {
  let Guard(point, dir) = ghost
  io.debug(#(point, dir))
  case set.contains(placed_obstacles, point) {
    True -> placed_obstacles
    False ->
      case both_empty(point, dir, map) {
        True ->
          case
            // move the guard forward and rotate ('cause of the obstacle)
            move(ghost, map)
            |> rotate
            |> loop_lookup(map, visited, row_amount, col_amount)
          {
            True -> {
              // let placed_at =
              //   lookup(point, dir)
              //   |> lookup(dir)
              // io.debug("placed at: " <> string.inspect(placed_at))
              set.insert(placed_obstacles, point)
            }
            False -> placed_obstacles
          }
        False -> placed_obstacles
      }
  }
}

// check there is no obstacle in both next forward positions
fn both_empty(point: Point, dir: Direction, map: Map) -> Bool {
  case
    lookup(point, dir)
    |> dict.get(map, _)
  {
    Ok(entity) ->
      case entity {
        Empty ->
          case lookup(point, dir) |> lookup(dir) |> dict.get(map, _) {
            Ok(entity) -> {
              case entity {
                Empty -> True
                _ -> False
              }
            }
            _ -> False
          }
        _ -> False
      }

    _ -> False
  }
}

fn loop_lookup(
  ghost: Guard,
  map: Map,
  visited: VisitedMap,
  row_amount: Int,
  col_amount: Int,
) -> Bool {
  io.debug(ghost)
  case out_of_bounds(ghost.point, row_amount, col_amount) {
    True -> False
    False ->
      case set.contains(visited, #(ghost.point, ghost.dir)) {
        True -> True
        False -> {
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
