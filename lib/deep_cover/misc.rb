module DeepCover
  module Misc
    def self.require_relative_dir(dir_name)
      dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
      Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
        require file
      end
    end

    # Call with nil to remove $VERBOSE while in the block
    # copied from: https://apidock.com/rails/v4.2.7/Kernel/with_warnings
    def self.with_warnings(flag)
      old_verbose, $VERBOSE = $VERBOSE, flag
      yield
    ensure
      $VERBOSE = old_verbose
    end


    # Want to execute with coverage results. Ideally using the correct filename.

    # Want to only get the blank coverage data without needing to execute anything

    def self.shift_source(source, lineno)
      "\n" * (lineno - 1) + source
    end

    def self.unshift_coverage(coverage, lineno)
      coverage[(lineno-1)..-1]
    end

    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
      # Returns a blank coverage data without executing the source at all
      # Useful to know which line is considered not-executable by builtin
      def self.blank_builtin_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        source_stream = java.io.ByteArrayInputStream.new(source.to_java_bytes)
        ::Coverage.start
        Object.to_java.getRuntime.parseFile(fn, source_stream, nil)
        result = ::Coverage.result.fetch(fn)
        unshift_coverage result, lineno
      end

      # Executes the source as if it was in the specified file while
      # builtin coverage information is still captured
      def self.run_with_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        Object.to_java.getRuntime.executeScript(source, fn)
      end
    else
      # In ruby 2.0 and 2.1, using 2, 3 or 4 as lineno with RubyVM::InstructionSequence.compile
      # will cause the coverage result to be truncated.
      # 1: [1,2,nil,1]
      # 2: [nil,1,2,nil]
      # 3: [nil,nil,1,2]
      # 4: [nil,nil,nil,1]
      # 5: [nil,nil,nil,nil,1,2,nil,1]
      # Using 1 and 5 or more do not seem to show this issue.
      # The workaround is to create the fake lines manually and always use the default lineno

      # Returns a blank coverage data without executing the source at all
      # Useful to know which line is considered not-executable by builtin
      def self.blank_builtin_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        ::Coverage.start
        RubyVM::InstructionSequence.compile(source, fn)
        result = ::Coverage.result.fetch(fn)
        unshift_coverage result, lineno
      end

      # Executes the source as if it was in the specified file while
      # builtin coverage information is still captured
      def self.run_with_line_coverage(source, fn=nil, lineno=1)
        source = shift_source(source, lineno)
        RubyVM::InstructionSequence.compile(source, fn).eval
      end
    end
  end
end
