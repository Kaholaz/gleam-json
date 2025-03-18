import gleam/result
import parser
import tokenizer

pub fn parse_json(json_string: String) -> Result(parser.Json, Nil) {
  use tokens <- result.try(json_string |> tokenizer.tokenize())
  tokens |> parser.parse()
}
