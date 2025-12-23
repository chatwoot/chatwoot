require 'hana'
require 'json_refs/loader'

module JsonRefs
  module DereferenceHandler
    class File
      def initialize(options = {})
        @path = options.fetch(:path)
      end

      def call
        JsonRefs::Loader.handle(@path)
      end
    end

    class Local
      def initialize(options = {})
        @path = options.fetch(:path)
        @doc = options.fetch(:doc)
      end

      def call
        Hana::Pointer.new(@path[1..-1]).eval(@doc)
      end
    end
  end
end