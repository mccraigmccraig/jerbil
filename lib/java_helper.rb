
require 'rjb'
require 'rake'

# for some really weird reasons schemaexport fails on mac os x
# if java is not running in debug mode
$JAVA_DEBUG = RUBY_PLATFORM =~ /darwin/i || false
$IS_WINDOWS = RUBY_PLATFORM =~ /mswin|mingw/i
$JAVA_PATH_SEPERATOR = $IS_WINDOWS ? ';' : ':'

module JavaHelper
  def printStream_to_s(&block)
    yieldIO('java.io.PrintStream', block)
  end
 
  def printWriter_to_s(&block)
    yieldIO('java.io.PrintWriter', block)
  end
  
  def yieldIO(klass, block)
    out = Rjb::import('java.io.ByteArrayOutputStream').new
    ps = Rjb::import(klass.to_s).new_with_sig 'Ljava.io.OutputStream;', out    
    block.call(ps)
    ps.flush
    st = Rjb::import('java.lang.String').new_with_sig '[B', out.toByteArray
    String.new(st.toString)
  end
  
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
    classpath.include(File.join(File.dirname(__FILE__), "../buildsupport/*.jar"))
    classpath.include(File.join(File.dirname(__FILE__), "../classloader")) unless build_dir.nil?
    
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
    
    jvmargs += [ "-Djava.system.class.loader=JerbilClassLoader", 
      "-Dbuild.root=#{build_dir}" ] unless build_dir.nil?
    
    begin
    	Rjb::load(classpath.to_cp, jvmargs)
    rescue 
	    $stderr << "could not load java vm: make sure JAVA_HOME is set correctly!\n"
      raise
    end
  end
end


class FileList  
  def to_cp  
    self.join($JAVA_PATH_SEPERATOR)
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
	  self.pathmap("%{^#{srcdir}/,}X").gsub("/", ".")
  end
  
  def to_classes
    to_classnames.map {|name| Rjb::import(name)}.to_a
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
end

