# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Rails
    # A plugin that integrates RuboCop Rails with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-rails',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop-rails',
          description: 'A RuboCop extension focused on enforcing Rails best practices and coding conventions.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')

        ConfigObsoletion.files << project_root.join('config', 'obsoletion.yml')

        # FIXME: This is a dirty hack relying on a private constant to prevent
        # "Warning: AllCops does not support TargetRailsVersion parameter".
        # It should be updated to a better design in the future.
        without_warnings do
          ConfigValidator.const_set(:COMMON_PARAMS, ConfigValidator::COMMON_PARAMS.dup << 'TargetRailsVersion')
        end

        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: project_root.join('config', 'default.yml'))
      end

      private

      def without_warnings
        original_verbose = $VERBOSE
        $VERBOSE = nil
        yield
      ensure
        $VERBOSE = original_verbose
      end
    end
  end
end
