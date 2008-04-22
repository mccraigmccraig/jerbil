require 'rake/tasklib'
require 'jerbil/java_helper'
require 'tmpdir'
require 'builder'

module Jerbil
  # A task to create a Mac OS dmg file.
  #
  # == Example
  #   Jerbil::DmgTask.new do |t|
  #     t.classpath = CLASSPATH
  #     t.dmgfile   = "dist/myapp.dmg"
  #     t.appname   = "MyApp"
  #     t.mainclass = "com.foo.myapp.Main"
  #     #optional:
  #     t.vmopts    = ['-Xmx512M'] 
  #     t.depends_on :clean, :compile
  #   end

  class DmgTask < Rake::TaskLib
    include JavaHelper
  
    attr_accessor :name, :classpath, :dmgfile, :files, :appname, :icon, :mainclass,
                  :system_properties, :vmopts, :bundleidentifier, :copyright, :nativelibs, :java_properties
    
    def initialize(name=:dmg)
      @name = name
      @system_properties = {}
      @java_properties   = {}
      @vmopts = ['-Xms512M', '-Xmx1024M']
    
      yield self if block_given?
      raise "must define dmgfile" unless dmgfile
      raise "must define classpath" unless classpath
      raise "must define appname" unless appname
      raise "must define mainclass" unless mainclass
          
      @bundleidentifier ||= mainclass[0...mainclass.rindex('.')]
      @copyright ||= "Copyright #{Time.now.year} Trampoline Systems Ltd."
  
      define
    end
    
    def define # :nodoc:
      directory File.dirname(dmgfile)
      depends_on File.dirname(dmgfile)
      task name => dependencies do |t|
        
        staging_dir  = Dir::tmpdir + "/tmp_" + rand(0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF).to_s
        mac_dist_dir = File.join(staging_dir, appname =~ /\.app$/ ? appname : "#{appname}.app")
        
        contents   = File.join(mac_dist_dir, 'Contents')
        mac_os     = File.join(contents, 'MacOS') 
        resources  = File.join(contents, 'Resources')
        java       = File.join(resources, 'Java')
        native     = File.join(java, 'native')
        info_plist = File.join(contents, 'Info.plist')  
        
        [contents, mac_os, resources, java, native].each {|d| mkdir_p(d) unless File.directory?(d) }

        app_stub   = File.join(File.dirname(__FILE__), '..', 'macosx', 'JavaApplicationStub')
        raise "could not locate app_stub" unless File.exist?(app_stub)
        
        cp app_stub, mac_os
        chmod 0755,  File.join(mac_os, File.basename(app_stub))
        
        cp classpath, java
        cp nativelibs, native if nativelibs
        
        File.open(File.join(contents, 'PkgInfo'), 'w') { |pgkinfo| pgkinfo << 'APPL????' }

        info_dict = {
          :CFBundleDevelopmentRegion => 'English',
          :CFBundleExecutable        => 'JavaApplicationStub',
          :CFBundleGetInfoString     => copyright,
          :CFBundleIdentifier        => bundleidentifier,
          :CFBundleName              => appname,
          :CFBundlePackageType       => 'APPL',
          :CFBundleSignature         => '????',
          :Java => {
            :JVMVersion              => '1.5*',
#            :JVMArchs                => ['i386'],
            :ClassPath               => FileList["#{java}/**/*.jar"].pathmap("$JAVAROOT/%f").join(':'),
            :MainClass               => mainclass,
            :VMOptions               => vmopts.join(' '),
            :Properties => {
              "apple.laf.useScreenMenuBar" => "true",
              "java.library.path"          => "$JAVAROOT/#{File.basename(native)}"  
            }.merge(system_properties),
          }.merge(java_properties),
          :NSHumanReadableCopyright  => copyright
        }
         
        if icon and File.exist?(icon)
          cp icon, resources    
          info_dict[:CFBundleIconFile] = File.basename(icon)
        end
               
        File.open(info_plist, 'w') do |f| 
          x = Builder::XmlMarkup.new(:target => f, :indent => 4)
          serialize_dict = Proc.new do |hash|
            x.dict {
              hash.each do |k,v|
                x.key(k.to_s)
                case v
                  when Hash: serialize_dict.call(v)
                  when TrueClass: x.true  
                  when FalseClass: x.false
                  else x.string(v.to_s)
                end
              end
            }
          end
          x.instruct!
          x << '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' << "\n"
          x.plist(:version=>"1.0") { serialize_dict.call(info_dict) }
        end #write plist
        
        #sh "/Developer/Tools/SetFile -a B #{mac_dist_dir}" if File.exists?('/Developer/Tools/SetFile')
        if File.exists?('/usr/bin/hdiutil')
          sh "hdiutil create -srcdir '#{mac_dist_dir}' -ov #{dmgfile}" 
        else 
          warn "not running on MacOS, not creating dmg file"
        end
      end
    end
  end
end
