import gleam/list
import gleam/result
import gleam/string

const digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

const non_zero_digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

pub type Value {
  String(String)
  Number(String)
  Bool(Bool)
  Null
}

pub type Symbol {
  Comma
  Colon
}

pub type Control {
  ArrayOpen
  ArrayClose
  ObjectOpen
  ObjectClose
}

pub type Token {
  Value(Value)
  Symbol(Symbol)
  Control(Control)
}

pub fn tokenize(string: String) -> Result(List(Token), Nil) {
  use tokens <- result.try(tokenize_inner(string, []))
  tokens |> list.reverse() |> Ok()
}

fn tokenize_inner(
  string: String,
  tokens: List(Token),
) -> Result(List(Token), Nil) {
  case string |> string.trim_left() |> string.pop_grapheme() {
    // No more input:
    Error(_) -> Ok(tokens)
    Ok(#(char, string)) -> {
      case char {
        // Control caracters
        "[" -> tokenize_inner(string, [Control(ArrayOpen), ..tokens])
        "]" -> tokenize_inner(string, [Control(ArrayClose), ..tokens])
        "{" -> tokenize_inner(string, [Control(ObjectOpen), ..tokens])
        "}" -> tokenize_inner(string, [Control(ObjectClose), ..tokens])

        // Symbols
        "," -> tokenize_inner(string, [Symbol(Comma), ..tokens])
        ":" -> tokenize_inner(string, [Symbol(Colon), ..tokens])

        // Values
        "f" -> {
          use #(token, string) <- result.try(expect_literal(
            "alse",
            string,
            Value(Bool(False)),
          ))
          tokenize_inner(string, [token, ..tokens])
        }
        "t" -> {
          use #(token, string) <- result.try(expect_literal(
            "rue",
            string,
            Value(Bool(True)),
          ))
          tokenize_inner(string, [token, ..tokens])
        }
        "n" -> {
          use #(token, string) <- result.try(expect_literal(
            "ull",
            string,
            Value(Null),
          ))
          tokenize_inner(string, [token, ..tokens])
        }

        "\"" -> {
          use #(token, string) <- result.try(string |> parse_string())
          tokenize_inner(string, [token, ..tokens])
        }

        "-" -> {
          use #(number, string) <- result.try(
            string |> parse_negative_number(["-"], _),
          )
          tokenize_inner(string, [number |> tokenize_digit_list(), ..tokens])
        }
        "0" -> {
          use #(number, string) <- result.try(
            string |> parse_fraction(["0"], _),
          )
          tokenize_inner(string, [number |> tokenize_digit_list(), ..tokens])
        }
        digit -> {
          case
            non_zero_digits
            |> list.contains(digit)
          {
            True -> {
              use #(number, string) <- result.try(
                string |> parse_positive_number([digit], _),
              )
              tokenize_inner(string, [number |> tokenize_digit_list(), ..tokens])
            }
            False -> {
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

fn expect_literal(
  expected: String,
  input: String,
  success_token: Token,
) -> Result(#(Token, String), Nil) {
  case expected |> string.pop_grapheme() {
    Error(_) -> Ok(#(success_token, input))
    Ok(#(expected_char, expected)) -> {
      case input |> string.pop_grapheme() {
        Error(_) -> Error(Nil)
        Ok(#(input_char, input)) -> {
          case expected_char == input_char {
            True -> expect_literal(expected, input, success_token)
            False -> Error(Nil)
          }
        }
      }
    }
  }
}

fn parse_string(string: String) -> Result(#(Token, String), Nil) {
  parse_string_inner([], string)
}

fn parse_string_inner(
  out: List(String),
  input: String,
) -> Result(#(Token, String), Nil) {
  case input |> string.pop_grapheme() {
    Error(_) -> Error(Nil)
    Ok(#(char, input)) -> {
      case char {
        "\"" ->
          Ok(#(Value(String(out |> list.reverse() |> string.join(""))), input))

        "\\" -> {
          case input |> string.pop_grapheme() {
            Error(_) -> Error(Nil)
            Ok(#(char, input)) -> {
              case char {
                "\"" -> parse_string_inner([char, ..out], input)
                "\\" -> parse_string_inner([char, ..out], input)
                "/" -> parse_string_inner([char, ..out], input)

                "b" -> parse_string_inner(["\u{8}", ..out], input)
                "f" -> parse_string_inner(["\f", ..out], input)
                "n" -> parse_string_inner(["\n", ..out], input)
                "r" -> parse_string_inner(["\r", ..out], input)
                "t" -> parse_string_inner(["\t", ..out], input)

                "u" -> todo

                _ -> Error(Nil)
              }
            }
          }
        }

        char -> parse_string_inner([char, ..out], input)
      }
    }
  }
}

fn parse_negative_number(
  chars: List(String),
  input: String,
) -> Result(#(List(String), String), Nil) {
  case input |> string.pop_grapheme() {
    Error(_) -> Error(Nil)
    Ok(#("0", input)) -> parse_fraction(["0", ..chars], input)
    Ok(#(char, input)) -> {
      case
        non_zero_digits
        |> list.contains(char)
      {
        True -> parse_positive_number([char, ..chars], input)
        False -> Error(Nil)
      }
    }
  }
}

fn parse_positive_number(
  chars: List(String),
  input: String,
) -> Result(#(List(String), String), Nil) {
  let #(chars, input) = consume_digits(chars, input)
  parse_fraction(chars, input)
}

fn parse_fraction(
  chars: List(String),
  input: String,
) -> Result(#(List(String), String), Nil) {
  use #(chars, input) <- result.try(case input |> string.pop_grapheme() {
    Error(_) -> Ok(#(chars, input))
    Ok(#(".", input)) -> {
      let #(chars, input) = consume_digits([".", ..chars], input)
      case chars |> list.first() {
        Ok(".") -> Error(Nil)
        Error(_) -> panic as "No chars when parsing number. This is impossible!"
        _ -> Ok(#(chars, input))
      }
    }
    Ok(_) -> Ok(#(chars, input))
  })
  parse_exponent(chars, input)
}

fn parse_exponent(
  chars: List(String),
  input: String,
) -> Result(#(List(String), String), Nil) {
  case input |> string.pop_grapheme() {
    Error(_) -> Ok(#(chars, input))
    Ok(#(e, next_input)) -> {
      case e == "e" || e == "E" {
        False -> Ok(#(chars, input))
        True ->
          case next_input |> string.pop_grapheme() {
            Ok(#("-", input)) -> {
              let #(chars, input) = consume_digits(["-", ..chars], input)
              case chars |> list.first() {
                Ok("-") -> Error(Nil)
                Error(_) ->
                  panic as "No chars when parsing number. This is impossible!"
                _ -> Ok(#(chars, input))
              }
            }
            Ok(#("+", input)) -> {
              let #(chars, input) = consume_digits(["+", ..chars], input)
              case chars |> list.first() {
                Ok("+") -> Error(Nil)
                Error(_) ->
                  panic as "No chars when parsing number. This is impossible!"
                _ -> Ok(#(chars, input))
              }
            }
            Error(_) -> Error(Nil)
            _ -> {
              let #(chars, input) = consume_digits(chars, next_input)
              case chars |> list.first() {
                Ok("e") -> Error(Nil)
                Ok("E") -> Error(Nil)
                Error(_) ->
                  panic as "No chars when parsing number. This is impossible!"
                _ -> Ok(#(chars, input))
              }
            }
          }
      }
    }
  }
}

fn consume_digits(
  output: List(String),
  input: String,
) -> #(List(String), String) {
  case input |> string.pop_grapheme() {
    Error(_) -> #(output, input)
    Ok(#(char, next_input)) -> {
      case
        digits
        |> list.contains(char)
      {
        True -> consume_digits([char, ..output], next_input)
        False -> #(output, input)
      }
    }
  }
}

fn tokenize_digit_list(digits: List(String)) -> Token {
  digits |> list.reverse() |> string.join("") |> Number() |> Value()
}
