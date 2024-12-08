import file_streams/file_stream
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string

type Point {
  Point(row: Int, col: Int)
}

type AntenaPositions =
  dict.Dict(String, List(Point))

type Antinodes =
  set.Set(Point)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day8/1")
  let #(antenas, rows, cols) = load_map(stream, dict.new(), 0, 0)

  antenas
  |> dict.to_list
  |> load_antinodes(set.new(), rows, cols)
  |> set.size
}

fn load_map(
  stream,
  map: AntenaPositions,
  row: Int,
  cols: Int,
) -> #(AntenaPositions, Int, Int) {
  let line = file_stream.read_line(stream)
  case line {
    Ok(line) -> {
      let line = string.drop_end(line, 1)
      let map =
        string.split(line, "")
        |> list.index_fold(map, fn(map, char, col) {
          case char {
            "." -> map
            _ ->
              dict.upsert(map, char, fn(l) {
                case l {
                  Some(l) -> list.append(l, [Point(row, col)])
                  None -> [Point(row, col)]
                }
              })
          }
        })

      load_map(stream, map, row + 1, string.length(line))
    }
    Error(_) -> #(map, row, cols)
  }
}

fn load_antinodes(
  antenas: List(#(String, List(Point))),
  antinodes: Antinodes,
  rows: Int,
  cols: Int,
) -> Antinodes {
  case antenas {
    [antena, ..rest] -> {
      let #(_, antena_positions) = antena

      list.index_fold(antena_positions, antinodes, fn(antinodes, a, i) {
        list.index_fold(antena_positions, antinodes, fn(antinodes, b, j) {
          use <- bool.guard(i == j, antinodes)
          let dist = distance(a, b)
          loop_add_antinodes(b, dist, antinodes, rows, cols)
        })
      })
      |> load_antinodes(rest, _, rows, cols)
    }
    _ -> antinodes
  }
}

// components distance
fn distance(a: Point, b: Point) -> Point {
  Point(row: a.row - b.row, col: a.col - b.col)
}

fn in_bounds(p: Point, rows: Int, cols: Int) -> Bool {
  !{ p.row < 0 || p.row >= rows || p.col < 0 || p.col >= cols }
}

fn loop_add_antinodes(
  cur: Point,
  distance: Point,
  antinodes: Antinodes,
  rows: Int,
  cols: Int,
) -> Antinodes {
  use <- bool.guard(!in_bounds(cur, rows, cols), antinodes)

  let antinodes = set.insert(antinodes, cur)

  Point(row: cur.row + distance.row, col: cur.col + distance.col)
  |> loop_add_antinodes(distance, antinodes, rows, cols)
}
