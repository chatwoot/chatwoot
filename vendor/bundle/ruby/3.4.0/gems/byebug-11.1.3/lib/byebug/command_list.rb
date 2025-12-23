# frozen_string_literal: true

require_relative "errors"

module Byebug
  #
  # Holds an array of subcommands for a command
  #
  class CommandList
    include Enumerable

    def initialize(commands)
      @commands = commands.sort_by(&:to_s)
    end

    def match(input)
      find { |cmd| cmd.match(input) }
    end

    def each
      @commands.each { |cmd| yield(cmd) }
    end

    def to_s
      "\n" + map { |cmd| cmd.columnize(width) }.join + "\n"
    end

    private

    def width
      @width ||= map(&:to_s).max_by(&:size).size
    end
  end
end
