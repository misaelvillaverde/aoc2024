import file_streams/file_stream
import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

type Letter =
  String

type Plot {
  Plot(row: Int, col: Int)
}

type Map =
  dict.Dict(Plot, Letter)

type Direction {
  Up
  Down
  Right
  Left
}

type Land {
  Land(area: Int, perimeter: Int)
}

type Path {
  Path(land: Land, visited: set.Set(Plot))
}

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day12")

  let map = load_map(stream, dict.new(), 0)

  let #(total, _) =
    map
    |> dict.fold(#(0, set.new()), fn(acc, k, v) {
      let #(total, visited) = acc
      use <- bool.guard(set.contains(visited, k), #(total, visited))

      let Path(Land(area, perimeter), visited) = walk(k, v, map, visited)

      #(total + area * perimeter, visited)
    })

  total
}

fn load_map(stream, map: Map, row: Int) -> Map {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      string.drop_end(line, 1)
      |> string.split("")
      |> list.index_fold(map, fn(acc, plot, i) {
        acc
        |> dict.insert(Plot(row, i), plot)
        |> load_map(stream, _, row + 1)
      })
    }
    Error(_) -> map
  }
}

fn walk(plot: Plot, letter: Letter, map: Map, visited: set.Set(Plot)) -> Path {
  use <- bool.guard(set.contains(visited, plot), Path(Land(0, 0), visited))

  case dict.get(map, plot) {
    Ok(spot) -> {
      use <- bool.guard(
        spot != letter,
        Path(Land(area: 0, perimeter: 0), visited),
      )

      let visited = set.insert(visited, plot)

      let perimeter =
        peek(plot, Up, letter, map)
        |> int.add(peek(plot, Right, letter, map))
        |> int.add(peek(plot, Down, letter, map))
        |> int.add(peek(plot, Left, letter, map))

      let p = Path(Land(1, perimeter), visited)
      let p = sum(walk(move(plot, Up), letter, map, p.visited), p)
      let p = sum(walk(move(plot, Down), letter, map, p.visited), p)
      let p = sum(walk(move(plot, Right), letter, map, p.visited), p)
      let p = sum(walk(move(plot, Left), letter, map, p.visited), p)
      p
    }
    Error(_) -> Path(Land(area: 0, perimeter: 0), visited)
  }
}

fn sum(a: Path, b: Path) -> Path {
  Path(
    Land(a.land.area + b.land.area, a.land.perimeter + b.land.perimeter),
    visited: a.visited,
  )
}

fn peek(plot: Plot, direction: Direction, letter: Letter, map: Map) -> Int {
  let p = case direction {
    Up -> Plot(row: plot.row - 1, col: plot.col)
    Down -> Plot(row: plot.row + 1, col: plot.col)
    Right -> Plot(row: plot.row, col: plot.col + 1)
    Left -> Plot(row: plot.row, col: plot.col - 1)
  }

  case dict.get(map, p) {
    Ok(spot) if letter == spot -> 0
    _ -> 1
  }
}

fn move(plot: Plot, direction: Direction) -> Plot {
  case direction {
    Up -> Plot(row: plot.row - 1, col: plot.col)
    Down -> Plot(row: plot.row + 1, col: plot.col)
    Right -> Plot(row: plot.row, col: plot.col + 1)
    Left -> Plot(row: plot.row, col: plot.col - 1)
  }
}
