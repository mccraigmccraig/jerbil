require 'rake/tasklib'
require 'jerbil/java_helper'

module Jerbil
  # A task to create jar files.
  #
  # == Example
  #   Jerbil::JarTask.new do |t|
  #     t.dir = JAVA_BUILD_DIR
  #     t.filename = DISTJAR
  #     t.depends_on :clean, :compile
  #   end
  class JarTask < Rake::TaskLib
    include JavaHelper
  
    attr_accessor :name, :dir, :filename, :files
    
    def initialize(name=:jar)
      @name = name
      yield self if block_given?
      raise "must define filename" if filename.nil? 
      raise "must define dir or files" if dir.nil? and files.nil?     
      define
    end
    
    def define
      jardir = File.dirname(filename)
      depends_on jardir
      task name => dependencies do |t|
         jar = Rjb::import('sun.tools.jar.Main')
         args = [ "cf" ]
         args << filename
         
         #unless dir.nil? 
            args += [ "-C", dir, "." ]
         #else
         #   args += files.to_classfiles           
         #end
            
         #require 'pp'
         #pp args
         jar.main(args)
      end
      directory jardir
    end
  end
end
