require 'rake'
require 'rake/tasklib'

module Rake
  class JavaDocTask < TaskLib
    include ExtraArgumentTaking
    
     attr_accessor :name
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

