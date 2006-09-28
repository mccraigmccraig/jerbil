require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  module TestNG
    class TestNGTask < TaskLib
      include JavaHelper
      
      attr_accessor :name
      attr_accessor :dependencies
      attr_accessor :testclasses
      attr_accessor :outputdir
      attr_accessor :report
      attr_accessor :suites
      attr_accessor :workingdir
      
      def initialize(name)
        @name = name
        @dependencies = []
        @testclasses = []
        @outputdir = "test-output"
        @report = true
        @suites = []
        @workingdir = nil
        yield self if block_given?
        dependencies << workingdir unless workingdir.nil?
        dependencies << outputdir
        define
      end
      
      def define
	  	desc "run testng tests" if Rake.application.last_comment.nil?
        task name => dependencies do |t|
          testng = Rjb::import('org.testng.TestNG').new_with_sig 'Z', false
         
          tl = Rake::TestNG::TestListener.new
          sl = Rake::TestNG::SuiteListener.new
          
          testng.addListener(Rjb::bind(tl, 'org.testng.ITestListener'))
          testng.addListener(Rjb::bind(sl, 'org.testng.ISuiteListener'))
          
          if report
            testng.addListener(Rjb::import('org.testng.reporters.SuiteHTMLReporter').new)
            testng.addListener(Rjb::import('org.testng.reporters.TestHTMLReporter').new)
          end
         
          if suites.empty?
            testng.setTestClasses( testclasses.to_classes )
          else
            testng.setTestSuites( str_list(suites) )
          end
          
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
        end
        
        def onFinish(context)
          @outfile.close
        end
        
        def onStart(context)
          file = File.join(context.getOutputDirectory, "#{context.getName}.output")
          @outfile = File.open( file , "w") 
        end
        
        def onTestFailedButWithinSuccessPercentage(result)
        end
        
        def onTestFailure(result)
          $stderr.print "X"
          
          @failed_classes.add result.getTestClass.getName
          begin
            log result.getTestClass.getName + ":" + result.getMethod.getMethodName
            log result.getThrowable.getMessage
            trace = printStream_to_s {|ps| result.getThrowable.printStackTrace(ps) }
            log trace
            log "------------------------------------------------------------------------"
          rescue 
            $stderr.puts $!
          end
        end
        
        def onTestSkipped(result)
        end
        
        def onTestStart(result)
        end
        
        def onTestSuccess(result)
          $stderr.print "."
        end
        
        def log(s)
          @outfile.puts s.to_s
        end
        
        def failed_to_s
          @failed_classes.to_a.join(', ')   
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
        def create_suite_xml(filename, classnames, suitename="default", onetest=false)
          File.open(filename, 'w') do |suitexml|
            xml = Builder::XmlMarkup.new(:target=>suitexml, :indent=>4)
            xml.instruct!
            xml.declare! :DOCTYPE, :suite, :SYSTEM, "http://testng.org/testng-1.0.dtd" 
            
            xml.suite(:name => suitename ) do      
            
              if onetest
                xml.test(:name=>"all") do
                  xml.classes do
                    classnames.sort.each do | klass |
                      xml.tag!("class", :name => klass ) 
                    end
                  end
                end
              else
                classnames.sort.each do | klass |
                    xml.test(:name => klass[klass.rindex('.')+1, klass.length]) do
                      xml.classes do
                        xml.tag!("class", :name => klass ) 
                    end
                  end              
                end
              end
            end
          end
        end
      end
    end
end

