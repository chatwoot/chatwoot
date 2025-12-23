# frozen_string_literal: true

module RuboCop
  module Plugin
    # An exception raised when a plugin is not supported by the RuboCop engine.
    # @api private
    class NotSupportedError < Error
      def initialize(unsupported_plugins)
        super

        @unsupported_plugins = unsupported_plugins
      end

      def message
        if @unsupported_plugins.one?
          about = @unsupported_plugins.first.about

          "#{about.name} #{about.version} is not a plugin supported by RuboCop engine."
        else
          unsupported_plugin_names = @unsupported_plugins.map do |plugin|
            "#{plugin.about.name} #{plugin.about.version}"
          end.join(', ')

          "#{unsupported_plugin_names} are not plugins supported by RuboCop engine."
        end
      end
    end
  end
end
