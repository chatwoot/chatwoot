# frozen_string_literal: true

module RuboCop
  module Plugin
    # An exception raised when a plugin fails to load.
    # @api private
    class LoadError < Error
      def initialize(plugin_name)
        super

        @plugin_name = plugin_name
      end

      def message
        <<~MESSAGE
          Failed to load plugin `#{@plugin_name}` because the corresponding plugin class could not be determined for instantiation.
          Try upgrading it first (e.g., `bundle update #{@plugin_name}`).
          If `#{@plugin_name}` is not yet a plugin, use `require: #{@plugin_name}` instead of `plugins: #{@plugin_name}` in your configuration.

          For further assistance, check with the developer regarding the following points:
          https://docs.rubocop.org/rubocop/plugin_migration_guide.html
        MESSAGE
      end
    end
  end
end
