import gleam/result
import gleeunit
import gleeunit/should
import parser
import tokenizer

pub fn main() {
  gleeunit.main()
}

pub fn parse_string_array_test() {
  result.try(
    "[\"hello\", \"world\"]"
      |> tokenizer.tokenize(),
    fn(tokens) { tokens |> parser.parse },
  )
  |> should.equal(
    Ok(parser.ArrayJson([parser.String("hello"), parser.String("world")])),
  )
}

pub fn parse_string_object_test() {
  result.try(
    "{\"hello\": \"world\"}"
      |> tokenizer.tokenize(),
    fn(tokens) { tokens |> parser.parse },
  )
  |> should.equal(Ok(parser.ObjectJson([#("hello", parser.String("world"))])))
}
