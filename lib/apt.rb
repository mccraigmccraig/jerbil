
require File.dirname(__FILE__) + '/java_helper'

# Apt helper class - uses annotation processor API to identify annotations.
#	Based on
#	http://weblogs.java.net/blog/ss141213/archive/2005/12/how_to_automati.html
#   TODO: wrap compile/processing step in one?


class Apt
  include JavaHelper

  $APT_DEBUG = false
  attr_accessor :entities, :entity_classes, :table_views
  
  def initialize(javafiles, classpath)
    @javafiles = javafiles
    @classpath = classpath
    @entities = []
    @entity_classes = []
    @table_views = Hash.new
  end
  
  def process_annotations(args = nil)
    parms = [ "-nocompile", "-classpath", @classpath ]
    parms += @javafiles.to_a
    parms += args.to_a

    apt = Rjb::import('com.sun.tools.apt.Main')

    factory = get_factory

    puts "start processing" if $APT_DEBUG
    
    ret = 0
    aptout = printWriter_to_s do |pw|
      ret = apt.process( factory, pw, parms )
    end
 
    raise "Apt error:\n#{aptout}" unless ret == 0
    puts "done processing" if $APT_DEBUG
  end

  def get_factory
    Rjb::bind(self, 'com.sun.mirror.apt.AnnotationProcessorFactory')
  end
 
  # AnnotationFactory methods
  def supportedOptions
    #returns collection of strings
    empty_list
  end

  def supportedAnnotationTypes
    #returns collection of strings
    puts "supportedAnnotationTypes()" if $APT_DEBUG
    list = empty_list
    list.add 'javax.persistence.Entity'
    list.add 'trampothing.annotations.ViewTable'
    list
  end

  def getProcessorFor(set, env)
    puts "getProcessorFor #{set.toString}, #{env.toString}" if $APT_DEBUG
    @env = env
    Rjb::bind(self, 'com.sun.mirror.apt.AnnotationProcessor')
  end

  #AnnotationProcessor methods
  def process
   
    specTypeDecls = @env.getSpecifiedTypeDeclarations 
  
    add_each(specTypeDecls)

    specTypeDecls.each do |specType|
      enhance_type(specType)

      if specType.is_entity?
          puts "#{specType.getQualifiedName}" if $APT_DEBUG
          @entities << "#{specType.getQualifiedName}"
          @entity_classes << Rjb::import(specType.getQualifiedName)
      end
      
      if specType.has_annotation?('trampothing.annotations.ViewTable') and
         specType.has_annotation?('javax.persistence.Table')
          
         tablename = specType.get_annotation('javax.persistence.Table').name
         sql= specType.get_annotation('trampothing.annotations.ViewTable').sql
         puts "table #{tablename} with sql #{sql}" if $APT_DEBUG   
         @table_views[tablename] = sql
      end
    end
  end
  
  def hashCode
    123456
  end 
  
  # adds some extra convenience methods
  private 
  def enhance_type(a_type)
    has_annotation = %q{
        def has_annotation?(annotation)
          getAnnotation(Rjb::import(annotation)) != nil  
        end
    }
    
    is_entity = %q{
        def is_entity?
          has_annotation?('javax.persistence.Entity')
        end
    }
    
    get_annotation = %q{
        def get_annotation(annotation)
            getAnnotation(Rjb::import(annotation)) 
        end
    }
   
    a_type.instance_eval(has_annotation)
    a_type.instance_eval(is_entity)  
    a_type.instance_eval(get_annotation)
  end
  
  def add_each(obj)
     each_method = %q{
        def each
          it = iterator()
          while it.hasNext
            yield(it.next)
          end
        end
      }
      obj.instance_eval(each_method)
  end
end

