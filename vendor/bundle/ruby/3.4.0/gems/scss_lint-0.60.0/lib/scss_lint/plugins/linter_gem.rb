module SCSSLint
  class Plugins
    # Load linter plugin gems
    class LinterGem
      attr_reader :config

      def initialize(name)
        @name = name
      end

      def load
        require @name
        @config = plugin_config
        self
      rescue LoadError
        raise SCSSLint::Exceptions::PluginGemLoadError,
              "Unable to load linter plugin gem '#{@name}'. Try running " \
              "`gem install #{@name}`, or adding it to your Gemfile and " \
              'running `bundle install`. See the `plugin_gems` section of ' \
              'your .scss-lint.yml file to add/remove gem plugins.'
      end

    private

      # Returns the {SCSSLint::Config} for this plugin.
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

      # Path of the configuration file to attempt to load for this plugin.
      #
      # @return [String]
      def plugin_config_file
        gem_specification = Gem::Specification.find_by_name(@name)

        File.join(gem_specification.gem_dir, Config::FILE_NAME)
      end
    end
  end
end
