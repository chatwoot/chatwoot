class Captain::Conversation::PriorityUpdateJob < ApplicationJob
  queue_as :low

  # Retry on transient failures
  retry_on OpenAI::Error, attempts: 3, wait: :polynomially_longer
  retry_on Faraday::Error, attempts: 3, wait: :polynomially_longer

  # Discard if the conversation no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(conversation)
    @conversation = conversation
    @account = conversation.account

    return unless should_analyze?

    Rails.logger.info(
      "[Captain::PriorityUpdateJob] Analyzing priority for conversation ##{conversation.display_id}"
    )

    Captain::Llm::ConversationPriorityService.new(conversation).analyze_and_update
  rescue StandardError => e
    handle_error(e)
  end

  private

  def should_analyze?
    return false unless smart_priority_enabled?
    return false unless conversation_eligible?

    true
  end

  def smart_priority_enabled?
    # Check if the account has the feature enabled
    # For now, check if OpenAI is configured
    openai_configured?
  end

  def openai_configured?
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.present?
  end

  def conversation_eligible?
    # Only analyze open or pending conversations
    return false unless @conversation.open? || @conversation.pending?

    # Only analyze if there are incoming messages (customer messages)
    @conversation.messages.incoming.exists?
  end

  def handle_error(error)
    Rails.logger.error(
      "[Captain::PriorityUpdateJob] Error analyzing conversation ##{@conversation.display_id}: #{error.message}"
    )
    ChatwootExceptionTracker.new(error, account: @account).capture_exception
  end
end
