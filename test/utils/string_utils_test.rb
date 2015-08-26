require_relative "../test_helper"

class StringUtilsTest < Minitest::Test
  def utils
    SchemaRepo::StringUtils
  end

  def test_underscore
    result = utils.underscore "FooBar"
    assert_equal "foo_bar", result
  end

  def test_demodulize
    result = utils.demodulize "Foo::Bar::Baz"
    assert_equal "Baz", result
  end

  def test_constantize
    assert_equal utils, utils.constantize("SchemaRepo::StringUtils")
  end
end
