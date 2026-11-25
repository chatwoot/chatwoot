class Conversations::EventDataPresenter < SimpleDelegator
  # What a contact is allowed to receive over the cable. This is an ALLOWLIST on
  # purpose: `contact_push_data` is built FROM this list, never subtracted from
  # `push_data`. A new field therefore reaches agents only, until someone adds it
  # here deliberately.
  #
  # A denylist was tried first and failed open. Every field added to `push_data`
  # leaked by default, and two did within a month: `last_non_activity_message`
  # (which resolves to a trailing private note, since `non_activity_messages`
  # filters `message_type` but not `private`) and, on Pro, `kanban_task` (board
  # name, funnel step names, and the agent roster with availability). Anything
  # operational — labels, custom attributes, priority, assignee, SLA — is agent
  # context and stays out by construction.
  #
  # The list is this short because that is what the contact actually consumes:
  # the widget store keeps only `id` and `status` from cable payloads
  # (widget/store/modules/conversationAttributes.js), and the typing handlers
  # read only `conversation.id`. The rest is here because it describes the
  # contact's own side of the conversation and costs nothing to keep, so a
  # widget change does not immediately land on this list. Everything else the
  # widget needs comes from its own REST endpoint, which is scoped to the
  # contact and unaffected by this.
  #
  # Only the cable is narrowed. `/api/v1/accounts/.../conversations` is
  # agent-authenticated and keeps serving the full payload.
  CONTACT_PUSH_KEYS = %i[
    id status can_reply channel messages unread_count
    agent_last_seen_at contact_last_seen_at created_at updated_at timestamp
  ].freeze

  # Transient per-event tags the listener merges onto a payload after building
  # it. They are not `push_data` fields, so they are named separately, but they
  # are contact-safe and have to survive the narrowing.
  CONTACT_SAFE_EVENT_KEYS = %i[event_metadata].freeze

  # The contact's copy of `push_data`. See CONTACT_PUSH_KEYS before widening it.
  def contact_push_data
    self.class.contact_slice(push_data.slice(*CONTACT_PUSH_KEYS))
  end

  # Narrows an already-built agent payload instead of rebuilding it, so a
  # listener that broadcasts to both audiences pays for `push_data` once.
  def self.contact_slice(payload)
    data = payload.slice(*CONTACT_PUSH_KEYS, *CONTACT_SAFE_EVENT_KEYS)
    data[:messages] = data[:messages].map { |message| contact_message(message) } if data[:messages].present?
    data
  end

  # A message is the contact's to see, sender included. The conversation it
  # embeds names the assigned agent, which agents read (the dashboard's audio
  # alerts) and the contact must not.
  def self.contact_message(message)
    return message if message[:conversation].blank?

    message.merge(conversation: message[:conversation].except(:assignee_id))
  end

  def push_data # rubocop:disable Metrics/MethodLength
    {
      additional_attributes: additional_attributes,
      **push_reply_state,
      channel: inbox.try(:channel_type),
      contact_inbox: contact_inbox,
      group_type: group_type,
      id: display_id,
      inbox_id: inbox_id,
      messages: push_messages,
      last_non_activity_message: push_last_non_activity_message,
      labels: label_list,
      meta: push_meta,
      status: status,
      custom_attributes: custom_attributes,
      snoozed_until: snoozed_until,
      unread_count: unread_incoming_messages.count,
      first_reply_created_at: first_reply_created_at,
      priority: priority,
      waiting_since: waiting_since.to_i,
      **push_timestamps,
      **group_left_data,
      **whatsapp_missing_data,
      **redirect_origin_data
    }
  end

  # Whether THIS thread's number has left the WhatsApp group. The group contact is
  # account-scoped and can be in two inboxes of one account, so the answer belongs to the
  # conversation rather than to the contact every thread shares. Absent, rather than
  # false, on everything that is not a group: the question does not apply there, and the
  # conversation partial leaves it out on the same terms.
  def group_left_data
    return {} unless group_type_group?

    { group_left: contact_inbox&.group_left? }
  end

  # Same field, on the same terms, as the conversation partial: see the comment there.
  def whatsapp_missing_data
    return {} unless inbox&.whatsapp?

    { whatsapp_missing_checked_at: contact_inbox&.whatsapp_missing_checked_at&.to_i }
  end

  # The WhatsApp entry conversation this widget thread was redirected from, as its display_id (the
  # per-account number, the same one `id` above carries) — never the primary key, which is a
  # different number for the same conversation and is what a consumer would silently mis-join on.
  #
  # ALWAYS present, nil included, and that is the opposite of group_left right above. The two look
  # alike and are not: a conversation does not stop being a group, but a pairing IS cleared — by a
  # re-entry whose token names no origin (see the widget controller). Omitting nil would make that
  # clear indistinguishable from "this conversation was never part of an episode", and a consumer
  # holding the previous pairing has no way to tell it to drop one. It kept acting on it.
  #
  # A Chatwoot without this change omits the key entirely, so absent still means "said nothing" — the
  # distinction a consumer needs is between an instance that speaks about pairings and one that does
  # not, and the key's presence is exactly that.
  def redirect_origin_data
    { redirect_origin_display_id: redirect_origin_display_id }
  end

  # Like #push_data but with message text normalized for external integrations (webhooks).
  def webhook_data
    push_data.merge(
      account: account.webhook_data,
      messages: webhook_push_messages
    )
  end

  # The widget learns the conversation's id, inbox, read state and status, not the contact or the agents
  def widget_data
    {
      id: display_id,
      inbox_id: inbox_id,
      contact_last_seen_at: contact_last_seen_at.to_i,
      status: status
    }
  end

  private

  # This payload also reaches the contact: ActionCableListener broadcasts
  # `conversation.created`, `conversation.status_changed` and
  # `conversation.updated` to `user_tokens + contact_inbox_tokens` in a single
  # message. `.chat` (no activity, no private) is what keeps agent-only content
  # out of the contact's browser, so this array is deliberately NOT the
  # dashboard seed — that one lives in the conversation jbuilder
  # (`Conversation#dashboard_seed_message`) and is wider on purpose. Do not
  # "mirror the jbuilder" here before splitting the broadcast audience.
  def push_messages
    [messages.where(account_id: account_id).chat.last&.push_event_data].compact
  end

  # Same query and reaction enrichment as the `last_non_activity_message` field
  # in the conversation jbuilder, so cable subscribers can refresh the chat list
  # preview after in-place reaction updates (the snake-cased field is read by
  # the frontend store and `MessagePreview` to derive the latest visible
  # message). Without this, the snapshot taken at fetch time stays stale.
  def push_last_non_activity_message
    msg = last_non_activity_message
    return nil unless msg

    data = msg.push_event_data
    if msg.reaction?
      target_id = msg.content_attributes['in_reply_to']
      target = target_id.present? ? messages.find_by(id: target_id) : nil
      # Strip HTML before truncating so email/HTML messages don't leak
      # "<p>..." markup into the chat-list preview as literal text.
      # `strip_tags` returns an `ActiveSupport::SafeBuffer`, which Sidekiq's
      # strict-args check rejects when this hash is passed to
      # `ActionCableBroadcastJob.perform_later`; coerce back to a plain String
      # so the cable broadcast doesn't 500 the controller via the dispatcher.
      if target&.content.present?
        plain_snippet = String.new(ActionController::Base.helpers.strip_tags(target.content))
        data[:in_reply_to_snippet] = plain_snippet.truncate(60)
      end
    end
    data
  end

  def webhook_push_messages
    [messages.where(account_id: account_id).chat.last&.webhook_push_event_data].compact
  end

  def push_reply_state
    {
      anonymous_caller: contact_inbox&.anonymous_caller?,
      can_reply: can_reply?
    }
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
      updated_at: updated_at&.floor(6).to_f
    }
  end
end
Conversations::EventDataPresenter.prepend_mod_with('Conversations::EventDataPresenter')
