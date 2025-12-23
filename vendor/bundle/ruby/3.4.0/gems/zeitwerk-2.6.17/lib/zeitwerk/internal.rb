# frozen_string_literal: true

# This is a private module.
module Zeitwerk::Internal
  def internal(method_name)
    private method_name

    mangled = "__#{method_name}"
    alias_method mangled, method_name
    public mangled
  end
end
