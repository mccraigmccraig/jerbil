begin
	require 'rjb'
	require 'rake'
rescue LoadError
	require 'rubygems'
	require 'rjb'
	require 'rake'
end

# for some really weird reasons schemaexport fails on mac os x
# if java is not running in debug mode
$JAVA_DEBUG = RUBY_PLATFORM =~ /darwin/i || false
$IS_WINDOWS = RUBY_PLATFORM =~ /mswin|mingw/i
$JAVA_PATH_SEPERATOR = $IS_WINDOWS ? ';' : ':'
$DIR_SEP = $IS_WINDOWS ? "\\" : "/"
$DIR_SEP_FOR_SUBSTITUTION = $IS_WINDOWS ? "\\\\" : "/"

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
  
  def str_list(strings)
    l = empty_list
    strings.each { |s| l.add s.to_s }
    l
  end
  
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
  
  def load_vm(classpath, loggingprops = nil, build_dir = nil ) 
    #need verbose java exceptions
    $VERBOSE = true
    #include build jars and custom classloader
    
    java_home = ENV['JAVA_HOME']
    classpath.include(File.join(java_home, "lib", "tools.jar")) if java_home
    
    classpath.include(File.join(File.dirname(__FILE__), "../../buildsupport/*.jar"))
    classpath.include(File.join(File.dirname(__FILE__), "../../classloader")) unless build_dir.nil?
    
    jvmargs = []    
    jvmargs << "-Djava.util.logging.config.file=#{loggingprops.to_s}" unless loggingprops.nil? 

    if $JAVA_DEBUG
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
        "-Dbuild.root=#{build_dir}", "-Djerbil.debug=false" ] 
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

# Tasks including this module can specifiy additional
# java style arguments.
# 
#
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

class Rake::FileList  
  def to_cp  
    self.join($JAVA_PATH_SEPERATOR)
  end
end

class Rake::TaskLib  
  def depends_on(*args)
    dependencies.concat(args)
  end
  
  def dependencies
    @dependencies ||= []
  end
end

class JavaFileList < Rake::FileList
  attr_reader :srcdir
  attr_reader :dstdir
  attr_accessor :resource_patterns
  
  def initialize(srcdir, dstdir, extensions = nil)
    super([])
    @srcdir = srcdir
    @dstdir = dstdir
    @resource_patterns = []
    copy_extensions = extensions || [ "xml", "properties" ] 
    copy_extensions.each { |ext| add_extension(ext) } 
    include(srcdir + "/**/*.java")
  end
  
  def to_classnames
	# remove the initial directory and separator
	sub = srcdir + $DIR_SEP_FOR_SUBSTITUTION
	paths = self.pathmap("%{^#{sub},}X")
	
	paths.gsub!($DIR_SEP, ".")
	paths.gsub!("/", "." )
  end
  
  def to_classes
    classnames = to_classnames
    classes = classnames.map {|name| Rjb::import(name)}
    classes.to_a
  end
  
  def to_classfiles
    self.pathmap("%{^#{srcdir},#{dstdir}}X.class")
  end
  
  def sourcepath
    srcdir
  end
  
  def resources
    r = FileList.new
    resource_patterns.each { |p| r.include(srcdir+p) }
    r
  end 
  
  def resources_and_target
    resources.each do | r |
      target =  r.sub(/#{srcdir}/, dstdir)
      yield r, target if block_given?
    end
  end
  
  def add_extension(ext)
    @resource_patterns << "/**/*.#{ext}"
  end
  
  def add_extensions(exts)
    @resource_patterns.concat(exts.to_a)
  end

  def dump(files)
	files.each do |f|
		print f + "\n"
	end
  end
end

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
    @java_files.collect{|jf| jf.srcdir}.join($JAVA_PATH_SEPERATOR)
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

