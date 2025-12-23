# frozen_string_literal: true

require_relative "../command"

module Byebug
  #
  # Execute a file containing byebug commands.
  #
  # It can be used to restore a previously saved debugging session.
  #
  class SourceCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* so(?:urce)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        source <file>

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Restores a previously saved byebug session"
    end

    def execute
      return puts(help) unless @match[1]

      file = File.expand_path(@match[1]).strip
      return errmsg(pr("source.errors.not_found", file: file)) unless File.exist?(file)

      processor.interface.read_file(file)
    end
  end
end
