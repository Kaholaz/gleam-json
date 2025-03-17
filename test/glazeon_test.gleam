import glazeon
import gleam/dict
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn parse_null_test() {
  "null"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNull))
}

pub fn parse_true_test() {
  "true"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonBool(True)))
}

pub fn parse_false_test() {
  "false"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonBool(False)))
}

pub fn parse_string_test() {
  "\"foo\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("foo")))
}

pub fn parse_escaped_quote_test() {
  "\"\\\"\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\"")))
}

pub fn parse_escaped_slash_test() {
  "\"\\/\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("/")))
}

pub fn parse_escaped_backslash_test() {
  "\"\\\\\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\\")))
}

pub fn parse_backspace_test() {
  "\"\\b\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\u{0008}")))
}

pub fn parse_formfeed_test() {
  "\"\\f\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\f")))
}

pub fn parse_linefeed_test() {
  "\"\\n\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\n")))
}

pub fn parse_return_test() {
  "\"\\r\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\r")))
}

pub fn parse_tab_test() {
  "\"\\t\""
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonString("\t")))
}

pub fn parse_digit_test() {
  "123"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(123.0)))
}

pub fn parse_negative_digit_test() {
  "-123"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(-123.0)))
}

pub fn parse_negative_fraction_test() {
  "-123.123"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(-123.123)))
}

pub fn parse_fraction_test() {
  "123.123"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(123.123)))
}

pub fn parse_exponent_test() {
  "1.23e2"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(123.0)))
}

pub fn parse_negative_exponent_test() {
  "123e-2"
  |> glazeon.parse_json
  |> should.equal(Ok(glazeon.JsonNumber(1.23)))
}

pub fn parse_string_array_test() {
  "[\"hello\", \"world\"]"
  |> glazeon.parse_json
  |> should.equal(
    Ok(
      glazeon.JsonArray([
        glazeon.JsonString("hello"),
        glazeon.JsonString("world"),
      ]),
    ),
  )
}

pub fn parse_string_object_test() {
  "{\"hello\": \"world\"}"
  |> glazeon.parse_json
  |> should.equal(
    Ok(
      glazeon.JsonObject(
        dict.from_list([#("hello", glazeon.JsonString("world"))]),
      ),
    ),
  )
}
