# coding: utf-8
lib = File.expand_path "../lib", __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require "schema_repo/version"

Gem::Specification.new do |spec|
  spec.name          = "schema_repo"
  spec.version       = SchemaRepo::VERSION
  spec.authors       = ["JohnnyT"]
  spec.email         = ["ubergeek3141@gmail.com"]

  spec.summary       = "A REST service to store Avro schemas"
  spec.description   = "A REST service to store Avro schemas"
  spec.homepage      = "https://github.com/johnnyt/schema_repo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest", "= 5.4.2"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "rake"
end
