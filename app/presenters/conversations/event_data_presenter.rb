class Conversations::EventDataPresenter < SimpleDelegator
  def push_data
    {
      additional_attributes: additional_attributes,
      can_reply: can_reply?,
      channel: inbox.try(:channel_type),
      contact_inbox: contact_inbox,
      id: display_id,
      inbox_id: inbox_id,
      messages: push_messages,
      labels: label_list,
      meta: push_meta,
      status: status,
      custom_attributes: custom_attributes,
      snoozed_until: snoozed_until,
      unread_count: unread_incoming_messages.count,
      first_reply_created_at: first_reply_created_at,
      priority: priority,
      waiting_since: waiting_since.to_i,
      handoff_invite: crm_handoff_invite,
      **push_timestamps
    }
  end

  # Like #push_data but with message text normalized for external integrations (webhooks).
  def webhook_data
    push_data.merge(
      account: account.webhook_data,
      messages: webhook_push_messages
    )
  end

  private

  # Convite R3 pendente do card CRM vinculado (badge na lista de conversas).
  # Só consulta quando o CRM AI está ligado (find_by indexado por
  # conversation_id); nil quando não há convite ativo — o front não renderiza.
  def crm_handoff_invite
    # Referência direta (sem defined?): defined? não dispara o autoload do
    # Zeitwerk e retornava nil com Crm::Ai ainda não carregado no processo.
    return unless Crm::Ai::Config.enabled?

    card = account.crm_cards.find_by(conversation_id: id)
    return if card.blank?

    Crm::Ai::HandoffInvitePayload.for_card(card)
  end

  def push_messages
    [messages.where(account_id: account_id).chat.last&.push_event_data].compact
  end

  def webhook_push_messages
    [messages.where(account_id: account_id).chat.last&.webhook_push_event_data].compact
  end

  def push_meta
    {
      sender: contact.push_event_data,
      assignee: assigned_entity&.push_event_data,
      assignee_type: assignee_type,
      team: team&.push_event_data,
      hmac_verified: contact_inbox&.hmac_verified
    }
  end

  def push_timestamps
    {
      agent_last_seen_at: agent_last_seen_at.to_i,
      contact_last_seen_at: contact_last_seen_at.to_i,
      last_activity_at: last_activity_at.to_i,
      timestamp: last_activity_at.to_i,
      created_at: created_at.to_i,
      updated_at: updated_at.to_f
    }
  end
end
Conversations::EventDataPresenter.prepend_mod_with('Conversations::EventDataPresenter')
