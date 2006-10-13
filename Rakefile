require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'


task :default => :test 

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = false
end


desc "install sample Rakefile. Specify your SRC=x and TESTSRC=y for your source file locations."
task :install do |t|

  dstfile = File.join(Rake.original_dir, "../Rakefile")
    
  raise "\n#{dstfile} already exists, delete it first to proceed\n" if File.exists?(dstfile)
  
  src = ENV['SRC'] || "src"
  testsrc = ENV['TESTSRC'] || "testsrc"
  
  rfile = File.read('Rakefile.jerbil')
  
  rfile.gsub!(/##SRC##/, src)
  rfile.gsub!(/##TESTSRC##/, testsrc)
  
  File.open( dstfile, 'w' ) do |f|
    f << rfile
  end  
  
  puts "created sample Rakefile in #{dstfile}"
end

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
  s.homepage = 'http://www2.trampolinesystems.com/code/jerbil'
  s.version = read_version
  s.add_dependency('rjb', '>= 1.0')
  s.require_path = 'lib'
  s.requirements << 'rjb'
  s.requirements << 'JDK 5.0'
  files = FileList['lib/*.rb', 'samples/**/*', 
                   'test/*.rb', 'classloader/*' 'COPYING', 'ChangeLog', 'README']
  
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
