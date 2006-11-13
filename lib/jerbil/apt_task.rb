require 'rake'
require 'jerbil/java_helper'
require 'jerbil/javac_task'

module Jerbil

  # A task using Java's {Annotation Processing Tool}[http://java.sun.com/j2se/1.5.0/docs/guide/apt/]
  # (apt) to compile (optional) and process annotations found in the class files.
  #
  # This task can be used to gather a list of all EJB3 entities, or testng annotated classes
  # during the compile step.
  #
  # == Example
  #
  #  desc "compile all java files and find annotations"
  #  Jerbil::AptTask.new(:compile) do |t|
  #    t.java_files = Jerbil::JavaFileList.new("src", "classes")
  #    t.find_annotation 'javax.persistence.Entity' do |entities|
  #       File.open(ANNOTATED_CLASSES, 'w') { |f| f << entities.to_yaml }
  #    end
  #  end
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
        
    
    def supportedOptions # :nodoc:
      empty_list
    end

    def supportedAnnotationTypes # :nodoc:
      list = empty_list
      annotations.each_key { |a| list.add a.to_s }
      list
    end
    
    def getProcessorFor(set,env) # :nodoc:
      @env = env
      Rjb::bind(self, 'com.sun.mirror.apt.AnnotationProcessor')
    end
    
    # this is needed by java - the factory gets stored internally
    # in a map, so it needs to return a hash code.
    def hashCode # :nodoc:
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
    
    # Registers an annotation handler for all annotations with name +annotation+.
    # Handlers (code blocks) will be invoked after successful compilation, in #post_compile.
    # See AptTask for an example.
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
    
    # A convenience method to serialize a list of found annotations 
    # to file +filename+ (yaml format).
    def annotated_classes_to_yaml(annotation, filename)
      find_annotation annotation do |classes|
        File.open(filename, 'w') { |f| f << classes.to_a.uniq.to_yaml }
      end
    end
        
    protected   
    def compile(parameters, printwriter)
      apt = Rjb::import('com.sun.tools.apt.Main')
      parameters << "-nocompile" if nocompile
      apt.process(get_processor_factory, printwriter, parameters )
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
    
    # Calls all registered handlers.
    def post_compile
      super unless nocompile
      @found_annotations.each do |name, types|
        handler = @found_annotations_handler[name]        
        handler.call(types) unless handler.nil?
      end
    end
    
    def get_processor_factory # :nodoc:
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

