#!/usr/bin/env ruby

$:.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require 'test/unit'
require 'jerbil/java_helper'

module Jerbil
  class TestJavaHelper < Test::Unit::TestCase
    def test_to_classfiles
      flist = JavaFileList.new("src","dst")
      flist.add("src/org/foo/Bla.java")
      flist.add("src/org/foo/Baz.java")
  
      cf = flist.to_classfiles
      assert cf.length == 2
      assert_equal 'dst/org/foo/Bla.class', cf[0]
      assert_equal 'dst/org/foo/Baz.class', cf[1]
    end
  
    def test_to_classes
      JavaHelper.guess_java_home
      flist = JavaFileList.new("src","dst")
      flist.add("java/lang/String.java")
      flist.add("java/util/Map.java")
  
      cf = flist.to_classes
      assert cf.length == 2
      assert_equal 'java.lang.String', cf[0].getName
      assert_equal 'java.util.Map', cf[1].getName
    end
    
  
    def test_to_cp
      flist = FileList["ab.jar", "cd.jar", "ef.jar"]          
      assert_equal 'ab.jar:cd.jar:ef.jar', flist.to_cp(':')
      assert_equal 'ab.jar;cd.jar;ef.jar', flist.to_cp(';')
    end
    
    def test_javafiles
      flist = JavaFileList.new(
        File.join(File.dirname(__FILE__), "..", "example", "src"),
        File.join(File.dirname(__FILE__), "..", "example", "build"))
      
      classnames = flist.to_classnames
      assert_equal 6, classnames.length, classnames
      assert_equal 1, flist.resources.length, flist.resources
          
      assert_equal [
				'jerbil.example.EntityWithValidationErrors',
				'jerbil.example.JerbilEntity', 
        'jerbil.example.Jerbiliser',
        'jerbil.example.Main',
        'jerbil.example.Main2',
        'jerbil.example.MyAnnotation'], classnames.sort
    
      #assert_equal ['./../example/src/jerbil/example/example.properties'], 
      #  flist.resources.sort
      
      #flist.source_and_target do |s,t|
      #  puts "#{s} ==> #{t}"
      #end
      
      #puts flist.outofdate
    end    
  end
end

