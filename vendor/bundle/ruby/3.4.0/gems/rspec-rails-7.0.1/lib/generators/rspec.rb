require 'rails/generators/named_base'
require 'rspec/core'
require 'rspec/rails/feature_check'

# @private
# Weirdly named generators namespace (should be `RSpec`) for compatibility with
# rails loading.
module Rspec
  # @private
  module Generators
    # @private
    class Base < ::Rails::Generators::NamedBase
      include RSpec::Rails::FeatureCheck

      def self.source_root(path = nil)
        if path
          @_rspec_source_root = path
        else
          @_rspec_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'rspec', generator_name, 'templates'))
        end
      end

      # @private
      # Load configuration from RSpec to ensure `--default-path` is set
      def self.configuration
        @configuration ||=
          begin
            configuration = RSpec.configuration
            options = RSpec::Core::ConfigurationOptions.new({})
            options.configure(configuration)
            configuration
          end
      end

      def target_path(*paths)
        File.join(self.class.configuration.default_path, *paths)
      end
    end
  end
end

# @private
module Rails
  module Generators
    # @private
    class GeneratedAttribute
      def input_type
        @input_type ||= if type == :text
                          "textarea"
                        else
                          "input"
                        end
      end
    end
  end
end
