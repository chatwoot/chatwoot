# frozen_string_literal: true

module RuboCop
  module Cop
    # This autocorrects string literals
    class StringLiteralCorrector
      extend Util

      class << self
        def correct(corrector, node, style)
          return if node.dstr_type?

          str = node.str_content
          if style == :single_quotes
            corrector.replace(node, to_string_literal(str))
          else
            corrector.replace(node, str.inspect)
          end
        end
      end
    end
  end
end
