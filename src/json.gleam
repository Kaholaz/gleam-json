import gleam/dict.{type Dict}
import gleam/iterator.{type Iterator}
import gleam/string
import gleam/result
import gleam/list
import gleam/float
import gleam/int

pub type JsonValue {
  JsonObject(Dict(String, JsonValue))
  JsonArray(List(JsonValue))
  JsonString(String)
  JsonNumber(Float)
  JsonBool(Bool)
  JsonNull
}

pub type JsonParser {
  JsonValueParser
  JsonObjectParser(Dict(String, JsonValue))
  JsonArrayParser(List(JsonValue))
  JsonStringParser(List(String))
  JsonNumberParser(NumberParser)
  JsonTrueParser
  JsonFalseParser
  JsonNullParser
}

pub type NumberParser {
  NumberParser(tokens: List(String), state: NumberParserState)
}

pub type NumberParserState {
  Initial
  ConsumingFirstDigit
  ConsumingDigit
  ConsumingFraction(exponent: Int)
  ConsumingFirstExponent(exponent: Int)
  ConsumingExponent(exponent: Int, tokens: List(String))
}

pub fn parse_json(json_string: String) -> Result(JsonValue, Nil) {
  let chars =
    json_string
    |> string.to_graphemes
    |> iterator.from_list

  use #(out, chars) <- result.try(run_parser(JsonValueParser, chars))
  case
    chars
    |> step_ignore_whitespace
  {
    iterator.Done -> Ok(out)
    _ -> Error(Nil)
  }
}

fn step_ignore_whitespace(
  tokens: Iterator(String),
) -> iterator.Step(String, Iterator(String)) {
  let is_only_whitespace = fn(s) {
    string.trim(s)
    |> string.is_empty
  }

  case
    tokens
    |> iterator.step
  {
    iterator.Done -> iterator.Done
    iterator.Next(token, chars) ->
      case is_only_whitespace(token) {
        True -> step_ignore_whitespace(chars)
        False -> iterator.Next(token, chars)
      }
  }
}

fn assert_next_tokens(
  expected_tokens: List(a),
  tokens: Iterator(a),
) -> Result(Iterator(a), Nil) {
  let number_of_tokens =
    expected_tokens
    |> list.length

  case
    tokens
    |> iterator.take(number_of_tokens)
    |> iterator.to_list
  {
    x if x == expected_tokens ->
      Ok(
        tokens
        |> iterator.drop(number_of_tokens),
      )
    _ -> Error(Nil)
  }
}

pub fn run_parser(
  parser: JsonParser,
  tokens: Iterator(String),
) -> Result(#(JsonValue, Iterator(String)), Nil) {
  case parser {
    JsonValueParser ->
      case
        tokens
        |> step_ignore_whitespace
      {
        iterator.Done -> Error(Nil)
        iterator.Next("{", tokens) ->
          run_parser(JsonObjectParser(dict.new()), tokens)
        iterator.Next("[", tokens) -> run_parser(JsonArrayParser([]), tokens)
        iterator.Next("\"", tokens) -> run_parser(JsonStringParser([]), tokens)
        iterator.Next("t", tokens) -> run_parser(JsonTrueParser, tokens)
        iterator.Next("f", tokens) -> run_parser(JsonFalseParser, tokens)
        iterator.Next("n", tokens) -> run_parser(JsonNullParser, tokens)
        iterator.Next(token, _) ->
          case
            token
            |> is_number
            || token == "-"
          {
            True ->
              run_parser(JsonNumberParser(NumberParser([], Initial)), tokens)
            False -> Error(Nil)
          }
      }
    JsonTrueParser -> {
      use tokens <- result.try(assert_next_tokens(
        "rue"
          |> string.to_graphemes,
        tokens,
      ))
      Ok(#(JsonBool(True), tokens))
    }
    JsonFalseParser -> {
      use tokens <- result.try(assert_next_tokens(
        "alse"
          |> string.to_graphemes,
        tokens,
      ))
      Ok(#(JsonBool(False), tokens))
    }
    JsonNullParser -> {
      use tokens <- result.try(assert_next_tokens(
        "ull"
          |> string.to_graphemes,
        tokens,
      ))
      Ok(#(JsonNull, tokens))
    }
    JsonStringParser(parsed_tokens) -> {
      case
        tokens
        |> iterator.step
      {
        iterator.Done -> Error(Nil)
        iterator.Next("\"", tokens) ->
          Ok(#(
            JsonString(
              parsed_tokens
              |> list.reverse
              |> string.concat,
            ),
            tokens,
          ))
        iterator.Next(token, tokens) ->
          run_parser(JsonStringParser([token, ..parsed_tokens]), tokens)
      }
    }
    JsonNumberParser(number_parser) ->
      parse_number(number_parser, tokens)
      |> result.map(fn(ok) { #(JsonNumber(ok.0), ok.1) })
    JsonArrayParser(array) -> {
      use #(value, tokens) <- result.try(run_parser(JsonValueParser, tokens))
      case
        tokens
        |> step_ignore_whitespace
      {
        iterator.Next(",", tokens) ->
          run_parser(JsonArrayParser([value, ..array]), tokens)
        iterator.Next("]", tokens) ->
          Ok(#(
            JsonArray(
              [value, ..array]
              |> list.reverse,
            ),
            tokens,
          ))
        _ -> Error(Nil)
      }
    }
    JsonObjectParser(dict) -> {
      use #(key, tokens) <- result.try(run_parser(JsonValueParser, tokens))
      use key <- result.try(case key {
        JsonString(string) -> Ok(string)
        _ -> Error(Nil)
      })

      case
        tokens
        |> step_ignore_whitespace
      {
        iterator.Next(":", tokens) -> {
          use #(value, tokens) <- result.try(run_parser(JsonValueParser, tokens))
          case
            tokens
            |> step_ignore_whitespace
          {
            iterator.Next(",", tokens) ->
              run_parser(
                JsonObjectParser(
                  dict
                  |> dict.insert(key, value),
                ),
                tokens,
              )
            iterator.Next("}", tokens) ->
              Ok(#(
                JsonObject(
                  dict
                  |> dict.insert(key, value),
                ),
                tokens,
              ))
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
  }
}

pub fn parse_number(
  parser: NumberParser,
  tokens: Iterator(String),
) -> Result(#(Float, Iterator(String)), Nil) {
  case parser {
    NumberParser(_, Initial) ->
      case
        tokens
        |> step_ignore_whitespace
      {
        iterator.Next("-", tokens) ->
          parse_number(NumberParser(["-"], ConsumingFirstDigit), tokens)
        iterator.Next(token, _) -> {
          case
            token
            |> is_number
          {
            True -> parse_number(NumberParser([], ConsumingFirstDigit), tokens)
            False -> Error(Nil)
          }
        }
        iterator.Done -> Error(Nil)
      }
    NumberParser(digits, ConsumingFirstDigit) ->
      case
        tokens
        |> step_ignore_whitespace
      {
        iterator.Next("0", tokens) ->
          case
            tokens
            |> iterator.step
          {
            iterator.Next(".", tokens) ->
              parse_number(
                NumberParser(["0", ..digits], ConsumingFraction(0)),
                tokens,
              )
            iterator.Next(e, tokens) if e == "e" || e == "E" ->
              parse_number(
                NumberParser(["0", ..digits], ConsumingFirstExponent(0)),
                tokens,
              )
            _ -> Ok(#(0.0, tokens))
          }
        iterator.Next(token, tokens) -> {
          case
            token
            |> is_number
          {
            True ->
              parse_number(
                NumberParser([token, ..digits], ConsumingDigit),
                tokens,
              )
            False -> Error(Nil)
          }
        }
        iterator.Done -> Error(Nil)
      }
    NumberParser(digits, ConsumingDigit) ->
      case
        tokens
        |> iterator.step
      {
        iterator.Next(".", tokens) ->
          parse_number(NumberParser(digits, ConsumingFraction(0)), tokens)
        iterator.Next(token, tokens) if token == "e" || token == "E" -> {
          parse_number(NumberParser(digits, ConsumingFirstExponent(0)), tokens)
        }
        iterator.Next(token, tokens) -> {
          case
            token
            |> is_number
          {
            True ->
              parse_number(
                NumberParser([token, ..digits], ConsumingDigit),
                tokens,
              )
            False ->
              parser
              |> turn_to_number
              |> result.map(fn(f) { #(f, tokens) })
          }
        }
        iterator.Done ->
          parser
          |> turn_to_number
          |> result.map(fn(f) { #(f, tokens) })
      }
    NumberParser(digits, ConsumingFraction(exponent)) -> {
      case
        tokens
        |> iterator.step
      {
        iterator.Next(token, tokens) if token == "e" || token == "E" -> {
          parse_number(
            NumberParser(digits, ConsumingFirstExponent(exponent)),
            tokens,
          )
        }
        iterator.Next(token, tokens) -> {
          case
            token
            |> is_number
          {
            True ->
              parse_number(
                NumberParser([token, ..digits], ConsumingFraction(exponent - 1)),
                tokens,
              )
            False ->
              parser
              |> turn_to_number
              |> result.map(fn(f) { #(f, tokens) })
          }
        }
        iterator.Done ->
          parser
          |> turn_to_number
          |> result.map(fn(f) { #(f, tokens) })
      }
    }
    NumberParser(digits, ConsumingFirstExponent(exponent)) -> {
      case
        tokens
        |> iterator.step
      {
        iterator.Next("-", tokens) -> {
          parse_number(
            NumberParser(digits, ConsumingExponent(exponent, ["-"])),
            tokens,
          )
        }
        iterator.Next(token, _) -> {
          case
            token
            |> is_number
          {
            True ->
              parse_number(
                NumberParser(digits, ConsumingExponent(exponent, [])),
                tokens,
              )
            False ->
              parser
              |> turn_to_number
              |> result.map(fn(f) { #(f, tokens) })
          }
        }
        iterator.Done ->
          parser
          |> turn_to_number
          |> result.map(fn(f) { #(f, tokens) })
      }
    }
    NumberParser(digits, ConsumingExponent(exponent, exponent_digits)) -> {
      case
        tokens
        |> iterator.step
      {
        iterator.Next(token, tokens) -> {
          case
            token
            |> is_number
          {
            True ->
              parse_number(
                NumberParser(
                  digits,
                  ConsumingExponent(exponent, [token, ..exponent_digits]),
                ),
                tokens,
              )
            False ->
              parser
              |> turn_to_number
              |> result.map(fn(f) { #(f, tokens) })
          }
        }
        iterator.Done ->
          parser
          |> turn_to_number
          |> result.map(fn(f) { #(f, tokens) })
      }
    }
  }
}

fn turn_to_number(number_parser: NumberParser) -> Result(Float, Nil) {
  case number_parser {
    NumberParser(_, Initial) -> Error(Nil)
    NumberParser(_, ConsumingFirstDigit) -> Error(Nil)
    NumberParser(_, ConsumingFirstExponent(_)) -> Error(Nil)
    NumberParser(digits, ConsumingDigit) ->
      digits
      |> digit_list_to_float
    NumberParser(digits, ConsumingFraction(exponent)) -> {
      use digits <- result.try(
        digits
        |> digit_list_to_float,
      )
      use exponent <- result.try(
        10.0
        |> float.power(
          exponent
          |> int.to_float,
        ),
      )
      Ok(digits *. exponent)
    }
    NumberParser(digits, ConsumingExponent(exponent, exponent_digits)) -> {
      use exponent_digits <- result.try(
        exponent_digits
        |> list.reverse
        |> string.concat
        |> int.parse,
      )
      let exponent =
        { exponent + exponent_digits }
        |> int.to_float
      use exponent <- result.try(
        10.0
        |> float.power(exponent),
      )

      use digits <- result.try(
        digits
        |> digit_list_to_float,
      )
      Ok(digits *. exponent)
    }
  }
}

fn digit_list_to_float(digits) {
  digits
  |> list.reverse
  |> string.concat
  |> int.parse
  |> result.map(int.to_float(_))
}

pub fn is_number(token: String) -> Bool {
  ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
  |> list.contains(token)
}
