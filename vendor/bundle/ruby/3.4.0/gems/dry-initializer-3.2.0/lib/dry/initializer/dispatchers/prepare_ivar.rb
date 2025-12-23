# frozen_string_literal: true

# Prepares the variable name of a parameter or an option.
#
module Dry
  module Initializer
    module Dispatchers
      module PrepareIvar
        module_function

        def call(target:, **options)
          ivar = "@#{target}".delete("?").to_sym

          {target:, ivar:, **options}
        end
      end
    end
  end
end
