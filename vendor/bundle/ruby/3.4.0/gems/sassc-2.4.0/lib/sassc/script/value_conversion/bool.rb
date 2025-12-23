# frozen_string_literal: true

module SassC
  module Script
    module ValueConversion
      class Bool < Base
        def to_native
          Native::make_boolean(@value.value)
        end
      end
    end
  end
end
