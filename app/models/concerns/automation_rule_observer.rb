# Other way we could handle this with rails-observer gem
module AutomationRuleObserver
  extend ActiveSupport::Concern

  AUTOMATION_RULE_EVENTS = [
    :conversation_created,
    :conversation_resolved,
    :conversation_assigned,
    :conversation_snoozed,
    :conversation_auto_resolved
    :conversation_muted,
    :label_added,
    :label_removed,
    :team_assigned,
    :incoming_message_created,
    :outgoing_message_created
  ]

  included do
    after_create :call_automation_rule, if: :automation_rule_present?
  end

  def call_automation_rule
  end

  private

  def automation_rule_present?
    true
  end
end
