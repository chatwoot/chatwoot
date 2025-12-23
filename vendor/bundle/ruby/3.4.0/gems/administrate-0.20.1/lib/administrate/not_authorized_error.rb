module Administrate
  class NotAuthorizedError < StandardError
    def initialize(action:, resource:)
      @action = action
      @resource = resource

      case resource
      when String, Symbol
        super("Not allowed to perform #{action.inspect} on #{resource.inspect}")
      when Module
        super("Not allowed to perform #{action.inspect} on #{resource.name}")
      else
        super(
          "Not allowed to perform #{action.inspect} on the given " +
            resource.class.name
        )
      end
    end
  end
end
