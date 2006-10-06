#!/usr/bin/env ruby

$:.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require 'java_helper'
require 'test/unit'
require 'yaml'
require 'sample/buildconfig'

class TestBuild < Test::Unit::TestCase
  def test_compile
    run_rake(:clean, :compile) do
      assert_files_exist(JAVA_FILES.to_classfiles)
    end
  end
  
  def test_javadoc
    run_rake(:clean, :javadoc) do
      assert File.exists?(File.join(JAVADOC_DIR, "index.html"))
    end
  end
  
  def test_test_compile
    run_rake(:clean, :test_compile) do
      assert_files_exist(JAVA_FILES.to_classfiles)
      assert_files_exist(JAVA_TEST_FILES.to_classfiles)
    end  
  end
  
  def test_jar
    run_rake(:clean, :jar) do
      assert File.exists?(DISTJAR)
    end
  end
  
  def test_test
    run_rake(:clean, :test) do
      assert File.directory?(TESTOUTPUTDIR)
      assert File.exists?(File.join(TESTOUTPUTDIR, "Command line suite", "index.html"))
    end
  end
  
  def test_find_annotations
    run_rake(:clean, :find_annotations) do
      assert File.exists?(ANNOTATED_CLASSES)
      classes = YAML.load_file(ANNOTATED_CLASSES)
      
      assert classes.length == 1
      assert_equal ["jerbil.sample.Jerbiliser"], classes
    end
  end
  
  def test_run
    run_rake(:clean, :run) do
    
    end
  end
  
  private
  def assert_files_exist(files)
    files.each {|f| assert File.exists?(f)}
  end
  
  def run_rake(*args)
    Dir.chdir("sample") do     
      sh "rake --quiet #{args.join(" ")}" do |ok,res|
        flunk "rake failed: #{res}" unless ok 
        yield if block_given?     
      end
    end
  end
end
