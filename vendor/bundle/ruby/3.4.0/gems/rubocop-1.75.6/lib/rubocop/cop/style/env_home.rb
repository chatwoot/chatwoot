# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for consistent usage of `ENV['HOME']`. If `nil` is used as
      # the second argument of `ENV.fetch`, it is treated as a bad case like `ENV[]`.
      #
      # @safety
      #   The cop is unsafe because the result when `nil` is assigned to `ENV['HOME']` changes:
      #
      #   [source,ruby]
      #   ----
      #   ENV['HOME'] = nil
      #   ENV['HOME'] # => nil
      #   Dir.home    # => '/home/foo'
      #   ----
      #
      # @example
      #
      #   # bad
      #   ENV['HOME']
      #   ENV.fetch('HOME', nil)
      #
      #   # good
      #   Dir.home
      #
      #   # good
      #   ENV.fetch('HOME', default)
      #
      class EnvHome < Base
        extend AutoCorrector

        MSG = 'Use `Dir.home` instead.'
        RESTRICT_ON_SEND = %i[[] fetch].freeze

        # @!method env_home?(node)
        def_node_matcher :env_home?, <<~PATTERN
          (send
            (const {cbase nil?} :ENV) {:[] :fetch}
            (str "HOME")
            ...)
        PATTERN

        def on_send(node)
          return unless env_home?(node)
          return if node.arguments.count == 2 && !node.arguments[1].nil_type?

          add_offense(node) do |corrector|
            corrector.replace(node, 'Dir.home')
          end
        end
      end
    end
  end
end
