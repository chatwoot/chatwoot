# frozen_string_literal: true

module Launchy
  # Internal: Ecapsulate the commandline argumens passed to Launchy
  #
  class Argv
    attr_reader :argv

    def initialize(*args)
      @argv = args.flatten
    end

    def to_s
      @argv.join(" ")
    end

    def to_str
      to_s
    end

    def [](idx)
      @argv[idx]
    end

    def valid?
      !blank? && executable?
    end

    def blank?
      @argv.empty? || @argv.first.strip.empty?
    end

    def executable?
      ::Launchy::Application.find_executable(@argv.first)
    end

    def ==(other)
      @argv == other.argv
    end
  end
end
