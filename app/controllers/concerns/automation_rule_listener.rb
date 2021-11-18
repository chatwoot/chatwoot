class AutomationRuleListener < BaseListener

  def conversation_status_changed(event_obj)
    conversation = conversation.data[:conversation]
    if self.rule_present?('conversation_status_changed', conversation)
      conditions_match = AutomationRule::ConditionsFilterService.new(@rule, conversation).perform
      AutomationRule::ActionService.new(@rule, conversation).perform if conditions_match?
    end
  end

  def conversation_created_automation(event_obj)
    conversation = event_obj.data[:conversation]
    if self.rule_present?('conversation_created', event_obj[:conversation])

    end
  end


  def self.rule_present?(event_name, conversation)
    @rule = AutomationRule.find_by(
      event_name: event_name,
      account_id: conversation.account_id
    )
    @rule.present?
  end
end


