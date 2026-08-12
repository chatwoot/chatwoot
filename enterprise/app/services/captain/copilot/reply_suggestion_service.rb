class Captain::Copilot::ReplySuggestionService
  include Captain::Copilot::ConversationAccess

  class GenerationError < StandardError; end

  def initialize(assistant:, conversation_id:, user_id:, copilot_thread_id:)
    @assistant = assistant
    @account = assistant.account
    @conversation_id = conversation_id
    @user = @account.users.find(user_id)
    @copilot_thread = @account.copilot_threads.find_by!(
      id: copilot_thread_id,
      user_id: user_id,
      assistant_id: assistant.id
    )
  end

  def generate_response
    conversation = accessible_conversation(account: @account, user: @user, display_id: @conversation_id)
    raise ActiveRecord::RecordNotFound, 'Conversation not found' if conversation.blank?

    target_message = latest_public_message(conversation)
    return persist_discarded_response unless target_message&.incoming?

    message_history = conversation_history(conversation)

    runner = Captain::Assistant::AgentRunnerService.new(
      assistant: @assistant,
      conversation: conversation,
      source: 'copilot_reply_suggestion',
      read_only: true,
      trace_feature: :copilot,
      responding_to_message_id: target_message.id,
      stale_response_policy: :public_message
    )
    response = runner.generate_response(message_history: message_history)
    return persist_discarded_response if runner.response_discarded?

    raise GenerationError, response['reasoning'] if response['error']

    return persist_discarded_response if persist_response(response, runner, conversation, target_message) == :discarded

    response
  end

  private

  def conversation_history(conversation)
    history = Captain::Conversation::MessageHistoryBuilderService.new(conversation: conversation).perform
    history.pop while history.last&.dig(:content) == Captain::Conversation::MessageHistoryBuilderService::RESOLUTION_MARKER
    history
  end

  def latest_public_message(conversation)
    conversation.messages
                .where(private: false, message_type: [:incoming, :outgoing])
                .reorder(created_at: :desc, id: :desc)
                .first
  end

  def persist_response(response, runner, conversation, target_message)
    response_parts = Captain::Assistant::ResponseParts.from_response(response)
    content = response_parts.customer_message_content(
      citation_urls: @assistant.trusted_citation_urls(runner.last_run_result)
    )

    @copilot_thread.with_lock do
      return :discarded unless latest_public_message(conversation)&.id == target_message.id
      return :persisted if @copilot_thread.copilot_messages.assistant.exists?

      @copilot_thread.copilot_messages.create!(
        message_type: :assistant,
        message: {
          content: content,
          reasoning: response['reasoning'],
          reply_suggestion: true
        }.compact
      )
      @account.increment_response_usage
    end

    :persisted
  end

  def persist_discarded_response
    @copilot_thread.with_lock do
      return discarded_response if @copilot_thread.copilot_messages.assistant.exists?

      @copilot_thread.copilot_messages.create!(
        message_type: :assistant,
        message: { content: discarded_response['response'] }
      )
    end

    discarded_response
  end

  def discarded_response
    {
      'response' => I18n.t('captain.copilot.reply_suggestion_discarded', locale: @account.locale),
      'discarded' => true
    }
  end
end
