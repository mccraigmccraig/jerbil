require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  class JavacTask < TaskLib
    include JavaHelper, ExtraArgumentTaking
    
    attr_accessor :name
    attr_accessor :java_files
    attr_accessor :verbose

    create_alias_for :g, :debug
    
    def initialize(name)
      @name = name
      @verbose = false
      yield self if block_given?
      define     
    end
    
    def define
	    desc "compile files in #{java_files.srcdir.to_a.join(', ')}" if Rake.application.last_comment.nil?     
      task name => java_files.dstdir do |t|
          
        parms  = [ "-d", java_files.dstdir ]
        parms += [ "-sourcepath", java_files.sourcepath ] unless java_files.sourcepath.nil? 
        
        parms << "-verbose" if verbose
        
        # must do this to prevent javac bombing out on the file package-info.java
        # due to known javac bug 6198196 - http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6198196
        # $IS_WINDOWS is defined in the java_helper file - bit icky, I know, but it works
        java_files.gsub!( "/", "\\" ) if $IS_WINDOWS
               
        parms += extra_args unless extra_args.nil?
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
      java_files.resources_and_target do |res, target|
        directory = File.dirname(target)
        #mkdir_p directory, :verbose=>verbose unless File.directory?(directory)
        #cp res, target, :verbose=>verbose unless uptodate?(target,res)
        mkdir_p directory unless File.directory?(directory)
        cp res, target unless uptodate?(target,res)
      end
    end
  end 
end
