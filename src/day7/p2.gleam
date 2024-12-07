import file_streams/file_stream
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn solution() -> Int {
  let assert Ok(stream) = file_stream.open_read("input/day7/1")
  extract(stream, [])
  |> sum(0)
}

type Equation {
  Equation(result: Int, values: List(Int))
}

fn extract(
  stream: file_stream.FileStream,
  acc: List(Equation),
) -> List(Equation) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      case
        string.drop_end(line, 1)
        |> string.split(" ")
      {
        [result, ..values] -> {
          list.append(acc, [
            Equation(
              result: result
                |> string.drop_end(1)
                |> int.parse
                |> result.unwrap(0),
              values: values
                |> list.map(fn(i) { result.unwrap(int.parse(i), 0) }),
            ),
          ])
          |> extract(stream, _)
        }
        _ -> acc
      }
    }
    Error(_) -> acc
  }
}

fn sum(equations: List(Equation), acc: Int) -> Int {
  case equations {
    [equation, ..rest] -> {
      let assert [a, ..values] = equation.values
      case calculate(Equation(equation.result, values), a) {
        True -> sum(rest, acc + equation.result)
        False -> sum(rest, acc)
      }
    }
    _ -> acc
  }
}

fn calculate(equation: Equation, acc: Int) -> Bool {
  let Equation(result, values) = equation

  case values {
    [x, ..rest] -> {
      let add = compute(Operation(acc, x, Add))
      let mul = compute(Operation(acc, x, Mul))
      let concat = compute(Operation(acc, x, Concat))

      let equation = Equation(result, rest)

      calculate(equation, add)
      || calculate(equation, mul)
      || calculate(equation, concat)
    }
    [] -> acc == result
  }
}

type Op {
  Add
  Mul
  Concat
}

type Operation {
  Operation(a: Int, b: Int, Op)
}

fn compute(operation: Operation) -> Int {
  let Operation(a, b, op) = operation
  case op {
    Add -> a + b
    Mul -> a * b
    Concat ->
      { int.to_string(a) <> int.to_string(b) }
      |> int.parse
      |> result.unwrap(0)
  }
}
