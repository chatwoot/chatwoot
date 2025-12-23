require_relative 'plugins/linter_gem'
require_relative 'plugins/linter_dir'

module SCSSLint
  # Loads external linter plugins.
  class Plugins
    def initialize(config)
      @config = config
    end

    def load
      all.map(&:load)
    end

  private

    def all
      [plugin_gems, plugin_directories].flatten
    end

    def plugin_gems
      Array(@config['plugin_gems']).map do |gem_name|
        LinterGem.new(gem_name)
      end
    end

    def plugin_directories
      Array(@config['plugin_directories']).map do |directory|
        LinterDir.new(File.join(File.dirname(@config.file), directory))
      end
    end
  end
end
