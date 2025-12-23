# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of squiggly heredoc over `strip_heredoc`.
      #
      # @example
      #
      #   # bad
      #   <<EOS.strip_heredoc
      #     some text
      #   EOS
      #
      #   # bad
      #   <<-EOS.strip_heredoc
      #     some text
      #   EOS
      #
      #   # good
      #   <<~EOS
      #     some text
      #   EOS
      #
      class StripHeredoc < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use squiggly heredoc (`<<~`) instead of `strip_heredoc`.'
        RESTRICT_ON_SEND = %i[strip_heredoc].freeze

        minimum_target_ruby_version 2.3

        def on_send(node)
          return unless (receiver = node.receiver)
          return unless receiver.type?(:str, :dstr)
          return unless receiver.respond_to?(:heredoc?) && receiver.heredoc?

          register_offense(node, receiver)
        end

        private

        def register_offense(node, heredoc)
          add_offense(node) do |corrector|
            squiggly_heredoc = heredoc.source.sub(/\A<<(-|~)?/, '<<~')

            corrector.replace(heredoc, squiggly_heredoc)
            corrector.remove(node.loc.dot)
            corrector.remove(node.loc.selector)
          end
        end
      end
    end
  end
end
