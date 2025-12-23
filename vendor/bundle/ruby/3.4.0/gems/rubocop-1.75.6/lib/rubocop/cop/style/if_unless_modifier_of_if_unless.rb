# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for if and unless statements used as modifiers of other if or
      # unless statements.
      #
      # @example
      #
      #  # bad
      #  tired? ? 'stop' : 'go faster' if running?
      #
      #  # bad
      #  if tired?
      #    "please stop"
      #  else
      #    "keep going"
      #  end if running?
      #
      #  # good
      #  if running?
      #    tired? ? 'stop' : 'go faster'
      #  end
      class IfUnlessModifierOfIfUnless < Base
        include StatementModifier
        extend AutoCorrector

        MSG = 'Avoid modifier `%<keyword>s` after another conditional.'

        def on_if(node)
          return unless node.modifier_form? && node.body.if_type?

          add_offense(node.loc.keyword, message: format(MSG, keyword: node.keyword)) do |corrector|
            keyword = node.if? ? 'if' : 'unless'

            corrector.replace(node, <<~RUBY.chop)
              #{keyword} #{node.condition.source}
              #{node.if_branch.source}
              end
            RUBY
          end
        end
      end
    end
  end
end
