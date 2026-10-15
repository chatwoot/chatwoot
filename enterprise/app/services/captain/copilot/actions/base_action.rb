# An action changes one record at a time. A subclass declares:
#   NAME        the value the model passes to the act tool
#   RESOURCE    the resource it changes, as named in Captain::Copilot::Resources
#   DESCRIPTION what the action does, shown to the model
#   ARGUMENTS   a JSON schema for its arguments
#   REPEATABLE  false when running the change twice repeats its effect, e.g. sending a message. ActionJob then marks the
#               record applying before perform and never runs it again for that record after a crash.
# and implements perform(record), which returns :applied, or :skipped when the record already has the change. perform
# raises Captain::Copilot::ActionNotApplicableError when the change no longer applies to the record.
# ActionJob loads records through the resource's scope, so the user's access is checked again before each change.
class Captain::Copilot::Actions::BaseAction
  REPEATABLE = true

  def initialize(account:, user:, arguments:, proposal_states: {})
    @account = account
    @user = user
    @arguments = arguments.is_a?(Hash) ? arguments.deep_stringify_keys : arguments
    @proposal_states = proposal_states
    raise ArgumentError, "Invalid arguments for #{self.class::NAME}" unless JSONSchemer.schema(self.class::ARGUMENTS).valid?(@arguments)

    validate!
  end

  def perform(_record)
    raise NotImplementedError
  end

  # The state each target was in when the change was proposed, keyed by record ID, for an action that must not run on a
  # record that changed afterwards. The act tool saves it, and perform reads it from @proposal_states.
  def proposal_states(_ids)
    {}
  end

  # Names the approval card shows for IDs in the arguments, e.g. the agent behind an agent_id.
  def card_details; end

  private

  def validate!; end
end
