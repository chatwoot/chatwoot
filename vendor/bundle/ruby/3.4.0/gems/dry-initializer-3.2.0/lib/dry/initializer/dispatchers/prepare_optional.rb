# frozen_string_literal: true

# Defines whether an argument is optional
#
module Dry
  module Initializer
    module Dispatchers
      module PrepareOptional
        module_function

        def call(optional: nil, default: nil, required: nil, **options)
          optional ||= default
          optional &&= !required

          {optional: !!optional, default:, **options}
        end
      end
    end
  end
end
