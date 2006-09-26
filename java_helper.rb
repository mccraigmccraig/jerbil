# for some really weird reasons schemaexport fails on mac os x
# if java is not running in debug mode
$JAVA_DEBUG = RUBY_PLATFORM =~ /darwin/i || false


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
  
  def load_vm(classpath, loggingprops = nil )
    #need verbose java exceptions
    $VERBOSE = true

    jvmargs = []    
    jvmargs <<  "-Djava.util.logging.config.file=#{loggingprops.to_s}" unless loggingprops.nil? 

    if $JAVA_DEBUG
      jvmargs += [
      "-Xdebug",
      "-Xnoagent",
      "-Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n" ]
    end

    begin
      Rjb::load(classpath, jvmargs)
    rescue 
	    $stderr << "could not load java vm: make sure JAVA_HOME is set correctly!\n"
      raise
    end
  end
end


class FileList
  def to_cp  
    cp = ""
    self.each { |file| cp += file + ":" }
    cp[0, cp.length-1]
  end
end

class JavaFileList < Rake::FileList
  attr_reader :srcdir
  attr_reader :dstdir
  attr_accessor :resource_patterns
  
  def initialize(srcdir, dstdir)
    super()
    @srcdir = srcdir
    @dstdir = dstdir
    @resource_patterns = [ "/**/*.xml", "/**/*.yml", "/**/*.rb", "/**/*.txt" ]
    include(srcdir + "/**/*.java")
  end
  
  def to_classes
   to_classfiles.pathmap("%{^#{srcdir}/,}X").sub("/", ".")
  end
  
  def to_classfiles
    self.pathmap("%{^#{srcdir},#{dstdir}}X.class")
  end
  
  
  
  def resources
    r = FileList.new
    resource_patterns.each { |p| r.include(srcdir+p) }
    r
  end 
end

