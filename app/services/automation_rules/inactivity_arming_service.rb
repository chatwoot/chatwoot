# A wait on inactivity is armed, not run: it writes a clock, and writing the same clock twice
# writes the same clock. That is why it does not go through the message run claims, which exist to
# keep an action from happening twice and, applied to an arm, suppress real activity: an edit that
# restores a body the rule already saw reuses that body's finished claim, and the deadline that
# should have moved never does. Nothing here is customer-facing, so there is nothing to deduplicate.
class AutomationRules::InactivityArmingService
  def initialize(conversation, message: nil, performed_by: nil, at: nil)
    @conversation = conversation
    @message = message
    @performed_by = performed_by
    @at = at
    @account = conversation.account
  end

  def perform
    return if @account.blank? || !@account.feature_enabled?('delayed_automations')
    return if quiet_wait_speaking?

    rules.each do |rule|
      next if AutomationRules::ConditionsFilterService.new(rule, @conversation, {}).perform.blank?

      AutomationRulePendingExecution.schedule(rule: rule, conversation: @conversation, message: @message, at: @at)
    end
  end

  private

  # What another rule wrote is activity on the conversation, and the fire-time clock has always read
  # it that way; the arm has to agree, or a row that already ran or was skipped is terminal, nothing
  # sweeps it again, and that activity never starts a new count.
  #
  # Except when the rule that wrote it is itself a wait on silence. Such a rule speaks BECAUSE the
  # conversation went quiet, so reading it as the conversation coming alive is how two of them end up
  # answering each other for ever, each one's message restarting the other's count.
  def quiet_wait_speaking?
    @performed_by.is_a?(AutomationRule) && @performed_by.inactivity_trigger?
  end

  # Conversation-level rules, so the conditions are asked of the conversation and not of the
  # message that happened to arm them.
  def rules
    AutomationRule.where(account_id: @account.id, event_name: 'conversation_updated',
                         active: true, execution_delay_trigger: 'inactivity')
  end
end
