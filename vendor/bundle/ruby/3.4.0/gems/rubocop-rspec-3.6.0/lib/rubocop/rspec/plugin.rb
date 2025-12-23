# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module RSpec
    # A plugin that integrates RuboCop RSpec with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      # :nocov:
      def about
        LintRoller::About.new(
          name: 'rubocop-rspec',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop-rspec',
          description: 'Code style checking for RSpec files.'
        )
      end
      # :nocov:

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')

        ConfigObsoletion.files << project_root.join('config', 'obsoletion.yml')

        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: project_root.join('config/default.yml')
        )
      end
    end
  end
end
