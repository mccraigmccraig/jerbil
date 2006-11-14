require 'rake'
require 'rake/tasklib'
require 'jerbil/java_helper'

module Jerbil
  # Compiles Java source files. 
  # The location of the source files and the destionation directory is encapsulated
  # in a JavaFileList.
  #
  # == Example
  #
  #  desc "compile all java files"
  #  Jerbil::JavacTask.new(:compile) do |t|
  #    t.java_files = Jerbil::JavaFileList.new("src", "classes")
  #    t.options :nowarn, :debug
  #  end
  class JavacTask < Rake::TaskLib
    include JavaHelper, ExtraArgumentTaking
    
    attr_accessor :name
    attr_accessor :java_files
    attr_accessor :verbose

    create_alias_for :g, :debug
    
    def initialize(name)   
      @name = name
      @verbose = false
    
      yield self if block_given?
      depends_on java_files.dstdir
      define     
    end
    
    def define
	    desc "compile files in #{java_files.srcdir.to_a.join(', ')}" if Rake.application.last_comment.nil?     
      task name => dependencies do |t|
          
        if needs_compiling?
          parms  = [ "-d", java_files.dstdir ]
          parms += [ "-sourcepath", java_files.sourcepath ] if java_files.sourcepath 
          
          parms << "-verbose" if verbose
          
          # must do this to prevent javac bombing out on the file package-info.java
          # due to known javac bug 6198196 -
          # http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6198196
          java_files.gsub!( "/", "\\" ) if Jerbil::IS_WINDOWS
                 
          parms += extra_args.collect {|a|a.to_s} if extra_args        
          parms += gather_filenames    
           
          #require 'pp'
          #pp parms
          
          ret = 0
          javacout = printWriter_to_s do |pw|
            ret = compile(parms, pw)
          end
      
          raise "Compile error:\n#{javacout}" unless ret == 0                 
        end
        post_compile
      end
      directory java_files.dstdir
    end
  
    protected        
    def needs_compiling?
      not java_files.uptodate? 
    end
    
    def gather_filenames
      java_files.out_of_date    
    end
    
    def post_compile
      copy_resources
    end
    
    def compile( parameters, printwriter )
      javac = Rjb::import('com.sun.tools.javac.Main')
      javac.compile(parameters, printwriter)
    end
    
    def copy_resources
      java_files.resource_and_target do |res, target|
        directory = File.dirname(target)
        RakeFileUtils.verbose(verbose) do      
          mkdir_p directory unless File.directory?(directory)
          cp res, target unless uptodate?(target,res)
        end
      end
    end
  end 
end
