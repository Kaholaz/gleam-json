import gleeunit
import gleeunit/should
import gleam/dict
import json

pub fn main() {
  gleeunit.main()
}

pub fn parse_null_test() {
  "null"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNull))
}

pub fn parse_true_test() {
  "true"
  |> json.parse_json
  |> should.equal(Ok(json.JsonBool(True)))
}

pub fn parse_false_test() {
  "false"
  |> json.parse_json
  |> should.equal(Ok(json.JsonBool(False)))
}

pub fn parse_string_test() {
  "\"foo\""
  |> json.parse_json
  |> should.equal(Ok(json.JsonString("foo")))
}

pub fn parse_digit_test() {
  "123"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(123.0)))
}

pub fn parse_negative_digit_test() {
  "-123"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(-123.0)))
}

pub fn parse_negative_fraction_test() {
  "-123.123"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(-123.123)))
}

pub fn parse_fraction_test() {
  "123.123"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(123.123)))
}

pub fn parse_exponent_test() {
  "1.23e2"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(123.0)))
}

pub fn parse_negative_exponent_test() {
  "123e-2"
  |> json.parse_json
  |> should.equal(Ok(json.JsonNumber(1.23)))
}

pub fn parse_string_array_test() {
  "[\"hello\", \"world\"]"
  |> json.parse_json
  |> should.equal(
    Ok(json.JsonArray([json.JsonString("hello"), json.JsonString("world")])),
  )
}

pub fn parse_string_object_test() {
  "{\"hello\": \"world\"}"
  |> json.parse_json
  |> should.equal(
    Ok(json.JsonObject(dict.from_list([#("hello", json.JsonString("world"))]))),
  )
}
