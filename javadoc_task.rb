require 'rake'
require 'rake/tasklib'

module Rake
  class JavaDocTask < TaskLib
  
     # Name for task
     attr_accessor :name
     attr_accessor :srcdir
     attr_accessor :dstdir
     attr_accessor :package
     attr_accessor :description
     attr_accessor :dependencies
     
     def initialize(name = :javadoc)
      @name = name
      @dependencies = []
      @description = "generate javadocs"
      yield self if block_given?
      define
     end
     
     def define
      desc description unless description.nil? 
      task name => dependencies do |t|
        javadoc = Rjb::import('com.sun.tools.javadoc.Main')
    
        args = [ "-sourcepath", srcdir, 
                 "-d", dstdir, 
                 "-subpackages", package, 
                 "-quiet"]
    
         links = [ "http://java.sun.com/j2se/1.5.0/docs/api", 
                "http://static.springframework.org/spring/docs/2.0.x/api",
                "http://www.hibernate.org/hib_docs/v3/api/",
                "http://www.hibernate.org/hib_docs/annotations/api/",
                "http://java.sun.com/javaee/5/docs/api/",
                "http://www.alias-i.com/lingpipe/docs/api/"]
      
        links.each {|l| args += ["-link", "#{l}" ] }
    
        ret = javadoc.execute(args)
        raise "error generating javadocs" unless ret==0
      end
     end
  end
end

