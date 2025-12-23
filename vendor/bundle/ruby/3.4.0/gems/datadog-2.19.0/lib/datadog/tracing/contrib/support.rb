# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Miscellaneous support methods to aid in the creation of integrations.
      module Support
        module_function

        # Checks if a constant is loaded in a module, handling autoloaded constants correctly.
        #
        # This method is particularly useful when you need to check if a constant is fully loaded,
        # not just defined. It handles the special case of autoloaded constants, which return
        # non-nil for `defined?` even when they haven't been loaded yet.
        #
        # @param base_module [Module] the module to check for the constant
        # @param constant [Symbol] the name of the constant to check
        # @return [Boolean] true if the constant has been loaded, false otherwise
        def fully_loaded?(base_module, constant)
          # Autoload constants return `constant` for `defined?`, but that doesn't mean they are loaded...
          base_module.const_defined?(constant) &&
            # ... to check that we need to call `autoload?`. If it returns `nil`, it's loaded.
            base_module.autoload?(constant).nil?
        end
      end
    end
  end
end
