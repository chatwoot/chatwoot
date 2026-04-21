class SynapseosListener < BaseListener
  LEAD_LABEL = 'lead_qualificado'.freeze
  COMMAND_REGEX = %r{^/(ganhei|perdi)(?:\s+([0-9]+(?:[.,][0-9]+)?))?}i

  def conversation_updated(event)
    conversation, account = extract_conversation_and_account(event)
    changes = event.data[:changed_attributes] || {}

    handle_label_changes(conversation, account, changes)
    handle_assignee_transition(conversation, account, changes)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.private? && message.content.is_a?(String)

    match = message.content.strip.match(COMMAND_REGEX)
    return unless match

    handle_deal_command(message, match[1].downcase, match[2])
  end

  private

  def handle_deal_command(message, command, amount_raw)
    conversation = message.conversation
    account = message.account
    lead = ::Synapseos::Lead.where(account_id: account.id, conversation_id: conversation.id).first_or_create!(
      contact_id: conversation.contact_id,
      assignee_id: conversation.assignee_id,
      status: :qualified,
      source: 'manual_command'
    )

    amount = parse_amount(amount_raw)
    status = command == 'ganhei' ? :won : :lost
    ::Synapseos::Deal.create!(
      account_id: account.id,
      lead_id: lead.id,
      assignee_id: message.sender_id,
      status: status,
      amount: amount,
      closed_at: Time.current,
      metadata: { source: 'manual_command', note_message_id: message.id }
    )

    ::Synapseos::CrmEvent.create!(
      account_id: account.id,
      conversation_id: conversation.id,
      user_id: message.sender_id,
      event_type: status == :won ? 'deal_won' : 'deal_lost',
      metadata: { amount: amount, source: 'manual_command' }
    )
  rescue StandardError => e
    Rails.logger.warn("[Synapseos] handle_deal_command failed: #{e.message}")
  end

  def parse_amount(raw)
    return 0 if raw.blank?

    raw.to_s.tr(',', '.').to_f
  end

  def handle_label_changes(conversation, account, changes)
    label_change = changes['label_list'] || changes[:label_list]
    return if label_change.blank?

    previous_labels = Array(label_change[0]).map(&:to_s)
    current_labels = Array(label_change[1]).map(&:to_s)
    return unless current_labels.include?(LEAD_LABEL) && previous_labels.exclude?(LEAD_LABEL)

    create_lead_from_label(conversation, account)
  end

  def create_lead_from_label(conversation, account)
    return if ::Synapseos::Lead.exists?(account_id: account.id, conversation_id: conversation.id)

    lead = ::Synapseos::Lead.create!(
      account_id: account.id,
      conversation_id: conversation.id,
      contact_id: conversation.contact_id,
      assignee_id: conversation.assignee_id,
      status: :qualified,
      source: 'label',
      qualified_at: Time.current
    )
    log_event(account, conversation, 'lead_qualified', lead_id: lead.id, source: 'label')
  end

  def handle_assignee_transition(conversation, account, changes)
    bot_change = changes['assignee_agent_bot_id'] || changes[:assignee_agent_bot_id]
    user_change = changes['assignee_id'] || changes[:assignee_id]
    return if bot_change.blank? && user_change.blank?

    previous_type = previous_assignee_type(bot_change, user_change)
    current_type = current_assignee_type(conversation)
    return if previous_type == current_type

    if previous_type == 'AgentBot' && current_type == 'User'
      log_event(account, conversation, 'bot_takeover', new_assignee_id: conversation.assignee_id)
    elsif previous_type == 'User' && current_type == 'AgentBot'
      log_event(account, conversation, 'human_rescue', previous_assignee_id: user_change&.first)
    end
  end

  def previous_assignee_type(bot_change, user_change)
    previous_bot = bot_change&.first
    previous_user = user_change&.first
    return 'AgentBot' if previous_bot.present?
    return 'User' if previous_user.present?

    nil
  end

  def current_assignee_type(conversation)
    conversation.assignee_type
  end

  def log_event(account, conversation, event_type, metadata = {})
    ::Synapseos::CrmEvent.create!(
      account_id: account.id,
      conversation_id: conversation.id,
      event_type: event_type,
      metadata: metadata.compact
    )
  end
end
