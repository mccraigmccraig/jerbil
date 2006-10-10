#!/usr/bin/env ruby

$:.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require 'java_helper'
require 'test/unit'
require 'yaml'
require 'sample/buildconfig'

class TestBuild < Test::Unit::TestCase
  def test_compile
    run_rake(:clean, :compile) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles)
    end
  end
  
  def test_javadoc
    run_rake(:clean, :javadoc) do |ok,res|
      assert ok
      assert File.exists?(File.join(JAVADOC_DIR, "index.html"))
    end
  end
  
  def test_test_compile
    run_rake(:clean, :test_compile) do |ok,res|
      assert ok
      assert_files_exist(JAVA_FILES.to_classfiles)
      assert_files_exist(JAVA_TEST_FILES.to_classfiles)
    end  
  end
  
  def test_jar
    run_rake(:clean, :jar) do |ok,res|
      assert ok
      assert File.exists?(DISTJAR)
    end
  end
  
  def test_test
    run_rake(:clean, :test) do |ok,res|
      assert ok
      assert File.directory?(TESTOUTPUTDIR)
      assert File.exists?(File.join(TESTOUTPUTDIR, "Command line suite", "index.html"))
    end
  end
  
  def test_find_annotations
    run_rake(:clean, :find_annotations) do |ok,res|
      assert ok
      assert File.exists?(ANNOTATED_CLASSES)
      classes = YAML.load_file(ANNOTATED_CLASSES)
      
      assert_equal 1, classes.length
      assert_equal ["jerbil.sample.Jerbiliser"], classes
    end
  end
  
  def test_run_no_fork
    run_rake(:clean, :run) do |ok,res|
      assert !ok
      assert_equal 70, res.exitstatus
    end
  end
  
  def test_run_forked_ok
    run_rake(:clean, :run_forked) do |ok,res|
      assert ok	        
    end
  end
  
  def test_run_forked_fail
    run_rake(:clean, :run_forked_fail) do |ok,res|
      assert !ok	    
      assert_equal 1, res.exitstatus 
    end
  end
  
  def test_clean
    run_rake(:clean, :compile, :jar, :test)
    run_rake(:clean) do |ok,res|
      assert ok
      assert !File.directory?(TESTOUTPUTDIR)  
      assert !File.directory?(BUILD_DIR)
      assert !File.directory?(DIST_DIR)
    end
  end
  
  private
  def assert_files_exist(files)
    files.each {|f| assert File.exists?(f)}
  end
  
  def run_rake(*args, &block)
    Dir.chdir("sample") do
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
