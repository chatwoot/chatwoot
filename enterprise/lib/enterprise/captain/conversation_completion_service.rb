# Overrides the quota check from Enterprise::Captain::BaseTaskService
# so that conversation completion evaluation always runs regardless of
# the customer's Captain usage quota. This is an internal operational
# check, not a customer-facing feature — it should never be blocked
# by quota exhaustion.
module Enterprise::Captain::ConversationCompletionService
  private

  def responses_available?
    true
  end
end
