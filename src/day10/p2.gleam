import file_streams/file_stream
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string

type Direction {
  Up
  Down
  Right
  Left
}

type Coord {
  Coord(row: Int, col: Int)
}

type Map =
  dict.Dict(Coord, Int)

type Zeros =
  set.Set(Coord)

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day10/1")
  let #(map, zeros) = load_map(dict.new(), set.new(), stream, 0)

  set.fold(zeros, 0, fn(acc, zero) {
    acc + trailhead(zero, 0, map)
  })
}

fn load_map(
  map: Map,
  zeros: Zeros,
  stream: file_stream.FileStream,
  row: Int,
) -> #(Map, Zeros) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      let #(map, zeros) =
        string.drop_end(line, 1)
        |> string.split("")
        |> list.map(fn(i) { result.unwrap(int.parse(i), 0) })
        |> list.index_fold(#(map, zeros), fn(acc, n, col) {
          let #(map, zeros) = acc
          let point = Coord(row, col)
          let zeros = case n == 0 {
            True -> set.insert(zeros, point)
            False -> zeros
          }
          #(dict.insert(map, point, n), zeros)
        })
      load_map(map, zeros, stream, row + 1)
    }
    Error(_) -> #(map, zeros)
  }
}

fn trailhead(position: Coord, expected: Int, map: Map) -> Int {
  case dict.get(map, position) {
    Ok(n) if n == expected -> {
      use <- bool.guard(n == 9, 1)

      trailhead(move(position, Up), expected + 1, map)
      |> int.add(trailhead(move(position, Right), expected + 1, map))
      |> int.add(trailhead(move(position, Down), expected + 1, map))
      |> int.add(trailhead(move(position, Left), expected + 1, map))
    }
    _ -> 0
  }
}

fn move(position: Coord, direction: Direction) -> Coord {
  let Coord(row, col) = position
  case direction {
    Up -> Coord(row: row - 1, col: col)
    Down -> Coord(row: row + 1, col: col)
    Right -> Coord(row: row, col: col + 1)
    Left -> Coord(row: row, col: col - 1)
  }
}
