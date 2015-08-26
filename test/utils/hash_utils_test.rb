require_relative "../test_helper"

class HashUtilsTest < Minitest::Test
  def utils
    SchemaRepo::HashUtils
  end

  def test_symbolize_keys_converts_keys_to_symbols
    result = utils.symbolize({ "foo" => "bar" })
    assert_equal({ foo: "bar"}, result)
  end

  def test_symbolize_keys_recursises_into_objects
    result = utils.symbolize({ "foo" => { "bar" => "baz" }})
    assert_equal({ foo: { bar: "baz" }}, result)
  end
end
