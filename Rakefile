require 'rake'
require 'rake/testtask'


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
