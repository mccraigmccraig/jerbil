begin
	require 'rjb'
	require 'rake'
rescue LoadError
	require 'rubygems'
	require 'rjb'
	require 'rake'
end

module Jerbil
  # for some really weird reasons schemaexport fails on mac os x
  # if java is not running in debug mode
  JAVA_DEBUG = ::RUBY_PLATFORM =~ /darwin/i || false
  IS_WINDOWS = RUBY_PLATFORM =~ /mswin|mingw/i
  JAVA_PATH_SEPERATOR = IS_WINDOWS ? ';' : ':'
  DIR_SEP = IS_WINDOWS ? "\\" : "/"
  DIR_SEP_FOR_SUBSTITUTION = IS_WINDOWS ? "\\\\" : "/"
  
  # The JavaHelper module provides common helper functionality needed across different
  # classes.
  module JavaHelper
  
    # Provides the block with an instance of java.io.PrintStream and returns
    # all text printed to it as ruby-typed string.
    def printStream_to_s(&block) # :yields: printstream
      yieldIO('java.io.PrintStream', block)
    end
   
    
    # Provides the block with an instance of java.io.PrintWriter and returns
    # all text printed to it as ruby-typed string.
    def printWriter_to_s(&block) # :yields: printwriter
      yieldIO('java.io.PrintWriter', block)
    end
    
    def yieldIO(klass, block) # :nodoc:
      out = Rjb::import('java.io.ByteArrayOutputStream').new
      ps = Rjb::import(klass.to_s).new_with_sig 'Ljava.io.OutputStream;', out    
      block.call(ps)
      ps.flush
      st = Rjb::import('java.lang.String').new_with_sig '[B', out.toByteArray
      String.new(st.toString)
    end
    
    # Returns an empty instance of <em>java.util.List</em>.
    def empty_list
      Rjb::import('java.util.ArrayList').new
    end
    
    # Returns an instance of java.util.List, populated with all
    # string found in +strings+.
    def str_list(strings)
      l = empty_list
      strings.each { |s| l.add s.to_s }
      l
    end
    
    # Serializes +obj+ using standard Java serialization. The result
    # is returned as bytearray.
    def serialize(obj)
      byteoos = Rjb::import('java.io.ByteArrayOutputStream').new
      oosKlass = Rjb::import('java.io.ObjectOutputStream')
      oos = oosKlass.new_with_sig 'Ljava.io.OutputStream;', byteoos
      begin
        oos.writeObject(obj)
      ensure
        oos.close
      end 
      byteoos.toByteArray
    end
    
    # Loads the java virtual machine. This method should only be invoked once, typically
    # before task definitions in a Rakefile.
    #
    # +classpath+:: a Rake::FileList containing the initial classpath. 
    # +build_dir+:: an optional directory (or list of directories) which will be used to resolve classes at runtime.
    # +loggingprops+:: the location of a java.util.logging configuration file.
    def load_jvm(classpath, build_dir = nil, loggingprops = nil ) 
      #need verbose java exceptions
      $VERBOSE = true
    
      #include tools.jar from JDK (needed for javac etc.)
      java_home = ENV['JAVA_HOME']
      classpath.include(File.join(java_home, "lib", "tools.jar")) if java_home    
      #include build jars and custom classloader
      classpath.include(File.join(File.dirname(__FILE__), "../../buildsupport/*.jar"))
      classpath.include(File.join(File.dirname(__FILE__), "../../classloader")) unless build_dir.nil?
      
      jvmargs = []    
      jvmargs << "-Djava.util.logging.config.file=#{loggingprops.to_s}" unless loggingprops.nil? 
       
      if JAVA_DEBUG || ENV['JAVA_DEBUG']
        jvmargs += [
        "-Xdebug",
        "-Xnoagent",
        "-Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n" ]
      end
      
      #java_home = ENV['JAVA_HOME']    
      #ENV['LD_LIBRARY_PATH'] = "#{java_home}/jre/lib/i386:#{java_home}/jre/lib/i386/client"
      
      #puts "lib:" + ENV['LD_LIBRARY_PATH']
      #jvmargs << "-Djava.library.path=#{ENV['JAVA_HOME']}/jre/lib/i386"
      
      if build_dir
        jvmargs += [ "-Djava.system.class.loader=JerbilClassLoader", 
          "-Djerbil.build.root=#{build_dir.to_a.join(':')}", "-Djerbil.debug=false" ] 
      else      
        $stderr << "jerbil: build_dir not set: dynamic classloading is disabled\n" if Rake.application.options.trace
      end
           
      begin
        Rjb::load(classpath.to_cp, jvmargs)
      rescue 
        $stderr << "could not load java vm: make sure JAVA_HOME is set correctly!\n"
        raise
      end
     
      #TODO: test javac main and raise if not found
    end
  end
  
  # Tasks including this module can easily specify additional
  # Java-style arguments (like -verbose, -gc).
  # 
  # == Example
  #
  #     Jerbil::MyExtraArgumentTakingTask.new do |t|
  #       t.source = '1.5'
  #       t.options :wibble, :wobble
  #     end
  #
  # results in a command line of the form "-source 1.5 -wibble -wobble".  
  module ExtraArgumentTaking      
      def self.append_features(base)
        super         
        class << base        
          def create_alias_for(actual, new)
            @@aliases ||= {}
            @@aliases[new.to_s] = actual.to_s         
          end     
        end
      end
        
      attr_reader :extra_args
      
      def options(*args)
        args.each {|a| self.send(a)}
      end
      
      def add_files(files)
        add_extra_args files.to_a
      end
            
      def add_extra_args(*args)
        @extra_args = [] if extra_args.nil?
        @extra_args += args.flatten
      end
             
      def method_missing(symbol, *args)   
        arg = symbol.to_s.sub(/=/, "")
        if @@aliases && @@aliases.has_key?(arg)   
          arg = @@aliases[arg]  
        end
        add_extra_args "-#{arg}", args
      end
  end
  
  # A JavaFileList is a specialisation of a standard Rake::FileList.
  # It includes additional methods to deal with build dirs, resources 
  # and other java specifics.
  class JavaFileList < Rake::FileList
    attr_reader :srcdir
    attr_reader :dstdir
    attr_accessor :resource_patterns
    
    # srcdir:: the directory containing the Java source file. 
    # dstdir:: destination directory for class files (used by JavacTask).
    # extensions:: a list of extensions to treat as resources. The default is to treat
    # all files not ending in .java as resources.           
    def initialize(srcdir, dstdir, extensions = nil)
      super([])
      @srcdir = srcdir
      @dstdir = dstdir
      @resource_patterns = []     
      add_extensions(extensions)
      include(srcdir + "/**/*.java")
    end
    
    # Returns a list of all java source files formatted as java class names.
    # For example src/org/foo/Baz -> org.foo.Baz.
    def to_classnames
      # remove the initial directory and separator
      sub = srcdir + DIR_SEP_FOR_SUBSTITUTION
      paths = self.pathmap("%{^#{sub},}X")
      
      paths.gsub!(DIR_SEP, ".")
      #paths.gsub!("/", "." )
    end
    
    # Returns a list of Java classes. This method uses Rjb::import to
    # load the specified classes into the virtual machine.
    def to_classes
      classnames = to_classnames
      classes = classnames.map {|name| Rjb::import(name)}
      classes.to_a
    end
    
    # Translates all java source files into their corresponding class destination
    # files, based on +dstdir+.
    #
    # For example src/org/foo/Baz.java -> classes/org/foo/Baz.class.
    def to_classfiles
      self.pathmap("%{^#{srcdir},#{dstdir}}X.class")
    end
    
    def sourcepath
      srcdir
    end
    
    # Returns a Rake::FileList containing all resources found in +srcdir+.
    # Resources are typically files in +srcdir+ with extensions other than .java 
    # (properties, xml, ...). If you want to copy specfic resources register 
    # extensions using #add_extension.
    def resources
      r = FileList.new
      if resource_patterns.empty? 
        r.include(srcdir + "/**/*.*")    
        r.exclude(srcdir + "/**/*.java")     
      else     
        resource_patterns.each { |p| r.include(srcdir+p) }
      end
      r
    end 
    
    # Calls block once for each resource found in +srcdir+, passing
    # the source and destination file as parameter.
    def resources_and_target
      resources.each do | r |
        target =  r.sub(/#{srcdir}/, dstdir)
        yield r, target if block_given?
      end
    end
    
    # Registers a resource extension.
    # 
    #   add_extension("xml")  => all xml files 
    # 
    def add_extension(ext)
      @resource_patterns << "/**/*.#{ext}"
    end
    
    # Registers a list of extensions.
    def add_extensions(exts)
      exts.to_a.each {|ext| add_extension(ext)}      
    end    
  end
  
  # A MultiJavaFileList is a container object for holding several JavaFileList
  # objects. This is useful for multidirectory builds.
  #
  # == Example
  #   SOURCE_DIR = "src"
  #   MODULES    = [ "a", "b" ]
  #   JAVA_BUILD_DIR = "classes"
  #   JAVA_FILES = MultiJavaFileList.new(MODULES, JAVA_BUILD_DIR, SOURCE_DIR)
  #
  # This will look for source files in +a/src+ and +b/src+, compiling into +classes+.
  class MultiJavaFileList
  
    attr_reader :modules, :dstdir
    
    def initialize(modules, dstdir, srcprefix = "src", copypat = nil) 
      @java_files = []
      @modules = modules
      @dstdir = dstdir
      modules.each do | m |
        srcdir = File.join(m, srcprefix)
        @java_files << JavaFileList.new(srcdir, dstdir, copypat )
      end
    end
    
    def sourcepath
      @java_files.collect{|jf| jf.srcdir}.join(JAVA_PATH_SEPERATOR)
    end
    
    def srcdir
      @java_files.collect{|jf| jf.srcdir}
    end
    
    def to_a
      files = []
      @java_files.each do |f|
        files += f
      end
      files
    end
    
    def to_ary
      to_a
    end  
    
    def resources
      res = []
      @java_files.each do |f|
        res += f.resources  
      end
      res
    end
    
    def resources_and_target
      @java_files.each do |jf|
        jf.resources_and_target do |r,t|
          yield r,t
        end
      end
    end
    
    def gsub!( replace, replace_with )
      @java_files.each{ |f| f.gsub!( replace, replace_with ) }
    end
  end
end

module Rake
  class FileList  
    # Returns the filelist formatted as Java classpath.
    # ("/tmp/foo.jar:/tmp/baz.jar")
    def to_cp(sep = Jerbil::JAVA_PATH_SEPERATOR)
      self.join(sep)
    end
  end
  
  class TaskLib  
    # Adds a dependency to the given task
    def depends_on(*args)
      dependencies.concat(args)
    end
   
    def dependencies
      @dependencies ||= []
    end
  end
end


