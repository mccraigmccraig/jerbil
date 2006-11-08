require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'

task :default => :test 

def read_version
  "0.1"
end

spec = Gem::Specification.new do |s|
  s.authors = 'Jan Berkel'
  s.email = 'jan@trampolinesystems.com'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.2'
  s.summary = 'Jerbil java build system'
  s.name = 'jerbil'
  s.homepage = 'http://code.trampolinesystems.com/jerbil'
  s.version = read_version
  s.add_dependency('rjb', '>= 1.0')
  s.require_path = 'lib'
  s.requirements << 'rjb'
  s.requirements << 'JDK 5.0'
  files = FileList['lib/**/*', 'test/*.rb', 'buildsupport/**/*', 'classloader/*', 'COPYING', 'ChangeLog', 'README']
  s.has_rdoc = false
  s.files = files
  s.test_files = FileList['test/*.rb']
  s.description = <<EOD
Jerbil (Java-Ruby-Build) is a rake and rjb based build system.
EOD
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_zip = false
  pkg.need_tar = false
end

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
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
