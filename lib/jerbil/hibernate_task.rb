require 'rake'
require 'rake/tasklib'
require 'jerbil/java_helper'
require 'jerbil/inflector'
require 'yaml'
require 'set'

module Jerbil 
  module Hibernate 
    # Generates a SQL schema from EJB3/Hibernate-annotated classes like Hibernate's
    # SchemaExport tool. Typically Jerbil::AptTask is used to compile source files and
    # gather a list of entities which then gets serialized to a YAML file.
    # ExportSchemaTask then reads this file and uses Hibernate's schema exporting 
    # features to generate SQL. Optionally the schema can be validated, to check 
    # whether any column or table names are reserved keywords (validate :sql) or
    # conform to ActiveRecord convention (validate :rails).
    #
    # == Example
    #   Jerbil::Hibernate::ExportSchemaTask.new(:export_schema) do |t|
    #       t.schemafile = "schema.sql"
    #       t.entities_yml = ENTITIES_YML   
    #       t.validate = :all
    #   end
    class ExportSchemaTask < Rake::TaskLib
      include JavaHelper
      
      attr_accessor :name
      
      # SQL schema destination file (default: schema.sql)
      attr_accessor :schemafile
			
      # A file containing a list of entities (<em>javax.persistence.Entity</em>),
      # serialized as a list of strings (YAML format).
      attr_accessor :entities_yml

      # a file containing a map of properties, property names are keys in the map, and
      # property values are values in the map
      attr_accessor :properties_yml
			
      # Classname implementing the db dialect, defaults to
      # <em>org.hibernate.dialect.MySQL5Dialect</em>
      attr_accessor :dialect
			
      # SQL statements to be executed before generated sql.
      attr_accessor :preamble
      attr_accessor :epilogue
			
      # FQN of a package containing package-info.java to be used by
      # hibernate.
      attr_accessor :package
      
      # Pretty printing of generated SQL (default: true)
      attr_accessor :prettyprint

      # name of a java system property to set when exporting schema
      attr_accessor :system_property_name

      # value of java system property to set when exporting schema
      attr_accessor :system_property_value
      
      def initialize(name=:export_schema)
        @name = name
        @dependencies = []
        @classfilter = nil
        @prettyprint = true
        @validate = []
        @schemafile = "schema.sql"
        @entities_yml = "entities.yml"
        @properties_yml = nil
        @dialect = "org.hibernate.dialect.MySQL5Dialect"
        @sql_reserved = nil
        @system_property_name = nil
        @system_property_value = nil

                
        yield self if block_given?
        define
      end           
      
      def define # :nodoc:
        task name => dependencies do |t|       
            with_system_property( @system_property_name , @system_property_value ) do
                entities = File.open(entities_yml) {|f| YAML.load(f)}

                raise 'no annotated entities found!' if entities.empty?

                #puts "found #{entities.size} entities"
                entities = entities.dup.select { |e| @classfilter.call(e) } if @classfilter
                entity_classes = entities.map {|klass| Rjb::import(klass)}

                properties = (YAML.load_file(@properties_yml) if @properties_yml) || {}

                cfg = get_config(entity_classes, properties, package)

                validate_config(cfg) unless validate.empty?
                sql = cfg.generateSchemaCreationScript(Rjb::import(dialect).new)

                schema =  "# -- do not edit ---\n"
                schema << "# generated by Jerbil::Hibernate::ExportSchemaTask at #{Time.new}\n\n"

                schema << preamble << "\n" if preamble

                sql.each do |s|
                  s = format(s) if prettyprint
                  schema << "#{s};"
                end

                schema << "\n\n#{epilogue}" if epilogue

                File.open(schemafile, "w") {|file| file << schema }
            end
        end
        file schemafile => name
        task name => entities_yml
      end

      # Filters all entities. Useful to only export schema for a subset of classes.
      # ====Example
      # Jerbil::Hibernate::ExportSchemaTask.new(:export_schema) do |t|
      #    t.filter { |classname| classname =~ /^foo/ }    
      #  end
      def filter(*args, &block)
          @classfilter = block
      end
      
      # Validate configuration (options: :all, :sql, :rails)
      def validate(*what)
        @validate.concat(what)
      end
      
      # Exposes the inflections instance so exceptions can be registered.
      def inflections
        yield Inflector::Inflections.instance if block_given?
      end
        
      protected
      def get_config(classes, properties, package=nil)
        anncfg = Rjb::import('org.hibernate.cfg.AnnotationConfiguration')
        acfg = anncfg.new
        packages = Set.new
        classes.each do |clazz|
          #puts "adding " + clazz.class.to_s
          acfg.addAnnotatedClass(clazz)
          
          pkg = clazz.getPackage
          packages << pkg.getName if pkg && pkg.getAnnotations.length > 0
        end
        packages << package if package
        packages.each { |pkg| acfg.addPackage(pkg) }
                
        properties.each do |key,value|
          acfg.setProperty(key, value)
        end
        
        acfg
      end
      
      def format(sql)
        Rjb::import('org.hibernate.pretty.DDLFormatter').new(sql).format      
      end       

      def reserved_words
        if @sql_reserved.nil?
          @sql_reserved = {}          
          Dir[File.join(File.dirname(__FILE__), "..", "..", "sql_reserved_words", "**")].each do |file|
            @sql_reserved[File.basename(file)] = File.readlines(file).map{|s|s.chomp}
          end
        end
        @sql_reserved
      end

      def check_reserved_word(word)
        offending_dialects = []
	      reserved_words.each do |dialect, wordlist|
		      offending_dialects << dialect.to_s if wordlist.include?(word.upcase)	
        end
	      offending_dialects
      end

      def validate?(what)
        @validate.include?(:all) || @validate.include?(what)
      end
      
      def validate_config(cfg)
        cfg.buildMappings
        class_mappings = cfg.getClassMappings

        invalid_tables  = []
        invalid_columns = []
        invalid_words   = []
               
        while class_mappings.hasNext         
          cmap = class_mappings.next
        
          simple_name = cmap.getMappedClass.getSimpleName
          table_name  = cmap.getTable.getName                 
            
          #only check table semantics for toplevel classes
          if cmap.getRootClass.equals(cmap)                               
            if validate?(:sql)
              dialect_probs = check_reserved_word(table_name)        
              unless dialect_probs.empty?
                $stderr << "[#{simple_name}] table name '#{table_name}' is a reserved keyword in dialects: #{dialect_probs.join(', ')}\n" if verbose
                invalid_words << table_name
              end
            end
        
            if validate?(:rails)
              expected_table_name = Inflector::tableize(simple_name).sub(/^hibernate_/, '')
              if expected_table_name != table_name && check_reserved_word(expected_table_name).empty?
                $stderr << "[#{simple_name}] invalid table: '#{table_name}', should be '#{expected_table_name}'\n" if verbose
                invalid_tables << table_name
              end
            end
          end
        
          # column checks
          property_it = cmap.getPropertyIterator
          while property_it.hasNext
            prop = property_it.next
            prop_name = prop.getName
        
            column_it = prop.getColumnIterator
            next unless column_it.hasNext
        
            col_name = column_it.next.getName
        
            if validate?(:sql)
              dialect_probs = check_reserved_word(col_name)
              unless dialect_probs.empty?
                $stderr << "[#{simple_name}] column name '#{col_name}' in '#{table_name}' is a reserved keyword in dialects: #{dialect_probs.join(', ')}\n" if verbose
                invalid_words << col_name
              end
            end
        
            #ignore association types for now (TODO)
            next if prop.getType.isAssociationType
        
            if validate?(:rails)
              expected_col_name = Inflector::underscore(prop_name)
          
              if expected_col_name != col_name && check_reserved_word(expected_col_name).empty?
                $stderr << "[#{simple_name}] invalid column: '#{table_name}.#{col_name}', should be '#{expected_col_name}'\n" if verbose
                invalid_columns << col_name
              end
            end
          end
        end
                
        raise "ExportSchemaTask: validation errors, not exporting" if !invalid_tables.empty? || !invalid_columns.empty? || !invalid_words.empty?
      end #validate config
      
    end #export schema task
  end # Hibernate
end

