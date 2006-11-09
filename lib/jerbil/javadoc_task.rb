require 'rake'
require 'rake/tasklib'

module Jerbil
  # A task to create javadoc from source files.
  # == Example
  #   Jerbil::JavaDocTask.new do |t|
  #     t.sourcepath = SOURCE_DIR
  #     t.subpackages = "jerbil"
  #     t.dstdir = JAVADOC_DIR
  #     t.options :quiet  
  #     t.depends_on :compile
  #   end
  class JavaDocTask < Rake::TaskLib
    include ExtraArgumentTaking
    
     attr_accessor :name
     # Desstionation directory for javadocs.
     attr_accessor :dstdir
          
     def initialize(name = :javadoc)
      @name = name   
      yield self if block_given?
      raise "need dstdir parameter" if dstdir.nil?
      depends_on dstdir
      define
     end
     
     def define
      desc "generate javadocs" if Rake.application.last_comment.nil?
      task name => dependencies do |t|
        javadoc = Rjb::import('com.sun.tools.javadoc.Main')    
        args = [ "-d", dstdir ]                                                    
        args += extra_args unless extra_args.nil?
        #require 'pp'
        #pp args
        ret = javadoc.execute(args)
        raise "error generating javadocs" unless ret==0
      end
      directory dstdir
     end
  end
end

