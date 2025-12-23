# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Performance
    # A plugin that integrates RuboCop Performance with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-performance',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop-performance',
          description: 'A collection of RuboCop cops to check for performance optimizations in Ruby code.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')

        ConfigObsoletion.files << project_root.join('config', 'obsoletion.yml')

        LintRoller::Rules.new(type: :path, config_format: :rubocop, value: project_root.join('config', 'default.yml'))
      end
    end
  end
end
