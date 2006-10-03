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
    attr_accessor :verbose

    
    def initialize(name)
      @name = name
      @dependencies = []     
      @nowarn = false
      @verbose = false
      yield self if block_given?
      dependencies << java_files.dstdir
      define     
    end
    
    def define
	  desc "compile files in #{java_files.srcdir.to_a.join(', ')}" if Rake.application.last_comment.nil?
      #task name => dependencies + [ *java_files ] do |t|
      task name => dependencies do |t|
          
        parms = [ "-d", java_files.dstdir ]
        parms += [ "-sourcepath", java_files.sourcepath ] unless java_files.sourcepath.nil? 
        
        parms << "-nowarn" if nowarn
        parms << "-verbose" if verbose
        
        # must do this to prevent javac bombing out on the file package-info.java
        # due to known javac bug 6198196 - http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6198196
        # $IS_WINDOWS is defined in the java_helper file - bit icky, I know, but it works
        java_files.gsub!( "/", "\\" ) if $IS_WINDOWS
        
        parms += java_files      
             
        #require 'pp'
        #pp parms
        
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
      java_files.resources_and_target do |res, target|
        directory = File.dirname(target)
        mkdir_p directory, :verbose=>verbose unless File.directory?(directory)
        cp res, target, :verbose=>verbose unless uptodate?(target,res)
      end
    end
  end 
end
