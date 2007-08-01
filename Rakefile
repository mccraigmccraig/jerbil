require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'

CLEAN.include('pkg')

FILES     = FileList['lib/**/*', 'test/*.rb', 'classloader/*', 'sql_reserved_words/*', 'LICENSE', 'TODO', 'CHANGES', 'README']
FULLFILES = FILES.clone.include('buildsupport/**/*', 'example/**/*' )
TESTFILES = FileList['test/test_java_helper.rb']
FULLTESTFILES = TESTFILES.clone.include('test/test_build.rb')

JERBIL_VERSION   = "0.2"

task :default => :repackage 

spec = Gem::Specification.new do |s|
  s.authors = 'Jan Berkel'
  s.email = 'jan@trampolinesystems.com'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.4'
  s.summary = 'Java build system, based on rake'
  s.name = 'jerbil'
  s.homepage = 'http://code.trampolinesystems.com/jerbil'
  s.version = JERBIL_VERSION
  s.add_dependency('rjb', '>= 1.0')
  s.add_dependency('rake', '>= 0.7.1')
  s.add_dependency('builder')
  s.require_path = 'lib'
  s.requirements << 'rjb'
  s.requirements << 'rake'
  s.requirements << 'builder'
  s.requirements << 'JDK 5.0'
  s.has_rdoc = true
  s.files = FILES
  s.test_files = TESTFILES
  s.description = <<EOD
Jerbil (Java-Ruby-Build) is a rake and rjb based build system.
EOD
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.gem_spec = spec
    pkg.need_zip = false
    pkg.need_tar = false
end
  
namespace :full do
  fullspec = spec.clone
  fullspec.files = FULLFILES
  fullspec.test_files = FULLTESTFILES
  fullspec.name = 'jerbil-full'
  Rake::GemPackageTask.new(fullspec) do |pkg|
    pkg.gem_spec = fullspec
    pkg.need_zip = false
    pkg.need_tar = false
  end
end

Rake::RDocTask.new do |rdoc|
  rdoc.title    = "Jerbil"
  rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include("README", "CHANGES", "TODO", "LICENSE", "lib/**/*.rb")
	rdoc.rdoc_dir = 'rdoc'
  rdoc.template = 'externals/allison/allison.rb'
end
  
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = false
end

desc "compile the classloader"
task :compile_classloader do |t|
  javac = "javac"
  retried = false
  begin
    Dir.chdir("classloader") do
      sh %{#{javac} JerbilClassLoader.java}
    end
  rescue
    if ENV['JAVA_HOME'] && !retried
      javac = File.join(ENV['JAVA_HOME'], "bin", "javac")
      retried = true 
      retry
    end
      
    $stderr << "Make sure javac is in your PATH, or set JAVA_HOME"
    raise
  end
end

begin
    require 'maintainer'
rescue LoadError
end

