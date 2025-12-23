# frozen_string_literal: true

module WebConsole
  # The base class for every Web Console related error.
  Error = Class.new(StandardError)

  # Raised when there is an attempt to render a console more than once.
  DoubleRenderError = Class.new(Error)
end
