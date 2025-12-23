# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module InternalAffairs
    # A Plugin for `InternalAffairs` department, which has internal cops.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-internal_affairs',
          version: Version::STRING,
          homepage: 'https://github.com/rubocop/rubocop/tree/master/lib/rubocop/cop/internal_affairs',
          description: 'A collection of RuboCop cops to check for internal affairs.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        require_relative '../internal_affairs'

        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../../config/internal_affairs.yml')
        )
      end
    end
  end
end
