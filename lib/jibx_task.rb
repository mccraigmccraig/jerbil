require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'
require File.dirname(__FILE__) + '/javac_task'

module Rake
  class JibxTask < TaskLib
    include JavaHelper
    
    attr_accessor :bindings, :name, :dependencies, :verbose, :classpath
 
    def initialize(name=:jibx)
      @name = name
      @verbose = false
      @dependencies = []
      @classpath = []
      yield self if block_given?
      define     
    end
    
    def define	 
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

