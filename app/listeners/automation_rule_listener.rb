class AutomationRuleListener < BaseListener
  def conversation_updated(event)
    return if performed_by_automation?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?('conversation_updated', account)

    rules = current_account_rules('conversation_updated', account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation, { changed_attributes: changed_attributes }).perform
      perform_action(rule, account, conversation, nil, nil) if conditions_match.present?
    end
  end

  def conversation_created(event)
    return if performed_by_automation?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?('conversation_created', account)

    rules = current_account_rules('conversation_created', account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation, { changed_attributes: changed_attributes }).perform
      perform_action(rule, account, conversation, nil, changed_attributes) if conditions_match.present?
    end
  end

  def order_status_updated(event)
    return if performed_by_automation?(event)

    account = event.data.account
    changed_attributes = event.data

    return unless rule_present?('order_status_updated', account)

    rules = current_account_rules('order_status_updated', account)
    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, nil, { changed_attributes: changed_attributes }).perform

      perform_action(rule, account, nil, event&.data&.contact, changed_attributes) if conditions_match.present?
    end
  end

  def order_created(event)
    return if performed_by_automation?(event)

    account = event.data.account
    changed_attributes = event.data

    return unless rule_present?('order_created', account)

    rules = current_account_rules('order_created', account)
    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, nil, { changed_attributes: changed_attributes }).perform

      perform_action(rule, account, nil, event&.data&.contact, changed_attributes) if conditions_match.present?
    end
  end

  def cart_recovery(event)
    return if performed_by_automation?(event)

    custom_api = event.data['custom_api']
    account = custom_api.account
    contact = Contact.find_by("account_id = ? AND additional_attributes->>'id_from_integration' = ?", account['id'],
                              event.data['id'].to_s)

    items = event.data.[]('checkouts')&.[](0)

    changed_attributes = items['lineItems']

    return unless rule_present?('cart_recovery', account)

    rules = current_account_rules('cart_recovery', account)
    rules.each do |rule|
      perform_action(rule, account, nil, contact, changed_attributes)
    end
  end

  def conversation_opened(event)
    return if performed_by_automation?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?('conversation_opened', account)

    rules = current_account_rules('conversation_opened', account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation, { changed_attributes: changed_attributes }).perform
      perform_action(rule, account, conversation, nil, nil) if conditions_match.present?
    end
  end

  def message_created(event)
    message = event.data[:message]

    return if ignore_message_created_event?(event)

    account = message.try(:account)
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?('message_created', account)

    rules = current_account_rules('message_created', account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation,
                                                                        { message: message, changed_attributes: changed_attributes }).perform
      perform_action(rule, account, message.conversation, nil, changed_attributes) if conditions_match.present?
    end
  end

  def rule_present?(event_name, account)
    return if account.blank?

    current_account_rules(event_name, account).any?
  end

  def current_account_rules(event_name, account)
    AutomationRule.where(
      event_name: event_name,
      account_id: account.id,
      active: true
    )
  end

  def performed_by_automation?(event)
    event.data[:performed_by].present? && event.data[:performed_by].instance_of?(AutomationRule)
  end

  def ignore_message_created_event?(event)
    message = event.data[:message]
    performed_by_automation?(event) || message.activity?
  end

  def perform_action(rule, account, conversation, contact, changed_attributes)
    if rule.respond_to?(:delay) && rule.delay.present?

      AutomationActionJob.set(wait: rule.delay.seconds).perform_later(rule, account, conversation, contact, changed_attributes)
    else
      ::AutomationRules::ActionService.new(rule, account, conversation, contact, changed_attributes).perform
    end
  end
end
