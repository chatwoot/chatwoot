class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    resolvable_conversations = conversation_scope(account).limit(Limits::BULK_ACTIONS_LIMIT)

    resolvable_conversations.each do |conversation|
      resolve_conversation(conversation, account)
    end
  end

  private

  def resolve_conversation(conversation, account)
    if account.auto_resolve_split_reasons
      send_split_reason_message(conversation, account)
    else
      send_auto_resolve_template(conversation)
    end

    add_label_if_present(conversation, account)
    conversation.toggle_status
  end

  def send_auto_resolve_template(conversation)
    ::MessageTemplates::Template::AutoResolve.new(conversation: conversation).perform
  end

  def send_split_reason_message(conversation, account)
    message_text = determine_message_text(conversation, account)

    ::MessageTemplates::Template::AutoResolve.new(
      conversation: conversation, message_text: message_text, message_type: :outgoing
    ).perform
  end

  def determine_message_text(conversation, account)
    if conversation.waiting_since.present?
      account.auto_resolve_message_agent.presence || I18n.t('conversations.activity.auto_resolve.agent_inactive', locale: account.locale)
    else
      account.auto_resolve_message_client.presence || I18n.t('conversations.activity.auto_resolve.client_inactive', locale: account.locale)
    end
  end

  def add_label_if_present(conversation, account)
    return if account.auto_resolve_label.blank?

    conversation.add_labels(account.auto_resolve_label)
  end

  def conversation_scope(account)
    base_scope = if account.auto_resolve_ignore_waiting
                   account.conversations.resolvable_not_waiting(account.auto_resolve_after)
                 else
                   account.conversations.resolvable_all(account.auto_resolve_after)
                 end

    # Exclude orphan conversations where contact was deleted but conversation cleanup is pending
    base_scope.where.not(contact_id: nil).where.not(status: :proxied)
  end
end
