require "bundler/gem_tasks"
require "rake/testtask"
require "stringio"

def capture_stdout
  out = StringIO.new
  $stdout = out
  yield
  return out
ensure
  $stdout = STDOUT
end

desc "Run examples"
task :examples do
  root = File.dirname __FILE__
  Dir["#{root}/examples/*.rb"].each do |example|
    capture_stdout do
      require example
    end
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
