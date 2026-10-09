# An action changes one record at a time. A subclass declares:
#   NAME        the value the model passes to the act tool
#   RESOURCE    the resource it changes, as named in Captain::Copilot::Resources
#   DESCRIPTION what the action does, shown to the model
#   ARGUMENTS   a JSON schema for its arguments
# and implements perform(record), which returns 'applied', or 'skipped' when the record already has the change.
# ActionJob loads records through the resource's scope, so the user's access is checked again before each change.
class Captain::Copilot::Actions::BaseAction
  def initialize(account:, user:, arguments:)
    @account = account
    @user = user
    @arguments = arguments.is_a?(Hash) ? arguments.deep_stringify_keys : arguments
    raise ArgumentError, "Invalid arguments for #{self.class::NAME}" unless JSONSchemer.schema(self.class::ARGUMENTS).valid?(@arguments)

    validate!
  end

  def perform(_record)
    raise NotImplementedError
  end

  private

  def validate!; end
end
