# frozen_string_literal: true

module Dry
  module Initializer
    module Mixin
      # @private
      module Root
        private

        def initialize(*args, **kwargs)
          __dry_initializer_initialize__(*args, **kwargs)
        end
      end
    end
  end
end
