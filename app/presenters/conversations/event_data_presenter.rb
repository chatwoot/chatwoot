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
      **push_timestamps
    }
  end

  # Like #push_data but with message text normalized for external integrations (webhooks).
  def webhook_data
    push_data.merge(
      account: account.webhook_data,
      contact_inbox_source_ids: contact_inbox_source_ids,
      messages: webhook_push_messages
    )
  end

  private

  # Coexistence gives one contact several source ids inside the same inbox, one per identity
  # WhatsApp reports: the phone number, the business scoped user id and, when the business
  # belongs to a portfolio, the parent one. `contact_inbox` only carries the single id the
  # conversation happens to be anchored to, so the others never reach an integration even
  # though Chatwoot resolved them. Scoping to this inbox keeps the list meaningful when an
  # account connects more than one WhatsApp business, since each assigns its own identifiers.
  #
  # This belongs to the webhook payload only, never to `push_data`. That one is broadcast to
  # the contact's own token, and on an API inbox a source id is the whole of the credential:
  # the public endpoint resolves a contact by inbox and source id alone, so handing a contact
  # the sibling ids of a merged record would hand it their conversations too. Keeping it here
  # also leaves the conversation index untouched, which renders `push_event_data` twice per
  # row and would otherwise pay this query for every conversation on the page.
  def contact_inbox_source_ids
    contact.contact_inboxes.where(inbox_id: inbox_id).pluck(:source_id)
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
