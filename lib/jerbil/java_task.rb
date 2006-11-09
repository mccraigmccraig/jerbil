require 'rake'
require 'rake/tasklib'

module Jerbil
  # Runs a Java program, either in-vm or as separate process (forked or replacing
  # current process).
  #
  # == Example (forked)
  #     Jerbil::JavaTask.new(:run, "jerbil.sample.Main") do |t|
  #       t.classpath = CLASSPATH
  #       t.parameters = [ "--quiet" ]       
  #       t.max_mem = 64
  #       t.fork = true
  #       t.depends_on :compile
  #     end
  # == Example (in-vm)
  #     Jerbil::JavaTask.new(:run, "jerbil.sample.Main") do |t|
  #       t.parameters = [ "-foo", "baz" ]       
  #       t.in_vm = true     
  #       t.depends_on :compile
  #     end
  
  class JavaTask < Rake::TaskLib
     include ExtraArgumentTaking
     
     # Name for task
     attr_accessor :name
  
     # Class to run
     attr_accessor :classname
     
     # Program args
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
       
     def yourkit(port=1001, platform="linux-x86-32") # :nodoc:
        add_extra_args "-agentlib:yjpagent=port=#{port}"
        ENV['LD_LIBRARY_PATH'] = ":./lib/yourkit/#{platform}"
     end
     
     # Adds a system property to the command line.
     def sys_property(name,value)
        add_extra_args "-D#{name}=#{value}"
     end
     
     def logging_conf=(file)
        sys_property("java.util.logging.config.file", file)
     end
     
     # The max. amount of memory (in MB) the new Java process is allowed to
     # take.
     def max_mem=(mem)
        add_extra_args "-Xmx#{mem}M"
     end
     
     # Runs program in debug mode, listening on port +port+.
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
