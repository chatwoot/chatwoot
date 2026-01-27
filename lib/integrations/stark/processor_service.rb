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

  def should_run_processor?(message)
    # Primary check: if conversation is assigned, don't process regardless of status
    return false if current_conversation.assignee_id.present?

    stark_disabled_until = current_conversation.additional_attributes['stark_disabled_until']
    return false if stark_disabled_until.present? && Time.current.to_i < stark_disabled_until.to_i

    # Secondary checks from parent class
    return false if message.private?
    return false unless processable_message?(message)

    # Status check: only process if pending (maintains existing behavior for unassigned)
    # return false unless current_conversation.pending?

    true
  end

  def process_conversation
    return unless should_run_processor?(event_data[:message])
    return if handle_missing_dealership_id
    return if event_data[:message].content.blank? && !message_has_image?(event_data[:message])

    process_stark_response
  end

  def process_stark_response
    # Double-check assignment before making API call (conversation might have been assigned since initial check)
    current_conversation.reload
    return if current_conversation.assignee_id.present?

    # return unless current_conversation.pending?

    response = get_stark_response(current_conversation, event_data[:message].content, event_data[:message])
    return if response.nil? # Response is nil if there was an error (already handled by StarkRetryable)

    current_conversation.update_column(:stop_follow_up, response['stop_follow_up'])
    handle_response(response)
  end

  def handle_missing_dealership_id
    return false if current_conversation.account&.dealership_id.present?

    mark_conversation_open
    true
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
