require 'rake'
require 'rake/tasklib'

module Rake
  class JavaTask < TaskLib
     include ExtraArgumentTaking
     
     # Name for task
     attr_accessor :name
  
     # Class to run
     attr_accessor :classname
     
     # program args
     attr_accessor :parameters
         
     attr_accessor :classpath
                    
     attr_accessor :fork     
     attr_accessor :in_vm
     
     def initialize(name, classname)
        @name = name || classname
        @classname = classname
        @parameters = []
        @classpath = "."              
        @in_vm = false
        @fork = false   
        yield self if block_given?
        define
     end
       
     def yourkit(port=1001, platform="linux-x86-32")
        add_extra_args "-agentlib:yjpagent=port=#{port}"
        ENV['LD_LIBRARY_PATH'] = ":./lib/yourkit/#{platform}"
     end
     
     def sys_property(name,value)
        add_extra_args "-D#{name}=#{value}"
     end
     
     def logging_conf=(file)
        sys_property("java.util.logging.config.file", file)
     end
     
     def max_mem=(mem)
        add_extra_args "-Xmx#{mem}M"
     end
     
     def debug(port=8000, suspend="n")
        add_extra_args "-Xdebug", "-Xnoagent",
          "-Xrunjdwp:transport=dt_socket,address=#{port},server=y,suspend=#{suspend}"
     end
     
     protected
     def define
        #desc "run #{classname}" if Rake.application.last_comment.nil?      
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
        
        parms = [ "-cp", cp ]
        parms += extra_args unless extra_args.nil?
               
        parms << classname
        parms += parameters
                      
        if @fork
          RakeFileUtils.verbose(verbose) do 
            sh "java", *parms
          end
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
