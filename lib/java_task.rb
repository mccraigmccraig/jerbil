require 'rake'
require 'rake/tasklib'

module Rake
  class JavaTask < TaskLib
         
     # Name for task
     attr_accessor :name
  
     # Class to run
     attr_accessor :classname
     
     attr_accessor :description
     
     # program args
     attr_accessor :parameters
     
     # vm args
     attr_accessor :vmargs
     
     attr_accessor :profile
     
     attr_accessor :yourkit_args 
     attr_accessor :yourkit_platform
     
     attr_accessor :classpath
     attr_accessor :max_mem
     
     attr_accessor :logging_conf
     
     attr_accessor :debug
     attr_accessor :debug_port
     
     attr_accessor :verbose
     
     attr_accessor :dependencies
     
     attr_accessor :fork
     
     attr_accessor :in_vm
     
     def initialize(name, classname)
        @name = name || classname
        @classname = classname
        @parameters = []
        @classpath = "."
        @yourkit_args = ["-agentlib:yjpagent=port=10001"]
        @yourkit_platform = "linux-x86-32"
        @max_mem = 1024
        @logging_conf = nil
        @debug = false
        @in_vm = false
        @debug_port = 8000
        @verbose = false
        @fork = false
        @vmargs = []
        @dependencies = [ :compile ]
        yield self if block_given?
        define
     end
     
     def define
        desc description unless description.nil?
        task name => dependencies do |t|
       
        if in_vm
          klass = Rjb::import(classname)
          klass.main(parameters)
          return
        end
        
        if classpath.respond_to?(:to_cp)
          cp = classpath.to_cp
        else
          cp = classpath.to_s
        end
        
        parms = [ "-cp", cp, "-Xmx#{max_mem}M" ]
        parms += vmargs
        
        unless logging_conf.nil?
          parms << "-Djava.util.logging.config.file=#{logging_conf}"
        end
        
        if profile
          parms += yourkit_args 
          ENV['LD_LIBRARY_PATH'] = ":./lib/yourkit/#{yourkit_platform}"
        end
        
        if debug
          parms += [
            "-Xdebug",
            "-Xnoagent",
            "-Xrunjdwp:transport=dt_socket,address=#{debug_port},server=y,suspend=n" ]
        end
        
        parms << classname
        parms += parameters
        
        puts "java #{parms.join(' ')}" if verbose
        
        if @fork
          sh "java", *parms                  
        else          
          begin
            exec "java", *parms
          rescue
            puts "running java with fork==false not supported on Mac OS X!" if RUBY_PLATFORM =~ /darwin/i
            raise
          end
        end       
       end
     end
  end
end
