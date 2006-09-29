require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  class JavacTask < TaskLib
    include JavaHelper
    
    attr_accessor :name
    attr_accessor :java_files
    attr_accessor :dependencies
    attr_accessor :nowarn

    def initialize(name)
      @name = name
      @dependencies = []     
      @nowarn = false
      yield self if block_given?
      dependencies << java_files.dstdir
      define     
    end
    
    def define
	  desc "compile files in #{java_files.srcdir}" if Rake.application.last_comment.nil?
      task name => dependencies + [ *java_files ] do |t|
          
        parms = [ "-d", java_files.dstdir, "-sourcepath", java_files.srcdir ]
        parms << "-nowarn" if nowarn
        parms += java_files      
             
        ret = 0
        javacout = printWriter_to_s do |pw|
          ret = compile(parms, pw)
        end

        raise "Compile error:\n#{javacout}" unless ret == 0        
        post_compile
      end
      directory java_files.dstdir
    end
    
   
    protected    
    def post_compile
      copy_resources
    end
    
    def compile( parameters, printwriter )
      javac = Rjb::import('com.sun.tools.javac.Main')
      javac.compile(parameters, printwriter)
    end
    
    def copy_resources
      java_files.resources.each do |f|
        target =  f.sub(/#{java_files.srcdir}/, java_files.dstdir)
        mkdir_p File.dirname(target)
        cp f, target
      end
    end
  end 
end
