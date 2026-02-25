class Captain::InboxPendingConversationsResolutionJob < ApplicationJob
  queue_as :low

  def perform(inbox)
    if inbox.account.feature_enabled?('captain_tasks')
      perform_with_evaluation(inbox)
    else
      perform_time_based(inbox)
    end
  ensure
    Current.reset
  end

  private

  def perform_time_based(inbox)
    Current.executed_by = inbox.captain_assistant

    resolvable_conversations = inbox.conversations.pending
                                    .where('last_activity_at < ?', Time.now.utc - 1.hour)
                                    .limit(Limits::BULK_ACTIONS_LIMIT)

    resolvable_conversations.each do |conversation|
      create_resolution_message(conversation, inbox)
      conversation.resolved!
    end
  end

  def perform_with_evaluation(inbox)
    Current.executed_by = inbox.captain_assistant

    resolvable_conversations = inbox.conversations.pending
                                    .where('last_activity_at < ?', Time.now.utc - 1.hour)
                                    .limit(Limits::BULK_ACTIONS_LIMIT)

    resolvable_conversations.each do |conversation|
      evaluation = evaluate_conversation(conversation, inbox)

      if evaluation[:complete]
        resolve_conversation(conversation, inbox, evaluation[:reason])
      else
        handoff_conversation(conversation, inbox, evaluation[:reason])
      end
    end
  end

  def evaluate_conversation(conversation, inbox)
    Captain::ConversationCompletionService.new(
      account: inbox.account,
      conversation_display_id: conversation.display_id
    ).perform
  end

  def resolve_conversation(conversation, inbox, reason)
    create_private_note(conversation, inbox, "Auto-resolved: #{reason}")
    create_resolution_message(conversation, inbox)
    conversation.resolved!
    create_captain_reporting_event(conversation, 'conversation_captain_resolved')
  end

  def handoff_conversation(conversation, inbox, reason)
    create_private_note(conversation, inbox, "Auto-handoff: #{reason}")
    create_handoff_message(conversation, inbox)
    conversation.bot_handoff!
    create_captain_reporting_event(conversation, 'conversation_captain_handoff')
    send_out_of_office_message_if_applicable(conversation)
  end

  def send_out_of_office_message_if_applicable(conversation)
    # Campaign conversations should never receive OOO templates — the campaign itself
    # serves as the initial outreach, and OOO would be confusing in that context.
    return if conversation.campaign.present?

    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation)
  end

  def create_private_note(conversation, inbox, content)
    conversation.messages.create!(
      message_type: :outgoing,
      private: true,
      sender: inbox.captain_assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: content
    )
  end

  def create_resolution_message(conversation, inbox)
    I18n.with_locale(inbox.account.locale) do
      resolution_message = inbox.captain_assistant.config['resolution_message']
      conversation.messages.create!(
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: resolution_message.presence || I18n.t('conversations.activity.auto_resolution_message'),
        sender: inbox.captain_assistant
      )
    end
  end

  def create_handoff_message(conversation, inbox)
    handoff_message = inbox.captain_assistant.config['handoff_message']
    return if handoff_message.blank?

    conversation.messages.create!(
      message_type: :outgoing,
      sender: inbox.captain_assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: handoff_message
    )
  end

  def create_captain_reporting_event(conversation, event_name)
    ReportingEvent.create!(
      name: event_name,
      value: conversation.updated_at.to_i - conversation.created_at.to_i,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.created_at,
      event_end_time: conversation.updated_at
    )
  end
end
