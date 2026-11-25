class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    reusable = conversation_to_continue
    return apply_requested_attributes(reusable) if reusable

    look_up_exising_conversation || create_new_conversation
  end

  private

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    @contact_inbox.inbox.conversations.where(contact_id: @contact_inbox.contact_id).last
  end

  # An email inbox set to continue the contact's open case answers here, for conversations created
  # through the API just as for mail arriving in the mailbox. Without it, anything opening a
  # conversation on the customer's behalf (an escalation from another channel, an integration)
  # starts a second thread beside the case the customer is already in.
  def conversation_to_continue
    conversation = Email::ConversationPolicy.existing_for(inbox: @contact_inbox.inbox, contact: @contact_inbox.contact)
    return if conversation.blank?
    return unless caller_may_act_on?(conversation)

    conversation
  end

  # A case the caller may not open is a case they may not continue. Continuing writes to the
  # conversation and hands it back with its latest message, so without this an agent whose custom
  # role limits them to their own conversations would reach, and change, a case belonging to
  # somebody else, through an endpoint that only checks access to the inbox. Refusing falls through
  # to the ordinary path and opens a conversation of their own, which is what the same request
  # would have got with the mode off.
  #
  # `show?` is the gate the dashboard already uses to update a conversation, so this asks the same
  # question, not a stricter one. No user in `Current` means nothing to authorize: the mail paths
  # and the rake task act for the contact, not for an agent.
  def caller_may_act_on?(conversation)
    return true if Current.user.blank?

    ConversationPolicy.new(
      { user: Current.user, account: Current.account, account_user: Current.account_user },
      conversation
    ).show?
  end

  # What the caller asked for is merged into the conversation it landed in: keys that came in the
  # request win, keys that did not are left alone. Dropping them silently is what makes reuse
  # dangerous — the caller believes it created a conversation carrying its attributes, and four
  # steps later reads a link that was never written.
  def apply_requested_attributes(conversation)
    conversation.update!(reused_conversation_attributes(conversation))
    conversation
  end

  def reused_conversation_attributes(conversation)
    attributes = {
      additional_attributes: merged_additional_attributes(conversation),
      custom_attributes: conversation.custom_attributes.merge(permitted_hash(:custom_attributes))
    }
    # assignee_id and team_id are deliberately not applied: routing a conversation somebody is
    # already working on would take the case away from them without anyone noticing.
    attributes[:status] = params[:status] if params[:status].present?
    attributes[:snoozed_until] = params[:snoozed_until] if params[:snoozed_until].present?
    attributes
  end

  # `mail_subject` is what names the conversation and what the outgoing reply is titled with, so it
  # stays as the thread that opened the case wrote it. Answering under the newest subject is a
  # separate decision, not a side effect of continuing a case.
  def merged_additional_attributes(conversation)
    existing = conversation.additional_attributes || {}
    merged = existing.merge(permitted_hash(:additional_attributes))
    merged['mail_subject'] = existing['mail_subject'] if existing['mail_subject'].present?
    merged
  end

  def permitted_hash(key)
    value = params[key]
    return {} if value.blank?

    (value.respond_to?(:permit!) ? value.permit! : value).to_h.stringify_keys
  end

  def create_new_conversation
    ::Conversation.create!(conversation_params)
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    custom_attributes = params[:custom_attributes]&.permit! || {}
    status = params[:status].present? ? { status: params[:status] } : {}

    # TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases
    # commenting this out to see if there are any errors, if not we can remove this in subsequent releases
    # status = { status: 'pending' } if status[:status] == 'bot'
    {
      account_id: @contact_inbox.inbox.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id]
    }.merge(status)
  end
end
