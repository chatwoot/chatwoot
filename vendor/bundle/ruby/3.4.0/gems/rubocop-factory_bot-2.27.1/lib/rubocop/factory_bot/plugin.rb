# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module FactoryBot
    # A plugin that integrates RuboCop FactoryBot with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      # :nocov:
      def about
        LintRoller::About.new(
          name: 'rubocop-factory_bot',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop-factory_bot',
          description: 'Code style checking for FactoryBot test files.'
        )
      end
      # :nocov:

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')

        obsoletion = project_root.join('config', 'obsoletion.yml')
        ConfigObsoletion.files << obsoletion if obsoletion.exist?

        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: project_root.join('config/default.yml')
        )
      end
    end
  end
end
