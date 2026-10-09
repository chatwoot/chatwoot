# An action changes one record at a time. A subclass declares:
#   NAME        the value the model passes to the act tool
#   DESCRIPTION what the action does, shown to the model
#   ARGUMENTS   a JSON schema for its arguments
# and implements perform(record), which returns 'applied', or 'skipped' when the record already has the change.
# Records are conversations the user can access; ActionJob checks access again before each change.
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
