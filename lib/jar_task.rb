require 'rake'
require 'rake/tasklib'

module Rake
  class JarTask < TaskLib
    include JavaHelper
  
    attr_accessor :name, :dir, :filename
    
    def initialize(name=:jar)
      yield self if block_given?
      raise "must define filename" if filename.nil? 
      raise "must define dir" if dir.nil? 
      define
    end
    
    def define
      dir = File.basename(filename)
      task name => [ dir ] do |t|
         jar = Rjb::import('sun.tools.jar.Main')
         args = [ "cf" ]
         args << filename
         args += [ "-C", dir, "." ]
         jar.main(args)
      end
      directory dir
    end
  end
end
