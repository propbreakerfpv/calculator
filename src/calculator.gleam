import gleam/io
import gleam/string
import gleam/list
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/erlang
import argv

pub fn main() {
  let args = argv.load().arguments
  case list.length(args) > 0 {
    True -> {
      args
      |> string.join(" ")
      |> do_expr
      |> int.to_string
      |> io.println
      Nil
    }
    False -> {
      let assert Ok(content) = erlang.get_line("</>: ")
      let content = string.trim(content)
      case content {
        "exit" -> Nil
        c -> {
          do_expr(c)
          |> int.to_string
          |> io.println
          main()
        }
      }
    }
  }
}

pub fn do_expr(input: String) -> Int {
  let tokens =
    input
    |> lex(0)
    |> list.filter(fn(t) {
      case t {
        WhiteSpace -> False
        _ -> True
      }
    })

  // let assert Some(ptr) =
  //   skip_while(tokens, 0, fn(e) {
  //     case e {
  //       LPeren -> True
  //       _ -> False
  //     }
  //   })

  // let assert Ok(Number(first)) = list.at(tokens, ptr)
  let parsed = parse(tokens, 0).0
  parsed
  |> eval
}

fn skip_while(l: List(t), idx: Int, f: fn(t) -> Bool) -> Option(Int) {
  case list.at(l, idx) {
    Ok(e) -> {
      case f(e) {
        True -> skip_while(l, idx + 1, f)
        False -> Some(idx)
      }
    }
    Error(_) -> None
  }
}

pub type Expression {
  Value(Int)
  Expression(lhs: Expression, op: Operator, rhs: Expression)
}

pub type Operator {
  Plus
  Minus
  Devide
  Multiply
}

pub type Token {
  Operator(Operator)
  LPeren
  RPeren
  Number(Int)
  WhiteSpace
  Unknown
}

fn lex(input: String, ptr: Int) -> List(Token) {
  case ptr == string.length(input) {
    True -> []
    False -> {
      let token = get_token(input, ptr)
      list.append([token.0], lex(input, ptr + token.1))
    }
  }
}

fn get_token(input: String, ptr: Int) -> #(Token, Int) {
  let assert Ok(char) =
    input
    |> string.to_graphemes
    |> list.at(ptr)
  case char {
    " " | "\t" -> #(WhiteSpace, 1)
    "+" -> #(Operator(Plus), 1)
    "-" -> #(Operator(Minus), 1)
    "*" -> #(Operator(Multiply), 1)
    "/" -> #(Operator(Devide), 1)
    "(" -> #(LPeren, 1)
    ")" -> #(RPeren, 1)
    n ->
      case is_num(n) {
        True -> {
          let i = extract_num(input, ptr)
          let assert Ok(num) = int.parse(i.0)
          #(Number(num), i.1)
        }
        False -> #(Unknown, 1)
      }
  }
}

fn is_num(n: String) -> Bool {
  case n {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn num_depth(num: String) -> Int {
  case is_num(num) {
    True -> num_depth(string.drop_left(num, 1)) + 1
    False -> 0
  }
}

fn extract_num(str: String, ptr: Int) -> #(String, Int) {
  case string.length(str) > ptr {
    True -> {
      let assert Ok(char) =
        str
        |> string.to_graphemes
        |> list.at(ptr)
      case char {
        "0" as c
        | "1" as c
        | "2" as c
        | "3" as c
        | "4" as c
        | "5" as c
        | "6" as c
        | "7" as c
        | "8" as c
        | "9" as c -> {
          let a = extract_num(str, ptr + 1)
          #(c <> a.0, a.1 + 1)
        }
        _ -> #("", 0)
      }
    }
    False -> {
      #("", 0)
    }
  }
}

/// 2 + 3
/// (2 + 3)
/// 2 + (3 + 4) ~ (3 + 4)
/// (3 + 4) + 2 ~ (3 + 4)
fn parse(tokens: List(Token), ptr: Int) -> #(Expression, Int) {
  let #(lhs, ptr) = case list.at(tokens, ptr) {
    Ok(LPeren) -> {
      let lhs = case list.at(tokens, ptr + 1) {
        Ok(Number(n)) -> n
        _ -> {
          io.println_error("error when parsing expression")
          panic
        }
      }
      #(lhs, ptr + 2)
    }
    Ok(Number(n)) -> {
      #(n, ptr + 1)
    }
    _ -> {
      io.println_error("error when parsing expression")
      panic
    }
  }
  parse_loop(tokens, ptr, Value(lhs))
}

/// (3 + 4) + 2
fn parse_loop(tokens: List(Token), ptr: Int, lhs: Expression) -> #(Expression, Int){
  case list.length(tokens) > ptr {
    True -> {
      let #(lhs, ptr) = continue_parse(tokens, ptr, lhs)
      parse_loop(tokens, ptr, lhs)
    }
    False -> #(lhs, ptr)
  }
}

/// 2 + 3 ~ + 3
/// (2 + 3) ~ + 3)
/// 2 + (3 + 4) ~ + (3 + 4) ~ + 4
/// (3 + 4) * 2 ~ + 4) ~ * 2
/// 1 + 2 * 3 ~ + 2 ~ * 3
fn continue_parse(tokens: List(Token), ptr: Int, lhs: Expression) -> #(Expression, Int){
  let op = case list.at(tokens, ptr) {
    Ok(Operator(op)) -> op
    _ -> {
      io.println_error("error when parsing expression")
      panic
    }
  }
  let #(ret, ptr) = case list.at(tokens, ptr + 1) {
    Ok(Number(n)) -> {
      case list.at(tokens, ptr + 2) {
        Ok(Operator(next_op)) -> {
          case op_pres(next_op) > op_pres(op) {
            True -> {
              let #(rhs, ptr) = parse(tokens, ptr + 1)
              #(Expression(lhs, op, rhs), ptr)
            }
            False -> #(Expression(lhs, op, Value(n)), ptr + 2)
          }
        }
        Ok(RPeren) | Error(_) -> #(Expression(lhs, op, Value(n)), ptr + 2)
        Ok(_) -> {
          io.println_error("error when parsing expression")
          panic
        }
      }
    }
    Ok(LPeren) -> {
      let #(rhs, ptr) = parse(tokens, ptr + 1)
      #(Expression(lhs, op, rhs), ptr)
    }
    _ -> {
      io.println_error("error when parsing expression")
      panic
    }
  }
  let ptr = case list.at(tokens, ptr) {
    Ok(RPeren) -> ptr + 1 
    _ -> ptr
  }
  #(ret, ptr)
}

fn op_pres(op: Operator) -> Int {
  case op {
    Plus -> 1
    Minus -> 1
    Devide -> 2
    Multiply -> 2
  }
}

fn eval(expr: Expression) -> Int {
  case expr {
    Value(v) -> v
    Expression(lhs, op, rhs) ->
      case op {
        Plus -> eval(lhs) + eval(rhs)
        Minus -> eval(lhs) - eval(rhs)
        Multiply -> eval(lhs) * eval(rhs)
        Devide -> eval(lhs) / eval(rhs)
      }
  }
}
