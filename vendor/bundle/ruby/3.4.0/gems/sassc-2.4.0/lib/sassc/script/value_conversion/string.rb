# frozen_string_literal: true

module SassC
  module Script
    module ValueConversion
      class String < Base
        def to_native(opts = {})
          if opts[:quote] == :none || @value.type == :identifier
            Native::make_string(@value.to_s)
          else
            Native::make_qstring(@value.to_s)
          end
        end
      end
    end
  end
end
