require 'rake'
require 'rake/tasklib'

module Rake
  class JavaDocTask < TaskLib
  
     # Name for task
     attr_accessor :name
     attr_accessor :sourcepath
     attr_accessor :dstdir
     attr_accessor :package
     attr_accessor :dependencies
     attr_accessor :verbose
     attr_accessor :links
     
     def initialize(name = :javadoc)
      @name = name
      @dependencies = []
      @verbose = false
      @links = []
      yield self if block_given?
      define
     end
     
     def define
      desc "generate javadocs" if Rake.application.last_comment.nil?
      task name => dependencies << dstdir do |t|
        javadoc = Rjb::import('com.sun.tools.javadoc.Main')
    
        args = [ "-sourcepath", sourcepath, 
                 "-d", dstdir ]
                                
        args << "-quiet" unless verbose                 
        args +=[ "-subpackages", package ] unless package.nil? 
    
        links = [ "http://java.sun.com/j2se/1.5.0/docs/api", 
                "http://static.springframework.org/spring/docs/2.0.x/api",
                "http://www.hibernate.org/hib_docs/v3/api/",
                "http://www.hibernate.org/hib_docs/annotations/api/",
                "http://java.sun.com/javaee/5/docs/api/",
                ]
      
        links.each {|l| args += ["-link", "#{l}" ] } 
    
        ret = javadoc.execute(args)
        raise "error generating javadocs" unless ret==0
      end
      directory dstdir
     end
  end
end

