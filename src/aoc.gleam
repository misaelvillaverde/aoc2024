import birl
import day12/p1
import gleam/io

pub fn main() {
  let start = birl.now()
  let solution = p1.solution()
  let end = birl.now()
  io.debug(#(solution, birl.difference(end, start)))
}
