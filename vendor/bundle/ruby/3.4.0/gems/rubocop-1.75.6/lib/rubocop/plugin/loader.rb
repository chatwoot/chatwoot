# frozen_string_literal: true

require_relative '../feature_loader'
require_relative 'load_error'

module RuboCop
  module Plugin
    # A class for loading and resolving plugins.
    # @api private
    class Loader
      # rubocop:disable Layout/LineLength
      DEFAULT_PLUGIN_CONFIG = {
        'enabled' => true,
        'require_path' => nil, # If not set, will be set to the plugin name
        'plugin_class_name' => nil # If not set, looks for gemspec `spec.metadata["default_lint_roller_plugin"]`
      }.freeze

      # rubocop:enable Layout/LineLength
      class << self
        def load(plugins)
          normalized_plugin_configs = normalize(plugins)
          normalized_plugin_configs.filter_map do |plugin_name, plugin_config|
            next unless plugin_config['enabled']

            plugin_class = constantize_plugin_from(plugin_name, plugin_config)

            plugin_class.new(plugin_config)
          end
        end

        private

        # rubocop:disable Metrics/MethodLength
        def normalize(plugin_configs)
          plugin_configs.to_h do |plugin_config|
            if plugin_config == Plugin::OBSOLETE_INTERNAL_AFFAIRS_PLUGIN_NAME
              warn Rainbow(<<~MESSAGE).yellow
                Specify `rubocop-internal_affairs` instead of `rubocop/cop/internal_affairs` in your configuration.
              MESSAGE
              plugin_config = Plugin::INTERNAL_AFFAIRS_PLUGIN_NAME
            end

            if plugin_config.is_a?(Hash)
              plugin_name = plugin_config.keys.first

              [
                plugin_name, DEFAULT_PLUGIN_CONFIG.merge(
                  { 'require_path' => plugin_name }, plugin_config.values.first
                )
              ]
            # NOTE: Compatibility is maintained when `require: rubocop/cop/internal_affairs` remains
            # specified in `.rubocop.yml`.
            elsif (builtin_plugin_config = Plugin::BUILTIN_INTERNAL_PLUGINS[plugin_config])
              [plugin_config, builtin_plugin_config]
            else
              [plugin_config, DEFAULT_PLUGIN_CONFIG.merge('require_path' => plugin_config)]
            end
          end
        end

        def constantize_plugin_from(plugin_name, plugin_config)
          if plugin_name.is_a?(String) || plugin_name.is_a?(Symbol)
            constantize(plugin_name, plugin_config)
          else
            plugin_name
          end
        end

        # rubocop:enable Metrics/MethodLength
        def constantize(plugin_name, plugin_config)
          require_plugin(plugin_config['require_path'])

          if (constant_name = plugin_config['plugin_class_name'])
            begin
              Kernel.const_get(constant_name)
            rescue StandardError
              raise <<~MESSAGE
                Failed while configuring plugin `#{plugin_name}': no constant with name `#{constant_name}' was found.
              MESSAGE
            end
          else
            constantize_plugin_from_gemspec_metadata(plugin_name)
          end
        end

        def require_plugin(require_path)
          FeatureLoader.load(config_directory_path: Dir.pwd, feature: require_path)
        end

        def constantize_plugin_from_gemspec_metadata(plugin_name)
          plugin_class_name = Gem.loaded_specs[plugin_name].metadata['default_lint_roller_plugin']

          Kernel.const_get(plugin_class_name)
        rescue LoadError, StandardError
          raise Plugin::LoadError, plugin_name
        end
      end
    end
  end
end
