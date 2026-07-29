# Evaluates whether a conversation is complete and can be auto-resolved.
# Used by InboxPendingConversationsResolutionJob to determine if inactive
# conversations should be resolved or handed off to human agents.
#
# NOTE: This service intentionally does NOT count toward Captain usage limits.
# The response excludes the :message key that Enterprise::Captain::BaseTaskService
# checks for usage tracking. This is an internal operational evaluation,
# not a customer-facing value-add, so we don't charge for it.
class Captain::ConversationCompletionService < Captain::BaseTaskService
  RESPONSE_SCHEMA = Captain::ConversationCompletionSchema

  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    content = format_evaluation_input
    return default_incomplete_response('No messages found') if content.blank?

    response = make_api_call(
      model: InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('conversation_completion') },
        { role: 'user', content: content }
      ],
      schema: RESPONSE_SCHEMA
    )

    return default_incomplete_response(response[:error]) if response[:error].present?

    parse_response(response[:message])
  end

  private

  def prompt_from_file(file_name)
    Rails.root.join('enterprise/lib/captain/prompts', "#{file_name}.liquid").read
  end

  def format_evaluation_input
    messages = conversation_message_records(start_from: 0)
    return if messages.blank?

    [
      "Conversation status: #{conversation.status}",
      format_messages_as_string(messages)
    ].join("\n\n")
  end

  def conversation_message_records(start_from: 0)
    messages = []
    character_count = start_from

    conversation.messages
                .where(message_type: [:incoming, :outgoing])
                .where(private: false)
                .reorder('id desc')
                .each do |message|
      content = message.content_for_llm
      next if content.blank?
      break if character_count + content.length > TOKEN_LIMIT

      messages.prepend({ message: message, content: content })
      character_count += content.length
    end

    messages
  end

  def format_messages_as_string(messages)
    transcript = messages.map do |message_context|
      "#{message_sender_label(message_context[:message])}: #{message_context[:content]}"
    end.join("\n")

    "Conversation transcript:\n#{transcript}"
  end

  def message_sender_label(message)
    return 'Customer' if message.incoming?
    return 'Captain' if captain_reply?(message)
    return 'Bot' if bot_reply?(message)

    'Assistant'
  end

  def captain_reply?(message)
    message.outgoing? && message.sender_type == 'Captain::Assistant'
  end

  def bot_reply?(message)
    message.outgoing? && message.sender_type.in?(['AgentBot', 'Captain::Assistant'])
  end

  def parse_response(message)
    return default_incomplete_response('Invalid response format') unless message.is_a?(Hash)

    {
      complete: message['complete'] == true,
      reason: message['reason'] || 'No reason provided'
    }
  end

  def default_incomplete_response(reason)
    { complete: false, reason: reason }
  end

  # This is an internal operational evaluation, not a customer-triggered feature,
  # so it should always use the installation key.
  def llm_credential
    @llm_credential ||= system_llm_credential
  end

  def counts_toward_usage?
    false
  end

  def event_name
    'captain.conversation_completion'
  end

  def build_follow_up_context?
    false
  end
end

Captain::ConversationCompletionService.prepend_mod_with('Captain::ConversationCompletionService')
