require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'

WWWROOT = "/var/www/code.trampolinesystems.com/"

task :default => :repackage 

def read_version
  "0.1"
end

spec = Gem::Specification.new do |s|
  s.authors = 'Jan Berkel'
  s.email = 'jan@trampolinesystems.com'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.4'
  s.summary = 'Java build system, based on rake'
  s.name = 'jerbil'
  s.homepage = 'http://code.trampolinesystems.com/jerbil'
  s.version = read_version
  s.add_dependency('rjb', '>= 1.0')
  s.add_dependency('rake', '>= 0.7.1')
  s.require_path = 'lib'
  s.requirements << 'rjb'
  s.requirements << 'rake'
  s.requirements << 'JDK 5.0'
  files = FileList['lib/**/*', 'test/*.rb', 'buildsupport/**/*', 'classloader/*', 'sample/**/*', 'COPYING', 'ChangeLog', 'README']
  s.has_rdoc = true
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
  rd.options << "--inline-source"
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

desc "publish documentation"
task :publish_doc  do |t|
  `scp -r html/* trampolinesystems.com:#{WWWROOT}/doc/jerbil/`
end
task :publish_doc => :rerdoc

task :copy_gem do |t|
  `scp pkg/* trampolinesystems.com:#{WWWROOT}/gems` 
end
task :copy_gem => :repackage

task :update_gem_index do |t|
  `ssh trampolinesystems.com generate_yaml_index -d #{WWWROOT}`
end

desc "publish gem"
task :publish_gem => [:copy_gem, :update_gem_index]

task :dist => [ :compile_classloader, :publish_gem, :publish_doc ]
