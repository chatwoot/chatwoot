# frozen_string_literal: true

module Sentry
  # @api private
  class LineCache
    def initialize
      @cache = {}
    end

    # Any linecache you provide to Sentry must implement this method.
    # Returns an Array of Strings representing the lines in the source
    # file. The number of lines retrieved is (2 * context) + 1, the middle
    # line should be the line requested by lineno. See specs for more information.
    def get_file_context(filename, lineno, context)
      return nil, nil, nil unless valid_path?(filename)

      lines = Array.new(2 * context + 1) do |i|
        getline(filename, lineno - context + i)
      end
      [lines[0..(context - 1)], lines[context], lines[(context + 1)..-1]]
    end

    private

    def valid_path?(path)
      lines = getlines(path)
      !lines.nil?
    end

    def getlines(path)
      @cache[path] ||= begin
        IO.readlines(path)
                       rescue
                         nil
      end
    end

    def getline(path, n)
      return nil if n < 1

      lines = getlines(path)
      return nil if lines.nil?

      lines[n - 1]
    end
  end
end
