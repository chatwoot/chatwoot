class Integrations::Stark::ProcessorService < Integrations::BotProcessorService
  include Stark::ConversationStatusManager
  include Stark::ApiHandler
  include Stark::MessageHandler
  include Stark::Validator

  pattr_initialize [:event_name!, :hook!, :event_data!]

  def perform
    return unless can_process_message?

    process_conversation
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: agent_bot.account).capture_exception
  end

  private

  def process_conversation
    mark_conversation_pending
    return unless should_run_processor?(event_data[:message])
    return if handle_missing_dealership_id

    process_stark_response
  end

  def process_stark_response
    response = get_stark_response(current_conversation, event_data[:message].content)
    return mark_conversation_open if invalid_response?(response)

    handle_response(response)
  end

  def handle_missing_dealership_id
    return false unless current_conversation.account&.dealership_id.blank?
    mark_conversation_open
    true
  end

  def invalid_response?(response)
    response.blank? || !response_valid?(response)
  end

  def current_conversation
    @current_conversation ||= event_data[:message].conversation
  end

  def hook
    @hook ||= agent_bot
  end

  def agent_bot
    @agent_bot ||= hook
  end
end
