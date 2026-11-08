# An action changes one record at a time. A subclass declares:
#   NAME        the value the model passes to the act tool
#   RESOURCE    the resource it changes, as named in Captain::Copilot::Resources
#   DESCRIPTION what the action does, shown to the model
#   ARGUMENTS   a JSON schema for its arguments
# and implements perform(record), which returns :applied, or :skipped when the record already has the change. perform
# raises Captain::Copilot::ActionNotApplicableError when the change no longer fits the record.
# ActionJob loads records through the resource's scope, so the user's access is checked again before each change.
class Captain::Copilot::Actions::BaseAction
  def initialize(account:, user:, arguments:, proposal_values: {})
    @account = account
    @user = user
    @arguments = arguments.is_a?(Hash) ? arguments.deep_stringify_keys : arguments
    @proposal_values = proposal_values
    raise ArgumentError, "Invalid arguments for #{self.class::NAME}" unless JSONSchemer.schema(self.class::ARGUMENTS).valid?(@arguments)

    validate!
  end

  def perform(_record)
    raise NotImplementedError
  end

  # Values the act tool saves for each target when it proposes the change, keyed by record ID. ActionJob passes them back
  # as @proposal_values, so each record gets what the agent approved even if it changed in between.
  def proposal_values(_ids)
    {}
  end

  # What the approval card shows. summary names the card's string under CAPTAIN.COPILOT.APPROVAL.ACTIONS and values fill it
  # in. content is text the card shows in full, and warning names a string under CAPTAIN.COPILOT.APPROVAL.WARNINGS.
  def card(_ids)
    { summary: self.class::NAME.upcase }
  end

  private

  def validate!; end
end
