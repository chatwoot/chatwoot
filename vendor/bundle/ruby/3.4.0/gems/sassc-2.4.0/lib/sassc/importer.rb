# frozen_string_literal: true

module SassC
  class Importer
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def imports(path, parent_path)
      # A custom importer must override this method.
      # Custom importer may return an Import, or an array of Imports.
      raise NotImplementedError
    end

    class Import
      attr_accessor :path, :source, :source_map_path

      def initialize(path, source: nil, source_map_path: nil)
        @path = path
        @source = source
        @source_map_path = source_map_path
      end

      def to_s
        "Import: #{path} #{source} #{source_map_path}"
      end
    end
  end
end
