# frozen_string_literal: true

module Dry
  module Schema
    module Extensions
      module Hints
        # Tweaks AND visitor to enable :hints
        #
        # @api private
        module CompilerMethods
          # @api private
          def visit_and(node)
            super.with(hints: true)
          end
        end
      end
    end
  end
end
