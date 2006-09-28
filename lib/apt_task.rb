require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'
require File.dirname(__FILE__) + '/javac_task'

# Apt helper class - uses annotation processor API to identify annotations.
#	Based on
#	http://weblogs.java.net/blog/ss141213/archive/2005/12/how_to_automati.html
#   TODO: wrap compile/processing step in one?


module Rake
  class AptTask < JavacTask

    attr_accessor :annotations
    attr_accessor :nocompile
    
    def initialize(name)
      @annotations = {}
      @nocompile = false
      @found_annotations = {}
      @found_annotations_handler = {}
      super
    end
    
    
    def supportedOptions
      empty_list
    end

    def supportedAnnotationTypes
      list = empty_list
      annotations.each_key { |a| list.add a.to_s }
      list
    end
    
    def getProcessorFor(set,env)
      @env = env
      Rjb::bind(self, 'com.sun.mirror.apt.AnnotationProcessor')
    end
    
    def hashCode
      123456
    end 
    
    def process  
      add_each(@env.getSpecifiedTypeDeclarations).each do |specType|
        begin
          check_type(specType)
        rescue
          puts $!
        end
      end   
    end
    
    def check_type(type)
      enhance_type(type)
      annotations.each do | annotation, handler |
        if type.has_annotation?(annotation)
          handler.call(type)
        elsif type.is_classdecl?  
          methods = type.getMethods
          add_each(methods).each do |m|
            check_type(m)
          end      
        end
      end
    end
    
    def find_annotation(annotation, options={}, &handler)
      defopts = { :scope => :class }
      defopts.merge! options
      annotations[annotation] = Proc.new { |spec|
           t = spec.getDeclaringType || spec
           @found_annotations[annotation] ||= []
           @found_annotations[annotation] << t.toString
      }
      @found_annotations_handler[annotation] = handler
    end
    
    
    protected   
    def compile(parameters, printwriter)
      apt = Rjb::import('com.sun.tools.apt.Main')
      parameters << "-nocompile" if nocompile
      apt.process(get_processor_factory, printwriter, parameters )
    end
    
    def post_compile
      super
      @found_annotations.each do |name, types|
        handler = @found_annotations_handler[name]        
        handler.call(types) unless handler.nil?
      end
    end
    
    def get_processor_factory
       Rjb::bind(self, 'com.sun.mirror.apt.AnnotationProcessorFactory')
    end
    
    
    private 
    def enhance_type(a_type)
      has_annotation = %q{
          def has_annotation?(annotation)
            getAnnotation(Rjb::import(annotation)) != nil  
          end
      }
       
      get_annotation = %q{
          def get_annotation(annotation)
              getAnnotation(Rjb::import(annotation)) 
          end
      }
      
      is_classdecl = %q{
         def is_classdecl?
            Rjb::import("com.sun.mirror.declaration.ClassDeclaration").isAssignableFrom(getClass)
         end
      }
     
      a_type.instance_eval(has_annotation)
      a_type.instance_eval(get_annotation)
      a_type.instance_eval(is_classdecl)    
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
        obj
    end
  end
end

