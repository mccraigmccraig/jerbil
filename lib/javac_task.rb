require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  class JavacTask < TaskLib
    include JavaHelper
    
    attr_accessor :name
    attr_accessor :java_files
    attr_accessor :description
    attr_accessor :dependencies

    def initialize(name)
      @name = name
      @dependencies = []     
      yield self if block_given?
      dependencies << java_files.dstdir
      define     
    end
    
    def define
      directory java_files.dstdir
      desc description unless description.nil?
      task name => dependencies + [ *java_files ] do |t|
          
        parms = [ "-d", java_files.dstdir, "-sourcepath", java_files.srcdir ]
        parms += java_files
      
        ret = 0
        javacout = printWriter_to_s do |pw|
          ret = compile(parms, pw)
        end

        raise "Compile error:\n#{javacout}" unless ret == 0
        
        copy_resources
      end
    end
    
   
    protected
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
