require 'rake'
require 'rake/tasklib'

module Rake
  class JarTask < TaskLib
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
      task name => [ jardir ] do |t|
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
