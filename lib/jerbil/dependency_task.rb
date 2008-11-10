require 'rake'
require 'rake/tasklib'
require 'yaml'

# Simple dependency management - fetch sources from svn / cvs / etc.
module Jerbil
  class DependencyTask < Rake::TaskLib
    attr_accessor :name, :details
  
    def initialize(name, details, dest_dir=File.join(Rake.original_dir, 'lib-src'))
      @name     = name
      @details  = details
      @dest_dir = dest_dir
      yield self if block_given?
      define
    end
  
    def self.load(file='dependencies.yml')
      YAML.load_file(file).each { |name, details| DependencyTask.new(name, details) }
    end
    
    def dest_dir;  File.join(@dest_dir, details['destdir'] || name); end
    def patch_dir; File.join(Rake.original_dir, 'patches', name, details['tag'] || 'default'); end
    
    def in_lib_src_dir(&body_proc)
      FileUtils.mkdir_p(@dest_dir)
      Dir.chdir( @dest_dir ) do
        body_proc.call
      end
    end
    
    def define
      namespace "deps:#{name}" do      
      desc "get #{name} sources"
      task :get => [] do |t|
        in_lib_src_dir do
          unless File.directory?(dest_dir)
            if details.has_key?('cvs')
              sh "cvs -z3 -d#{details['cvs']} export -r#{details['tag'] || 'HEAD'} -d#{File.basename(dest_dir)} #{details['module']}"   
            elsif details.has_key?('svn')
            
              user     = details['user'] ? "--username #{details['user']}" : ''
              password = details['password'] ? "--password #{details['password']}" : ''
              revision = details['revision'] ? "--revision #{details['revision']}" : ''
            
              sh "svn checkout #{details['svn']} #{revision} #{user} #{password} #{dest_dir}"
            elsif details.has_key?('zip')
              zip_loc  = details['zip']
              filename = zip_loc[zip_loc.rindex('/')+1..-1]  
              sh "wget #{zip_loc}" unless File.exists?(filename)
              sh "unzip #{filename}"
            else raise "unkown repository type"
            end
          end
        end
      end
  
      has_patches = File.directory?(patch_dir)
      if has_patches
        desc "download and patch #{name}"
        task :patch => [:get] do |t|
          tstamp = File.join(dest_dir, 'patch.tstamp')
          patches = Dir["#{patch_dir}/*.patch"]
        	unless uptodate? tstamp, patches
        		Dir.chdir(dest_dir) do
        			patches.each do |p|
        				sh "patch -p0 < #{p}"
        			end
        		end
        		FileUtils.touch(tstamp)
        	end
        end
      end
    
      if details['buildcmd']
        desc "fetches #{name}, applies patches and builds"
        task :build => [has_patches ? :patch : :get]  do
          Dir.chdir(dest_dir) do
            sh details['buildcmd']
          end
        end
      end
    end
    end
  end
end