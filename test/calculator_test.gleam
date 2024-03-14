import gleeunit
import gleeunit/should
import calculator

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn one_plus_one_test() {
  "1 + 1"
  |> calculator.do_expr
  |> should.equal(2)
}

pub fn math1_test() {
  "1 - 1"
  |> calculator.do_expr
  |> should.equal(0)
}
pub fn math2_test() {
  "2 * 2"
  |> calculator.do_expr
  |> should.equal(4)
}
pub fn math3_test() {
  "2 / 2"
  |> calculator.do_expr
  |> should.equal(1)
}

pub fn complex_math1_test() {
  "(2 + 2)"
  |> calculator.do_expr
  |> should.equal(4)
}
pub fn complex_math2_test() {
  "(2 + 2) + 1"
  |> calculator.do_expr
  |> should.equal(5)
}
pub fn complex_math3_test() {
  "1 + (2 + 2)"
  |> calculator.do_expr
  |> should.equal(5)
}
pub fn complex_math4_test() {
  "2 + 3 * 4"
  |> calculator.do_expr
  |> should.equal(14)
}
pub fn complex_math5_test() {
  "(2 + 3) * 4"
  |> calculator.do_expr
  |> should.equal(20)
}
pub fn complex_math6_test() {
  "2 + (3 - 4)"
  |> calculator.do_expr
  |> should.equal(1)
}
