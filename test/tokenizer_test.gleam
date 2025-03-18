import gleeunit
import gleeunit/should
import tokenizer

pub fn main() {
  gleeunit.main()
}

pub fn parse_null_test() {
  "null"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Null)]))
}

pub fn parse_true_test() {
  "true"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Bool(True))]))
}

pub fn parse_false_test() {
  "false"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Bool(False))]))
}

pub fn parse_string_test() {
  "\"foo\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("foo"))]))
}

pub fn parse_escaped_quote_test() {
  "\"\\\"\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\""))]))
}

pub fn parse_escaped_slash_test() {
  "\"\\/\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("/"))]))
}

pub fn parse_escaped_backslash_test() {
  "\"\\\\\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\\"))]))
}

pub fn parse_backspace_test() {
  "\"\\b\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\u{8}"))]))
}

pub fn parse_formfeed_test() {
  "\"\\f\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\f"))]))
}

pub fn parse_linefeed_test() {
  "\"\\n\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\n"))]))
}

pub fn parse_return_test() {
  "\"\\r\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\r"))]))
}

pub fn parse_tab_test() {
  "\"\\t\""
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.String("\t"))]))
}

pub fn parse_digit_test() {
  "123"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("123"))]))
}

pub fn parse_negative_digit_test() {
  "-123"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("-123"))]))
}

pub fn parse_negative_fraction_test() {
  "-123.123"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("-123.123"))]))
}

pub fn parse_fraction_test() {
  "123.123"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("123.123"))]))
}

pub fn parse_exponent_test() {
  "1.23e2"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("1.23e2"))]))
}

pub fn parse_negative_exponent_test() {
  "123e-2"
  |> tokenizer.tokenize()
  |> should.equal(Ok([tokenizer.Value(tokenizer.Number("123e-2"))]))
}

pub fn parse_dot_test() {
  ".123"
  |> tokenizer.tokenize()
  |> should.equal(Error(Nil))
}
