# frozen_string_literal: true

require 'lint_roller/context'
require_relative 'not_supported_error'

module RuboCop
  module Plugin
    # A class for integrating plugin configurations into RuboCop.
    # Handles configuration merging, validation, and compatibility for plugins.
    # @api private
    class ConfigurationIntegrator
      class << self
        def integrate_plugins_into_rubocop_config(rubocop_config, plugins)
          default_config = ConfigLoader.default_configuration
          runner_context = create_context(rubocop_config)

          validate_plugins!(plugins, runner_context)

          plugin_config = combine_rubocop_configs(default_config, runner_context, plugins).to_h

          merge_plugin_config_into_all_cops!(default_config, plugin_config)
          merge_plugin_config_into_default_config!(default_config, plugin_config)
        end

        private

        def create_context(rubocop_config)
          LintRoller::Context.new(
            runner: :rubocop,
            runner_version: Version.version,
            engine: :rubocop,
            engine_version: Version.version,
            target_ruby_version: rubocop_config.target_ruby_version
          )
        end

        def validate_plugins!(plugins, runner_context)
          unsupported_plugins = plugins.reject { |plugin| plugin.supported?(runner_context) }
          return if unsupported_plugins.none?

          raise Plugin::NotSupportedError, unsupported_plugins
        end

        def combine_rubocop_configs(default_config, runner_context, plugins)
          fake_out_rubocop_default_configuration(default_config) do |fake_config|
            all_cop_keys_configured_by_plugins = []

            plugins.reduce(fake_config) do |combined_config, plugin|
              RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, combined_config)

              print 'Plugin ' if ConfigLoader.debug

              plugin_config, plugin_config_path = load_plugin_rubocop_config(plugin, runner_context)

              plugin_config['AllCops'], all_cop_keys_configured_by_plugins = merge_all_cop_settings(
                combined_config['AllCops'], plugin_config['AllCops'],
                all_cop_keys_configured_by_plugins
              )

              plugin_config.make_excludes_absolute

              ConfigLoader.merge_with_default(plugin_config, plugin_config_path)
            end
          end
        end

        def merge_plugin_config_into_all_cops!(rubocop_config, plugin_config)
          rubocop_config['AllCops'].merge!(plugin_config['AllCops'])
        end

        def merge_plugin_config_into_default_config!(default_config, plugin_config)
          plugin_config.each do |key, value|
            default_config[key] = if default_config[key].is_a?(Hash)
                                    resolver.merge(default_config[key], value)
                                  else
                                    value
                                  end
          end
        end

        def fake_out_rubocop_default_configuration(default_config)
          orig_default_config = ConfigLoader.instance_variable_get(:@default_configuration)

          result = yield default_config

          ConfigLoader.instance_variable_set(:@default_configuration, orig_default_config)

          result
        end

        # rubocop:disable Metrics/AbcSize
        def load_plugin_rubocop_config(plugin, runner_context)
          rules = plugin.rules(runner_context)

          case rules.type
          when :path
            [ConfigLoader.load_file(rules.value, check: false), rules.value]
          when :object
            path = plugin.method(:rules).source_location[0]
            [Config.create(rules.value, path, check: true), path]
          when :error
            plugin_name = plugin.about&.name || plugin.inspect
            error_message = rules.value.respond_to?(:message) ? rules.value.message : rules.value

            raise "Plugin `#{plugin_name}' failed to load with error: #{error_message}"
          end
        end
        # rubocop:enable Metrics/AbcSize

        # This is how we ensure "first-in wins": plugins can override AllCops settings that are
        # set by RuboCop's default configuration, but once a plugin sets an AllCop setting, they
        # have exclusive first-in-wins rights to that setting.
        #
        # The one exception to this are array fields, because we don't want to
        # overwrite the AllCops defaults but rather munge the arrays (`existing |
        # new`) to allow plugins to add to the array, for example Include and
        # Exclude paths and patterns.
        def merge_all_cop_settings(existing_all_cops, new_all_cops, already_configured_keys)
          return [existing_all_cops, already_configured_keys] unless new_all_cops.is_a?(Hash)

          combined_all_cops = existing_all_cops.dup
          combined_configured_keys = already_configured_keys.dup

          new_all_cops.each do |key, value|
            if combined_all_cops[key].is_a?(Array) && value.is_a?(Array)
              combined_all_cops[key] |= value
              combined_configured_keys |= [key]
            elsif !combined_configured_keys.include?(key)
              combined_all_cops[key] = value
              combined_configured_keys << key
            end
          end

          [combined_all_cops, combined_configured_keys]
        end

        def resolver
          @resolver ||= ConfigLoaderResolver.new
        end
      end
    end
  end
end
