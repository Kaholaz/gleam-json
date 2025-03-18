import gleam/list
import gleam/result
import tokenizer

type ParserReturn =
  Result(#(Value, List(tokenizer.Token)), Nil)

pub type Json {
  ObjectJson(List(#(String, Value)))
  ArrayJson(List(Value))
}

pub type Value {
  Bool(Bool)
  Null

  String(String)
  Number(String)

  Object(List(#(String, Value)))
  Array(List(Value))
}

pub fn parse(tokens: List(tokenizer.Token)) -> Result(Json, Nil) {
  use #(value, tokens) <- result.try(case tokens {
    [] -> Error(Nil)
    [tokenizer.Control(tokenizer.ArrayOpen), ..tokens] -> parse_array(tokens)
    [tokenizer.Control(tokenizer.ObjectOpen), ..tokens] -> parse_object(tokens)
    _ -> Error(Nil)
  })

  use json <- result.try(value |> value_to_json())
  case tokens {
    [] -> Ok(json)
    _ -> Error(Nil)
  }
}

fn parse_value(tokens: List(tokenizer.Token)) -> ParserReturn {
  case tokens {
    [] -> Error(Nil)
    [token, ..tokens] -> {
      case token {
        tokenizer.Control(c) -> {
          case c {
            tokenizer.ArrayOpen -> parse_array(tokens)
            tokenizer.ObjectOpen -> parse_object(tokens)
            _ -> Error(Nil)
          }
        }
        tokenizer.Value(v) -> {
          Ok(#(v |> value_to_value(), tokens))
        }
        tokenizer.Symbol(_) -> Error(Nil)
      }
    }
  }
}

fn value_to_json(value: Value) -> Result(Json, Nil) {
  case value {
    Object(o) -> Ok(ObjectJson(o))
    Array(a) -> Ok(ArrayJson(a))
    _ -> Error(Nil)
  }
}

fn value_to_value(value: tokenizer.Value) -> Value {
  case value {
    tokenizer.Bool(b) -> Bool(b)
    tokenizer.Null -> Null
    tokenizer.Number(n) -> Number(n)
    tokenizer.String(s) -> String(s)
  }
}

fn parse_array(tokens: List(tokenizer.Token)) -> ParserReturn {
  parse_array_inner([], tokens)
  |> result.map(fn(in) {
    let #(arr, tokens) = in
    #(Array(arr |> list.reverse()), tokens)
  })
}

fn parse_array_inner(
  out: List(Value),
  tokens: List(tokenizer.Token),
) -> Result(#(List(Value), List(tokenizer.Token)), Nil) {
  use #(value, tokens) <- result.try(tokens |> parse_value())
  let out = [value, ..out]
  case tokens {
    [] -> Error(Nil)
    [tokenizer.Symbol(tokenizer.Comma), ..tokens] ->
      parse_array_inner(out, tokens)
    [tokenizer.Control(tokenizer.ArrayClose), ..tokens] -> Ok(#(out, tokens))
    _ -> Error(Nil)
  }
}

fn parse_object(tokens: List(tokenizer.Token)) -> ParserReturn {
  parse_object_inner([], tokens)
  |> result.map(fn(in) {
    let #(keyval, tokens) = in
    #(Object(keyval |> list.reverse()), tokens)
  })
}

fn parse_object_inner(
  out: List(#(String, Value)),
  tokens: List(tokenizer.Token),
) -> Result(#(List(#(String, Value)), List(tokenizer.Token)), Nil) {
  use #(key, tokens) <- result.try(case tokens {
    [] -> Error(Nil)
    [tokenizer.Value(tokenizer.String(s)), ..tokens] -> Ok(#(s, tokens))
    _ -> Error(Nil)
  })

  use tokens <- result.try(case tokens {
    [] -> Error(Nil)
    [tokenizer.Symbol(tokenizer.Colon), ..tokens] -> Ok(tokens)
    _ -> Error(Nil)
  })

  use #(value, tokens) <- result.try(tokens |> parse_value())
  let out = [#(key, value), ..out]
  case tokens {
    [] -> Error(Nil)
    [tokenizer.Symbol(tokenizer.Comma), ..tokens] ->
      parse_object_inner(out, tokens)
    [tokenizer.Control(tokenizer.ObjectClose), ..tokens] -> Ok(#(out, tokens))
    _ -> Error(Nil)
  }
}
