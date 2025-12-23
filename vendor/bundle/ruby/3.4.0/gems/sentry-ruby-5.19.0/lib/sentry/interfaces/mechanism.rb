# frozen_string_literal: true

module Sentry
  class Mechanism < Interface
    # Generic identifier, mostly the source integration for this exception.
    # @return [String]
    attr_accessor :type

    # A manually captured exception has handled set to true,
    # false if coming from an integration where we intercept an uncaught exception.
    # Defaults to true here and will be set to false explicitly in integrations.
    # @return [Boolean]
    attr_accessor :handled

    def initialize(type: 'generic', handled: true)
      @type = type
      @handled = handled
    end
  end
end
