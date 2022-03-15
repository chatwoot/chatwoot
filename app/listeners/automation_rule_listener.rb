class AutomationRuleListener < BaseListener
  def conversation_updated(event_obj)
    conversation = event_obj.data[:conversation]
    account = conversation.account

    return unless rule_present?('conversation_updated', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation).perform
      AutomationRules::ActionService.new(rule, account, conversation).perform if conditions_match.present?
    end
  end

  def conversation_status_changed(event_obj)
    conversation = event_obj.data[:conversation]
    account = conversation.account

    return unless rule_present?('conversation_status_changed', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation).perform
      AutomationRules::ActionService.new(rule, account, conversation).perform if conditions_match.present?
    end
  end

  def conversation_created(event_obj)
    conversation = event_obj.data[:conversation]
    account = conversation.account

    return unless rule_present?('conversation_created', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation).perform
      ::AutomationRules::ActionService.new(rule, account, conversation).perform if conditions_match.present?
    end
  end

  def message_created(event_obj)
    message = event_obj.data[:message]
    account = message.try(:account)

    return unless rule_present?('message_created', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation).message_conditions
      ::AutomationRules::ActionService.new(rule, account, message.conversation).perform if conditions_match.present?
    end
  end

  def rule_present?(event_name, account)
    return if account.blank?

    @rules = AutomationRule.where(
      event_name: event_name,
      account_id: account.id,
      active: true
    )
    @rules.any?
  end
end
