require 'rake/tasklib'
require 'yaml'
require 'set'
require File.dirname(__FILE__) + '/java_helper'


module Rake 
  module HibernateFoo 
    class ExportSchemaTask < TaskLib
      include JavaHelper
      
      attr_accessor :name
      
      attr_accessor :schemafile
      attr_accessor :persistencefile
      attr_accessor :dialect
      
      attr_accessor :package
      
      def initialize(name=:export_schema)
        @name = name
        @dependencies = []
        @package = nil
        @schemafile = "schema.sql"
        @persistencefile = "persistence.yml"
        @dialect = "org.hibernate.dialect.MySQL5Dialect"
        
        yield self if block_given?
        define
      end
      
      def define
        task name => dependencies do |t|       
    
          entities = File.open(persistencefile) {|f| YAML.load(f)}
    
          raise 'no annotated entities found!' if entities.empty?
          
          #puts "found #{entities.size} entities"
          
          entity_classes = entities.map {|klass| Rjb::import(klass)}
          
          schemaexporter = SchemaExporter.new( entity_classes, schemafile, dialect, package )
          schemaexporter.export
        
          schema =  "# -- do not edit ---\n"
          schema << "# generated by hibernate:export_schema at #{Time.new}\n\n"
          
          schema << "drop database trampomail_development;\n"
          schema << "create database trampomail_development;\n"
          schema << "use trampomail_development\n\n"
          
          schema << IO.read(schemafile)
          schema = SqlBeautifier.beautify(schema)
          
          #apt.table_views.each do | table, sql |
          #  schema << "\n\ncreate view #{table} AS #{sql};"
          #end
          
          File.open(schemafile, "w") {|file| file << schema }
        end
      end  
    end
  
    class SqlBeautifier
      def SqlBeautifier.beautify(sql)
        newsql = ""
        sql.to_s.each do |line|
          if line =~ /^create table (\w+) \((.+)\)$/ 
            tablename = $1.strip
            fields = $2.split(',')
            newtabledef = "create table #{tablename} (\n"  
            
            fields.each_with_index do | definition, count |
              newtabledef << "\  #{definition.strip}"
              newtabledef << ",\n" if count < fields.length - 1
            end
            newtabledef << "\n);\n\n"
            newsql << newtabledef
          elsif line =~ /^alter table (\w+) ([^,]+),(.+)+$/
            tablename = $1.strip
            index = $2.strip
            constraint = $3.strip
            newsql << "alter table #{tablename}\n  #{index},\n  #{constraint};\n\n"   
          else
            newsql << line
          end
        end
        newsql
      end
     end
     
     class SchemaExporter
       def initialize(classes, outputfile, dialect, package=nil)
          @exporter = SchemaExporter.get_schema_exporter(classes, dialect, package)
          @exporter.setOutputFile(outputfile)
       end
       
       def export
          @exporter.execute(false,false,false,true)
       end
       
       private
       def SchemaExporter.get_schema_exporter(classes, dialect, package=nil)
        schemaexport = Rjb::import('org.hibernate.tool.hbm2ddl.SchemaExport')
        cfg = get_config(classes, package)
        cfg.getProperties.put('hibernate.dialect', dialect)
           
        schemaexporter = schemaexport.new_with_sig 'Lorg.hibernate.cfg.Configuration;', cfg
        
        raise "could not create schemaexporter" if schemaexporter.nil?
        schemaexporter
      end
    
     
      def SchemaExporter.get_config(classes, package=nil)
        anncfg = Rjb::import('org.hibernate.cfg.AnnotationConfiguration')
        acfg = anncfg.new
        packages = Set.new
        classes.each do |clazz|
          #puts "adding " + clazz.class.to_s
          acfg.addAnnotatedClass(clazz)
          
          pkg = clazz.getPackage
          packages << pkg.getName if pkg.getAnnotations.length > 0
        end
        packages << package unless package.nil?
        packages.each { |pkg| acfg.addPackage(pkg) }
        acfg
      end
    end
  end
end
