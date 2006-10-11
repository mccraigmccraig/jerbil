require 'rake'
require 'rake/tasklib'
require 'set'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  module TestNG
    class TestNGTask < Rake::TaskLib
      include JavaHelper
      
      attr_accessor :name
      attr_accessor :tests
      attr_accessor :outputdir
      attr_accessor :report
      attr_accessor :suites
      attr_accessor :workingdir
      attr_accessor :excludedgroups
      
      def initialize(name)
        @name = name
        @tests = []
        @outputdir = "test-output"
        @report = true
        @suites = []
        @workingdir = nil
        @excludedgroups = nil
        yield self if block_given?
        depends_on workingdir unless workingdir.nil?
        depends_on outputdir
        define
      end
      
      def define
	  	desc "run testng tests" if Rake.application.last_comment.nil?
        task name => dependencies do |t|
          testng = Rjb::import('org.testng.TestNG').new_with_sig 'Z', false
         
          tl = Rake::TestNG::TestListener.new
          sl = Rake::TestNG::SuiteListener.new
          
          #need to use _invoke because addListener has 3 different method signatures
          #using same name and return type
          #testng.addListener(Rjb::bind(tl, 'org.testng.ITestListener'))
          testng._invoke('addListener', 'Lorg.testng.ITestListener;', Rjb::bind(tl, 'org.testng.ITestListener'))
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
      
          raise "some tests failed: #{tl.failed_to_s}" unless testng.getStatus == 0
        end
        directory workingdir unless workingdir.nil?
        directory outputdir
      end
    end
    
    class TestListener
      include JavaHelper

        attr_reader :failed_classes
        def initialize
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
          $stderr.print "X"
          
          @failed_classes.add result.getTestClass.getName
          begin
            log get_test_name(result)
            log result.getThrowable.getMessage
            trace = printStream_to_s {|ps| result.getThrowable.printStackTrace(ps) }
            log trace
            log "------------------------------------------------------------------------"
          rescue 
            $stderr.puts $!
          end        
        end
        
        def onTestSkipped(result)
          log "skipped test " + get_test_name(result)
        end
        
        def onTestStart(result)		
          log "starting test " + get_test_name(result)
          @outfile.flush
        end
        
        def onTestSuccess(result)
          $stderr.print "."      
        end
     
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
          (@outfile || $stderr).puts s.to_s
        end 
      end
      
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
      
        
        def write_excludes_includes(xml, excluded, included = [])           
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

