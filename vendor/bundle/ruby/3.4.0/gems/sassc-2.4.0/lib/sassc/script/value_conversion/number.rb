# frozen_string_literal: true

module SassC
  module Script
    module ValueConversion
      class Number < Base
        def to_native
          Native::make_number(@value.value, @value.numerator_units.first)
        end
      end
    end
  end
end
