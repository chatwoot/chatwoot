# frozen_string_literal: true

require_relative 'plugin/configuration_integrator'
require_relative 'plugin/loader'

module RuboCop
  # Provides a plugin for RuboCop extensions that conform to lint_roller.
  # https://github.com/standardrb/lint_roller
  # @api private
  module Plugin
    BUILTIN_INTERNAL_PLUGINS = {
      'rubocop-internal_affairs' => {
        'enabled' => true,
        'require_path' => 'rubocop/cop/internal_affairs/plugin',
        'plugin_class_name' => 'RuboCop::InternalAffairs::Plugin'
      }
    }.freeze
    INTERNAL_AFFAIRS_PLUGIN_NAME = Plugin::BUILTIN_INTERNAL_PLUGINS.keys.first
    OBSOLETE_INTERNAL_AFFAIRS_PLUGIN_NAME = 'rubocop/cop/internal_affairs'

    class << self
      def plugin_capable?(feature_name)
        return true if BUILTIN_INTERNAL_PLUGINS.key?(feature_name)
        return true if feature_name == OBSOLETE_INTERNAL_AFFAIRS_PLUGIN_NAME

        begin
          # When not using Bundler. Makes the spec available but does not require it.
          gem feature_name
        rescue Gem::LoadError
          # The user requested a gem that they do not have installed
        end
        return false unless (spec = Gem.loaded_specs[feature_name])

        !!spec.metadata['default_lint_roller_plugin']
      end

      def integrate_plugins(rubocop_config, plugins)
        plugins = Plugin::Loader.load(plugins)

        ConfigurationIntegrator.integrate_plugins_into_rubocop_config(rubocop_config, plugins)

        plugins
      end
    end
  end
end
