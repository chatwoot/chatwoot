module Sprockets
  module Exporters
    # Convenience class for all exporters to inherit from
    #
    # An exporter is responsible for exporting a Sprockets::Asset
    # to a file system. For example the Exporters::File class
    # writes the asset to it's destination. The Exporters::Zlib class
    # writes a gzip copy of the asset to disk.
    class Base
      attr_reader :asset, :environment, :directory, :target

      # Public: Creates new instance
      #
      # Initialize will be called with
      # keyword arguments:
      #
      # - asset: An instance of Sprockets::Asset.
      # - environment: An instance of Sprockets::Environment.
      # - directory: String representing the target directory to write to.
      #
      # These will all be stored as accessible values. In addition a
      # +target+ will be available which is the target directory and
      # the asset's digest path combined.
      def initialize(asset: nil, environment: nil, directory: nil)
        @asset       = asset
        @environment = environment
        @directory   = directory
        @target      = ::File.join(directory, asset.digest_path)
        setup
      end

      # Public: Callback that is executed after initialization
      #
      # Any setup that needs to be done can be performed in the +setup+
      # method. It will be called immediately after initialization.
      def setup
      end

      # Public: Handles logic for skipping exporter and notifying logger
      #
      # The `skip?` will be called before anything will be written.
      # If `skip?` returns truthy it will not continue. This method
      # takes a `logger` that responds to +debug+ and +info+.  The `skip?`
      # method is the only place expected to write to a logger, any other
      # messages may produce jumbled logs.
      def skip?(logger)
        false
      end

      # Public: Contains logic for writing "exporting" asset to disk
      #
      # If the exporter is not skipped it then Sprockets will execute it's
      # `call` method. This method takes no arguments and should only use
      # elements passed in via initialize or stored in `setup`.
      def call
        raise "Must subclass and implement call"
      end

      # Public: Yields a file that can be written to with the input
      #
      # `filename`. Defaults to the `target`. Method
      # is safe to use in forked or threaded environments.
      def write(filename = target)
        FileUtils.mkdir_p File.dirname(filename)
        PathUtils.atomic_write(filename) do |f|
          yield f
        end
      end
    end
  end
end
