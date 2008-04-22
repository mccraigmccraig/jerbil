#!/usr/bin/env ruby

$:.unshift File.join( File.dirname(__FILE__), "..", "lib" )
$:.unshift File.join( File.dirname(__FILE__), "..", "example" )

require 'jerbil/java_helper'
require 'test/unit'
require 'yaml'
require 'buildconfig'

class TestBuild < Test::Unit::TestCase
  def test_compile
  
    tstamps, tstamps2 = []
    
    run_rake_clean(:compile) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles)
      assert File.exists?(File.join(JAVA_BUILD_DIR, "jerbil/example/example.properties"))
      tstamps = JAVA_FILES.to_classfiles.collect { |f| File.mtime(f) }
    end
      
    #run another compile, without cleaning up
    run_rake(:compile) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles) 
      tstamps2 = JAVA_FILES.to_classfiles.collect { |f| File.mtime(f) }
    end
          
    assert_equal tstamps, tstamps2
  end
  
  
  def test_compile_with_separate_resources
  
    tstamps, tstamps2 = []
    
    run_rake_clean(:compile_with_separate_resources) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles)
      assert File.exists?(File.join(JAVA_BUILD_DIR, "jerbil/example/a_resource.properties"))
      assert !File.exists?(File.join(JAVA_BUILD_DIR, "jerbil/example/example.properties"))
      tstamps = JAVA_FILES.to_classfiles.collect { |f| File.mtime(f) }
    end
      
    #run another compile, without cleaning up
    run_rake(:compile_with_separate_resources) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles) 
      tstamps2 = JAVA_FILES.to_classfiles.collect { |f| File.mtime(f) }
    end
          
    assert_equal tstamps, tstamps2
  end
  
  
  def test_javadoc
    run_rake_clean(:javadoc) do |ok,res|
      assert ok
      assert File.exists?(File.join(JAVADOC_DIR, "index.html"))
    end
  end
  
  def test_test_compile
    run_rake_clean(:test_compile) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles)
      assert_files_exist(JAVA_TEST_FILES.to_classfiles)
    end  
  end
  
  def test_jar
    run_rake_clean(:jar) do |ok,res|
      assert ok
      assert File.exists?(DISTJAR)
    end
  end
  
  def test_test
    run_rake_clean(:test) do |ok,res|
      assert ok
      assert File.directory?(TESTOUTPUTDIR)
      assert File.exists?(File.join(TESTOUTPUTDIR, "Command line suite", "index.html"))
    end
  end
  
  def test_find_annotations
    run_rake_clean(:find_annotations) do |ok,res|
      assert ok
      assert File.exists?(ANNOTATED_CLASSES)
      classes = YAML.load_file(ANNOTATED_CLASSES)
      
      assert_equal 1, classes.length
      assert_equal ["jerbil.example.Jerbiliser"], classes
    end
  end
  
  def test_export_schema
    run_rake_clean(:export_schema) do |ok,res|
      assert ok
      assert File.exists?(DB_SCHEMA)
      #make sure file is not empty
      assert File.size(DB_SCHEMA) >= 200
    end
  end
  
  def test_export_schema_filtered
    run_rake_clean(:export_schema_filtered) do |ok,res|
      assert ok
      assert File.exists?(DB_SCHEMA)
      #make sure file is empty
      assert File.size(DB_SCHEMA) <= 150
    end
  end
  
  def test_validate_schema_success
    run_rake_clean(:validate_schema_success) do |ok,res|
      assert ok    
      assert File.exists?(DB_SCHEMA)
      #make sure file is not empty
      assert File.size(DB_SCHEMA) >= 200
    end
  end
  
  def test_validate_schema_failure
    run_rake_clean(:validate_schema_failure) do |ok,res|
      assert !ok     
    end
  end
  
  
  def test_run_no_fork
    run_rake_clean(:run) do |ok,res|
      assert !ok
      assert_equal 70, res.exitstatus, "NB: this test fails on Mac OS X"
    end
  end
  
  def test_run_forked_ok
    run_rake_clean(:run_forked) do |ok,res|
      assert ok	        
    end
  end
  
  def test_run_in_vm
    run_rake_clean(:run_in_vm) do |ok,res|
      assert !ok
      assert_equal 70, res.exitstatus	        
    end
  end
  
  def test_run_forked_fail
    run_rake_clean(:run_forked_fail) do |ok,res|
      assert !ok	    
      assert_equal 1, res.exitstatus 
    end
  end
  
  def test_clean
    run_rake_clean(:jar) 
    
    run_rake(:clean) do |ok,res|
      assert ok
      assert !File.directory?(TESTOUTPUTDIR)  
      assert !File.directory?(BUILD_DIR)
      assert !File.directory?(DIST_DIR)
    end
  end
  
  def test_test_java_task
    run_rake(:clean, :test_java_task)
  end
  
  def test_dmg_task
    run_rake(:clean, :dmg)
  end
  
  private
  def assert_files_exist(files)
    files.each {|f| assert File.exists?(f)}
  end
  
  # runs rake clean in a separate process to 
  # detect classloader problems
  def run_rake_clean(*args)  
    run_rake(:clean) 
    if block_given?
      run_rake(args) { |ok,res| yield ok,res }
    else 
      run_rake(args)
    end
  end
  
  def run_rake(*args, &block)
    Dir.chdir(File.join(File.dirname(__FILE__), "..", "example")) do
      #sh "rake --quiet #{args.join(' ')}" do |ok,res|
      cmd = args.join(" ")
      #on windows, exec invokes a subshell which does not inherit environment variables,
      #therefore we cannot invoke rake directly      
      unless block_given?      
        block = lambda {|ok,res| flunk "rake failed: #{res}" unless ok }
      end
      
      ruby %{-rubygems -e "require 'rake'; Rake.application.run" #{cmd} --quiet} do |ok,res|      	
        flunk "could not invoke rake" if res.nil?
        block.call(ok, res)
      end
    end
  end
end
