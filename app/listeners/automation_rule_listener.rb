class AutomationRuleListener < BaseListener
  def conversation_updated(event_obj)
    conversation = event_obj.data[:conversation]
    return unless rule_present?('conversation_updated', conversation)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation).perform
      AutomationRules::ActionService.new(rule, conversation).perform if conditions_match.present?
    end
  end

  def conversation_status_changed(event_obj)
    conversation = event_obj.data[:conversation]
    account = conversation.try(:account)

    return unless rule_present?('conversation_status_changed', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation.id).perform
      AutomationRules::ActionService.new(rule, account, conversation.id).perform if conditions_match.present?
    end
  end

  def conversation_created(event_obj)
    conversation = event_obj.data[:conversation]
    account = conversation.try(:account)

    return unless rule_present?('conversation_created', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation.id).perform
      ::AutomationRules::ActionService.new(rule, account, conversation.id).perform if conditions_match.present?
    end
  end

  def message_created(event_obj)
    message = event_obj.data[:message]
    account = message.try(:account)

    return unless rule_present?('message_created', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation_id).message_conditions
      ::AutomationRules::ActionService.new(rule, account, message.conversation_id).perform if conditions_match.present?
    end
  end

  def contact_created(event_obj)
    contact = event_obj.data[:contact]
    account = contact.try(:account)

    return unless rule_present?('contact_created', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, contact.try(:conversation_ids)).contact_conditions(contact)
      ::AutomationRules::ActionService.new(rule, account, contact.try(:conversation_ids)).perform if conditions_match.present?
    end
  end

  def contact_updated(event_obj)
    contact = event_obj.data[:contact]
    account = contact.try(:account)

    return unless rule_present?('contact_updated', account)

    @rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, contact.try(:conversation_ids)).contact_conditions(contact)
      ::AutomationRules::ActionService.new(rule, account, contact.try(:conversation_ids)).perform if conditions_match.present?
    end
  end

  def label_added(event_obj)
  end

  def label_removed(event_obj)
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
