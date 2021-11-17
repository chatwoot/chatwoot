class AutomationRuleListener

  def conversation_status_change_automation(conversation_id)
    if rule_present?('conversation_created', conversation_id)

    end
  end

  def conversation_created_automation(conversation_id)
    if rule_present?('conversation_created', conversation_id)

    end
  end


  def self.rule_present?(event_name, conversation_id)
    conversation = Conversation.find(conversation_id)
    @rule = AutomationRule.find_by(
      event_name: event_name,
      account_id: conversation.account_id
    )
    @rule.present?
  end

  def automation_conditions_match?
    @rule.conditions.each do |condition|
    end
  end
end


