# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # A Key specialization used for keys that must be present
      #
      # @api private
      class Required < Key
        # @api private
        def operation
          :and
        end
      end
    end
  end
end
