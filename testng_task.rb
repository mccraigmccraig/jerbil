require 'rake'
require 'rake/tasklib'
require File.dirname(__FILE__) + '/java_helper'

module Rake
  module TestNG
    class TestNGTask < TaskLib
      attr_accessor :name
      attr_accessor :description
      attr_accessor :dependencies
      attr_accessor :testclasses
      
      def initialize(name)
        @name = name
        @dependencies = []
        @testclasses = []
        yield self if block_given?
        define
      end
      
      def define
        desc description unless description.nil?
        task name => dependencies do |t|
          tl = Rake::TestNG::TestListener.new
          listener = Rjb::bind(tl, 'org.testng.ITestListener')
          testng = Rjb::import('org.testng.TestNG').new_with_sig 'Z', false
          testng.addListener(listener)    
          testklasses = testclasses.map { |clazz| Rjb::import(clazz) }    
          testng.setTestClasses( testklasses )
          testng.setOutputDirectory( "test-output" )
          #testng.setParallel(true)
          testng.setVerbose( 2 )
          testng.run
      
          raise "some tests failed: #{tl.failed_to_s}" unless testng.getStatus == 0
        end
      end
    end
    
    class TestListener
      include JavaHelper

        attr_reader :failed_classes
        def initialize
          @failed_classes = Set.new
        end
        
        def onFinish(context)
          puts
          @outfile.close
        end
        
        def onStart(context)
          file = File.join(context.getOutputDirectory, "testng.output")
          $stderr.puts "test logging going to #{file}"
          @outfile = File.open( file , "w") 
        end
        
        def onTestFailedButWithinSuccessPercentage(result)
        end
        
        def onTestFailure(result)
          print "X"
          
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
          print "."
        end
        
        def log(s)
          @outfile.puts s.to_s
        end
        
        def failed_to_s
          @failed_classes.to_a.join(', ')   
        end
      end
    end
end

