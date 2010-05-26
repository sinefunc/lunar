require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "lunar"
    gem.summary = %Q{A redis based full text search engine}
    gem.description = %Q{Features full text searching via metaphones, range querying for numbers, fuzzy searching and sorting based on custom fields}
    gem.email = "cyx.ucron@gmail.com"
    gem.homepage = "http://github.com/sinefunc/lunar"
    gem.authors = ["Cyril David"]
    gem.add_dependency "redis", ">= 2.0.0"
    gem.add_dependency "nest", ">= 0.0.4"
    gem.add_dependency "text", ">= 0"
    gem.add_development_dependency "contest", ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lunar #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
