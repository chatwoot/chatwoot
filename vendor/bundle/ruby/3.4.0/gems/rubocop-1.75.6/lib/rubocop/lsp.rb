# frozen_string_literal: true

module RuboCop
  # The RuboCop's built-in LSP module.
  module LSP
    module_function

    # Returns true when LSP is enabled, false when disabled.
    #
    # @return [Boolean]
    def enabled?
      @enabled ||= false
    end

    # Enable LSP.
    #
    # @return [void]
    def enable
      @enabled = true
    end

    # Disable LSP.
    #
    # @return [void]
    def disable(&block)
      if block
        original = @enabled
        @enabled = false
        yield
        @enabled = original
      else
        @enabled = false
      end
    end
  end
end
