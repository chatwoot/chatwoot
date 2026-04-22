class SynapseosListener < BaseListener
  LEAD_LABEL = 'lead_qualificado'.freeze
  COMMAND_REGEX = %r{^/(ganhei|perdi)(?:\s+([0-9]+(?:[.,][0-9]+)?))?}i

  # Labels from docs/synapseos/tags_contract.md — broadcast changes on these.
  CONTRACT_LABELS = %w[
    lead_novo_recepcionado
    lead_qualificado
    crm_updated
    sla_alert
    rescue_transbordo
    assistencia_tecnica
    resgatado_fernanda
    farming_revisao
    farming_crosssell
    inadimplencia_contato
    inadimplencia_recuperada
  ].freeze

  BROADCAST_THROTTLE = 1.second

  def conversation_updated(event)
    conversation, account = extract_conversation_and_account(event)
    changes = event.data[:changed_attributes] || {}

    handle_label_changes(conversation, account, changes)
    handle_assignee_transition(conversation, account, changes)
    broadcast_label_changes(conversation, account, changes)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    broadcast_agent_activity(message) if message.sender_type == 'AgentBot'

    return unless message.private? && message.content.is_a?(String)

    match = message.content.strip.match(COMMAND_REGEX)
    return unless match

    handle_deal_command(message, match[1].downcase, match[2])
  end

  def deal_stage_changed(event)
    deal = event.data[:deal]
    previous_stage = event.data[:previous_stage]
    current_stage = event.data[:current_stage]
    return if deal.nil? || current_stage.nil?

    ::Synapseos::LiveChannel.broadcast(
      deal.account_id,
      type: 'deal_stage_changed',
      deal_id: deal.id,
      from: previous_stage&.slug,
      to: current_stage.slug,
      at: Time.current.iso8601
    )
  end

  def synapseos_crm_event_created(event)
    crm_event = event.data[:crm_event]
    return if crm_event&.conversation_id.blank?

    lead = ::Synapseos::Lead.find_by(account_id: crm_event.account_id, conversation_id: crm_event.conversation_id)
    return if lead.nil?

    case crm_event.event_type
    when 'appointment'
      return unless lead.pipeline_stage&.slug == 'qualificado'

      ::Synapseos::PipelineTransitionService.move(deal: lead, to_slug: 'negociacao')
    when 'deal_won'
      ::Synapseos::PipelineTransitionService.move(deal: lead, to_slug: 'fechado_ganho')
    when 'deal_lost'
      reason = crm_event.metadata['reason'] || crm_event.metadata[:reason]
      ::Synapseos::PipelineTransitionService.move(deal: lead, to_slug: 'perdido', reason: reason)
    end
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

    ::Synapseos::EnsureDefaultStagesService.new(account).call
    existing_lead = ::Synapseos::Lead.find_by(account_id: account.id, conversation_id: conversation.id)
    return promote_existing_lead(existing_lead) if existing_lead.present?

    create_lead_from_label(conversation, account)
  end

  def promote_existing_lead(lead)
    return unless lead.pipeline_stage&.slug == 'novo_lead'

    ::Synapseos::PipelineTransitionService.move(deal: lead, to_slug: 'qualificado')
  end

  def create_lead_from_label(conversation, account)
    qualified_stage = ::Synapseos::PipelineStage.find_by(account_id: account.id, slug: 'qualificado')

    lead = ::Synapseos::Lead.create!(
      account_id: account.id,
      conversation_id: conversation.id,
      contact_id: conversation.contact_id,
      assignee_id: conversation.assignee_id,
      pipeline_stage_id: qualified_stage&.id,
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

  def broadcast_agent_activity(message)
    slug = ::Synapseos::AgentResolver.slug_for(message.sender)
    return if slug.blank?

    throttle_key = "synapseos:live:activity:#{slug}:#{message.conversation_id}"
    return unless throttle(throttle_key)

    ::Synapseos::LiveChannel.broadcast(
      message.account_id,
      type: 'agent_activity',
      agent_slug: slug,
      conversation_id: message.conversation_id,
      action: message.private? ? 'private_note' : 'reply',
      at: message.created_at.iso8601
    )
  end

  def broadcast_label_changes(conversation, account, changes)
    label_change = changes['label_list'] || changes[:label_list]
    return if label_change.blank?

    previous_labels = Array(label_change[0]).map(&:to_s)
    current_labels = Array(label_change[1]).map(&:to_s)
    added = (current_labels - previous_labels) & CONTRACT_LABELS
    return if added.empty?

    added.each do |label|
      throttle_key = "synapseos:live:label:#{label}:#{conversation.id}"
      next unless throttle(throttle_key)

      ::Synapseos::LiveChannel.broadcast(
        account.id,
        type: 'label_event',
        conversation_id: conversation.display_id,
        label: label,
        at: Time.current.iso8601
      )
    end
  end

  def throttle(key)
    Rails.cache.write(key, 1, expires_in: BROADCAST_THROTTLE, unless_exist: true)
  end
end
