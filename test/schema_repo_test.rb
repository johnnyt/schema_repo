require_relative "test_helper"

class SchemaRepoTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SchemaRepo::VERSION
  end
end
