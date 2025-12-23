# frozen_string_literal: true

require_relative "../history"

module Byebug
  #
  # Interface class for remote use of byebug.
  #
  class RemoteInterface < Interface
    def initialize(socket)
      super()
      @input = socket
      @output = socket
      @error = socket
    end

    def read_command(prompt)
      super("PROMPT #{prompt}")
    rescue Errno::EPIPE, Errno::ECONNABORTED
      "continue"
    end

    def confirm(prompt)
      super("CONFIRM #{prompt}")
    rescue Errno::EPIPE, Errno::ECONNABORTED
      false
    end

    def print(message)
      super(message)
    rescue Errno::EPIPE, Errno::ECONNABORTED
      nil
    end

    def puts(message)
      super(message)
    rescue Errno::EPIPE, Errno::ECONNABORTED
      nil
    end

    def close
      output.close
    end

    def readline(prompt)
      puts(prompt)
      (input.gets || "continue").chomp
    end
  end
end
