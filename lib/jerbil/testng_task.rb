require 'rake'
require 'rake/tasklib'
require 'set'
require 'builder'
require 'jerbil/java_helper'

module Jerbil
  module TestNG
    # A task to run testng[http://testng.org] test suites or individual tests.
    #
    # == Example
    #
    #   Jerbil::TestNG::TestNGTask.new(:test) do |t|
    #     t.outputdir = TESTOUTPUTDIR
    #     t.tests     = JAVA_TEST_FILES
    #     t.depends_on :test_compile
    #   end
    #
    # The test classes can be specified by passing a Jerbil::JavaFileList to 
    # +tests+, or by setting the location of xml test suites using +suites+.
    class TestNGTask < Rake::TaskLib
      include JavaHelper
      
      attr_accessor :name
			
			# A JavaFileList specifing tests to run. TestNGTask will use
			# +to_classes+ to obtain the class files from the list.
      attr_accessor :tests
			
			# Where the testng output should go. Default "test-output".
      attr_accessor :outputdir
			
			# Whether to generate HTML reports. Defaults to +true+.
      attr_accessor :report
			
			# A list of locations of testng suite.xml files.		
      attr_accessor :suites
			
			# Working dir to use during test execution.
      attr_accessor :workingdir
			
			# A list of test listeners to use. Defaults to DefaultTestListener 
			# if empty.
			attr_accessor :listeners					
      
      def initialize(name)
        @name = name
        @tests = []
        @outputdir = "test-output"
        @report = true
        @suites = []
        @workingdir = nil 
				@listeners = []
        yield self if block_given?
        depends_on workingdir unless workingdir.nil?
        depends_on outputdir
        define
      end
      
      def define # :nodoc:
	  	desc "run testng tests" if Rake.application.last_comment.nil?
        task name => dependencies do |t|
          testng = Rjb::import('org.testng.TestNG').new_with_sig 'Z', false
         
          listeners << DefaultTestListener.new if listeners.empty?
    
					sl = SuiteListener.new
          
          #need to use _invoke because addListener has 3 different method signatures
          #using same name and return type
          #testng.addListener(Rjb::bind(tl, 'org.testng.ITestListener'))
					listeners.each do |tl|  
            testng._invoke('addListener', 'Lorg.testng.ITestListener;', Rjb::bind(tl, 'org.testng.ITestListener'))
          end
					
					#testng.addListener(Rjb::bind(sl, 'org.testng.ISuiteListener'))
          testng._invoke('addListener', 'Lorg.testng.ISuiteListener;', Rjb::bind(sl, 'org.testng.ISuiteListener'))
                
          if report
            testng.addListener(Rjb::import('org.testng.reporters.SuiteHTMLReporter').new)
            testng.addListener(Rjb::import('org.testng.reporters.TestHTMLReporter').new)
          end
         
          if suites.empty? && tests.respond_to?(:to_classes)
            testng.setTestClasses( tests.to_classes )
          else
            testng.setTestSuites( str_list(suites) )
          end
          
          #testng.setExcludedGroups( excludedgroups ) unless excludedgroups.nil?
          testng.setOutputDirectory( outputdir )
          #testng.setParallel(true)
          testng.setVerbose( 1 )
          
          if workingdir.nil?
            testng.run
          else
            Dir.chdir(workingdir) { testng.run }
          end
      
					message = "some tests failed"
					if listeners.first.kind_of?(DefaultTestListener)
						message += ": #{listeners.first.failed_to_s}"
					end
          raise message unless testng.getStatus == 0
        end
        directory workingdir unless workingdir.nil?
        directory outputdir
      end
    end
    
    # A TestNG test listener imlemented in ruby. It mimics Ruby's standard testrunner.
    class DefaultTestListener
      include JavaHelper

        attr_reader :failed_classes
        def initialize # :nodoc:
          @failed_classes = Set.new
          @outfile = nil
        end
        
        def onFinish(context)
          @outfile.close unless @outfile.nil?
        end
        
        def onStart(context)
          open_log(context)
        end
  
        def onTestFailedButWithinSuccessPercentage(result)
        end
        
        def onTestFailure(result)
          $stderr.print "F" unless Rake.application.options.trace
          
          @failed_classes.add result.getTestClass.getName
          begin
            log "Failure: " + get_test_name(result)
            log result.getThrowable.getMessage
            log printStream_to_s {|ps| result.getThrowable.printStackTrace(ps) }
            log "------------------------------------------------------------------------"
          rescue 
            $stderr.puts $!
          end        
        end
        
        def onTestSkipped(result)
		  $stderr.print "S" unless Rake.application.options.trace
          log "skipped test " + get_test_name(result)
        end
        
        def onTestStart(result)		
          log "starting test " + get_test_name(result)
          @outfile.flush
        end
        
        def onTestSuccess(result)
          $stderr.print "." unless Rake.application.options.trace      
        end
     
        # Returns a string describing all failed classes.
        def failed_to_s
          @failed_classes.to_a.join(', ')   
        end
                
        private 
        def get_test_name(result)
          "#{result.getTestClass.getName}.#{result.getMethod.getMethodName}"
        end
        
        def open_log(context)
          if @outfile.nil?
            file = File.join(context.getOutputDirectory, "#{context.getName}.output")
            @outfile = File.open( file , "w") 
          end
        end
        
        def log(s)
          @outfile.puts(s.to_s) if @outfile
          $stderr.puts(s.to_s) if Rake.application.options.trace
        end 
      end
      
      # A Ruby implementation of a TestNG suite listener.
      class SuiteListener
        def onStart(suite)
          #@start = Time.new
        end
        
        def onFinish(suite)
          puts
          #puts "tests finished in #{@start-Time.new} secs"
        end
      end
    
    
      class << self
      
        # Helper method to create a testng xml suite file.
        # +filename+:: destination file for suite file.
        # +classnames+:: a list of test class names.
        # +suitename+:: name of the suite.
        # +onetest+:: whether all tests should be rolled into one.
        # +excluded+:: classes excluded from the test.
        def create_suite_xml(filename, classnames, suitename="default", onetest=false, excluded = [])
          File.open(filename, 'w') do |suitexml|
            xml = Builder::XmlMarkup.new(:target=>suitexml, :indent=>4)
            xml.instruct!
            xml.declare! :DOCTYPE, :suite, :SYSTEM, "http://testng.org/testng-1.0.dtd" 
            
            xml.suite(:name => suitename ) do      
              if onetest                
                xml.test(:name=>"all") do
                  write_excludes_includes(xml, excluded )
                  xml.classes do
                    classnames.uniq.sort.each do | klass |
                      xml.tag!("class", :name => klass ) 
                    end
                  end
                end
              else
                classnames.uniq.sort.each do | klass |
                    xml.test(:name => klass[klass.rindex('.')+1, klass.length]) do
                      xml.classes do
                        xml.tag!("class", :name => klass ) 
                    end
                  end              
                end
              end
            end
          end
                         
        end # create_suite_xml 
            
        def write_excludes_includes(xml, excluded, included = []) # :nodoc:          
              xml.groups do
                xml.run do
                  excluded.each do |ex|
                    xml.exclude(:name => ex)
                  end
                  included.each do |inc|
                    xml.tag!("include", :name => inc)
                  end
                end
              end
          end          
      end
    end
end

