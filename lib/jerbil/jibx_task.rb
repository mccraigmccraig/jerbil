require 'rake'
require 'rake/tasklib'
require 'jerbil/java_helper'

module Jerbil
  # Compiles JIBX[http://jibx.sourceforge.net/] bindings.
  #
  # == Example
  #     Jerbil::JibxTask.new do |t|
  #       t.bindings = FileList[File.join(JAVA_BUILD_DIR, '/**/jibxModelExternalisedBinding.xml')]
  #       t.classpath = CLASSPATH
  #     end
  class JibxTask < Rake::TaskLib
    include JavaHelper
    
    attr_accessor :bindings, :name, :verbose, :classpath
 
    def initialize(name=:jibx)
      @name = name
      @verbose = false    
      @classpath = []
      yield self if block_given?
      define     
    end
    
    def define # :nodoc:	 
      task name => dependencies do |t|
        compiler = Rjb::import('org.jibx.binding.Compile').new
        compiler.setVerbose(verbose)
        compiler.setLoad(true)        
        begin
          compiler.compile(classpath.to_a, bindings.to_a)
        rescue 
          raise "jibx compilation failed: #{$!}"
        end 
      end   
    end
  end
end

