# frozen_string_literal: true

module SassC
  class Dependency
    attr_reader :filename
    attr_reader :options

    def initialize(filename)
      @filename = filename
      @options = { filename: @filename }
    end

    def self.from_filenames(filenames)
      filenames.map { |f| new(f) }
    end
  end
end
