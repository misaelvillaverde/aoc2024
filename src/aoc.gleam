import birl
import day11/p2
import gleam/io
import gleam/string

pub fn main() {
  // let p1x =
  //   task.async(fn() {
  //     let p1start = birl.now()
  //     let p1solution = p1.solution()
  //     let p1end = birl.now()
  //     io.debug(
  //       "p1: " <> string.inspect(#(p1solution, birl.difference(p1end, p1start))),
  //     )
  //   })

  // let p2x =
  //   task.async(fn() {
  let p2start = birl.now()
  let p2solution = p2.solution()
  let p2end = birl.now()
  io.debug(
    "p2: " <> string.inspect(#(p2solution, birl.difference(p2end, p2start))),
  )
  //   })

  // task.await_forever(p1x)
  // task.await_forever(p2x)
}
