
$:.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require 'rubygems'
require 'test/unit'
require 'java_helper'

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
		flist = JavaFileList.new("src","dst")
        flist.add("src/org/foo/Bla.java")
        flist.add("src/org/foo/Baz.java")

        cf = flist.to_classes
        assert cf.length == 2
        assert_equal 'org.foo.Bla', cf[0]
        assert_equal 'org.foo.Baz', cf[1]
	end

	def test_to_cp
		flist = FileList["ab.jar", "cd.jar", "ef.jar"]
		cp = flist.to_cp
		assert_equal 'ab.jar:cd.jar:ef.jar', cp
	end
end

