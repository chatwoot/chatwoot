# frozen_string_literal: true

require 'stringio'

module Puma
  class IOBuffer < StringIO
    def initialize
      super.binmode
    end

    def empty?
      length.zero?
    end

    def reset
      truncate 0
      rewind
    end

    def to_s
      rewind
      read
    end

    # Read & Reset - returns contents and resets
    # @return [String] StringIO contents
    def read_and_reset
      rewind
      str = read
      truncate 0
      rewind
      str
    end

    alias_method :clear, :reset

    # before Ruby 2.5, `write` would only take one argument
    if RUBY_VERSION >= '2.5' && RUBY_ENGINE != 'truffleruby'
      alias_method :append, :write
    else
      def append(*strs)
        strs.each { |str| write str }
      end
    end
  end
end
