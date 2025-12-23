# frozen_string_literal: true

module Byebug
  #
  # Interface class for command execution from script files.
  #
  class ScriptInterface < Interface
    def initialize(file, verbose = false)
      super()
      @verbose = verbose
      @input = File.open(file)
      @output = verbose ? $stdout : StringIO.new
      @error = $stderr
    end

    def read_command(prompt)
      readline(prompt, false)
    end

    def close
      input.close
    end

    def readline(*)
      while (result = input.gets)
        output.puts "+ #{result}" if @verbose
        next if /^\s*#/.match?(result)

        return result.chomp
      end
    end
  end
end
