class Captain::Copilot::ReplySuggestionService
  include Captain::Copilot::ConversationAccess
  include Integrations::LlmInstrumentationConstants

  class GenerationError < StandardError; end

  TRACE_NAME = 'llm.captain.copilot'.freeze

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
    @discarded = false
    @credit_used = false
  end

  def generate_response
    conversation = accessible_conversation(account: @account, user: @user, display_id: @conversation_id)
    return persist_failure_response if conversation.blank?

    existing_response = completed_response
    return existing_response if existing_response

    target_message = latest_public_message(conversation)
    with_trace(conversation, target_message) do
      next persist_discarded_response unless target_message&.incoming?

      response, runner = generate_reply(conversation)
      raise GenerationError, response['reasoning'] if response['error']

      persist_response(response, runner, conversation, target_message)
    end
  end

  def persist_failure_response
    @copilot_thread.with_lock do
      existing_message = @copilot_thread.copilot_messages.assistant.first
      return response_from(existing_message) if existing_message

      create_failure_response
    end
  end

  private

  def conversation_history(conversation)
    history = Captain::Conversation::MessageHistoryBuilderService.new(conversation: conversation).perform
    history.pop while history.last&.dig(:content) == Captain::Conversation::MessageHistoryBuilderService::RESOLUTION_MARKER
    history
  end

  def generate_reply(conversation)
    runner = Captain::Assistant::AgentRunnerService.new(
      assistant: @assistant,
      conversation: conversation,
      source: Captain::Assistant::AgentRunnerService::REPLY_SUGGESTION_SOURCE
    )
    response = runner.generate_response(message_history: conversation_history(conversation))

    [response, runner]
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
      existing_message = @copilot_thread.copilot_messages.assistant.first
      return response_from(existing_message) if existing_message
      return create_failure_response unless conversation_accessible?(conversation)
      return create_discarded_response if latest_public_message(conversation)&.id != target_message.id

      create_reply_suggestion(response, content)
    end
  end

  def create_reply_suggestion(response, content)
    @copilot_thread.copilot_messages.create!(
      message_type: :assistant,
      message: {
        content: content,
        reasoning: response['reasoning'],
        reply_suggestion: true
      }.compact
    )
    @account.increment_response_usage
    @credit_used = true

    response
  end

  def persist_discarded_response
    @copilot_thread.with_lock do
      existing_message = @copilot_thread.copilot_messages.assistant.first
      return response_from(existing_message) if existing_message

      create_discarded_response
    end
  end

  def create_discarded_response
    @discarded = true
    response = discarded_response
    @copilot_thread.copilot_messages.create!(
      message_type: :assistant,
      message: { content: response['response'] }
    )

    response
  end

  def create_failure_response
    response = failure_response
    @copilot_thread.copilot_messages.create!(
      message_type: :assistant,
      message: { content: response['response'] }
    )

    response
  end

  def conversation_accessible?(conversation)
    accessible_conversation(
      account: @account,
      user: @user,
      display_id: conversation.display_id
    )&.id == conversation.id
  end

  def completed_response
    message = @copilot_thread.copilot_messages.assistant.first
    response_from(message) if message
  end

  def response_from(copilot_message)
    @discarded = copilot_message.message['reply_suggestion'] != true

    {
      'response' => copilot_message.message['content'],
      'discarded' => @discarded
    }
  end

  def with_trace(conversation, target_message)
    return yield unless ChatwootApp.otel_enabled?

    OpentelemetryConfig.tracer.in_span(TRACE_NAME, attributes: trace_attributes(conversation, target_message)) do |span|
      response = yield
      span.set_attribute(ATTR_LANGFUSE_TRACE_OUTPUT, response.to_json)
      response
    ensure
      write_final_trace_metadata(span)
    end
  end

  def trace_attributes(conversation, target_message)
    {
      ATTR_LANGFUSE_USER_ID => @account.id.to_s,
      ATTR_LANGFUSE_SESSION_ID => "#{@account.id}_#{conversation.display_id}",
      ATTR_LANGFUSE_TAGS => ['copilot'].to_json,
      format(ATTR_LANGFUSE_METADATA, 'assistant_id') => @assistant.id.to_s,
      format(ATTR_LANGFUSE_METADATA, 'conversation_display_id') => conversation.display_id.to_s,
      format(ATTR_LANGFUSE_METADATA, 'source') => 'copilot_reply_suggestion',
      format(ATTR_LANGFUSE_METADATA, 'feature_name') => 'copilot',
      ATTR_LANGFUSE_TRACE_INPUT => { target_message_id: target_message&.id }.to_json
    }
  end

  def write_final_trace_metadata(span)
    span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'discarded'), @discarded.to_s)
    span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), @credit_used.to_s)
  end

  def reply_locale
    @user.ui_settings&.dig('locale').presence || @account.locale
  end

  def discarded_response
    {
      'response' => I18n.t('captain.copilot.reply_suggestion_discarded', locale: reply_locale),
      'discarded' => true
    }
  end

  def failure_response
    {
      'response' => I18n.t('captain.copilot.reply_suggestion_failed', locale: reply_locale),
      'discarded' => false
    }
  end
end
