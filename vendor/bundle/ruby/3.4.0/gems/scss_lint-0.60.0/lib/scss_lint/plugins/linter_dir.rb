module SCSSLint
  class Plugins
    # Load ruby files from linter plugin directories.
    class LinterDir
      attr_reader :config

      def initialize(dir)
        @dir = dir
      end

      def load
        ruby_files.each { |file| require file }
        @config = plugin_config
        self
      end

    private

      def ruby_files
        Dir.glob(File.expand_path(File.join(@dir, '**', '*.rb')))
      end

      # Returns the {SCSSLint::Config} for this directory.
      #
      # This is intended to be merged with the configuration that loaded this
      # plugin.
      #
      # @return [SCSSLint::Config]
      def plugin_config
        file = plugin_config_file

        if File.exist?(file)
          Config.load(file, merge_with_default: false)
        else
          Config.new({})
        end
      end

      # Path of the configuration file to attempt to load for this directory.
      #
      # @return [String]
      def plugin_config_file
        File.join(@dir, Config::FILE_NAME)
      end
    end
  end
end
