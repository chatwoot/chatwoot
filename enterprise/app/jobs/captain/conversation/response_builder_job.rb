class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  def perform(conversation, assistant)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant

    debug_file = "tmp/conversation-#{conversation.id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n\n" + ('='*100)
      f.puts '='*100
      f.puts '[RESPONSE BUILDER] ========== JOB PERFORM START =========='
      f.puts "[RESPONSE BUILDER] Time: #{Time.current}"
      f.puts "[RESPONSE BUILDER] Conversation ID: #{conversation.id}"
      f.puts "[RESPONSE BUILDER] Assistant: #{assistant&.class&.name} - #{assistant&.id}"
      f.puts "[RESPONSE BUILDER] Current.executed_by BEFORE setting: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
    end

    Current.executed_by = @assistant

    File.open(debug_file, 'a') do |f|
      f.puts "[RESPONSE BUILDER] Current.executed_by AFTER setting: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts '[RESPONSE BUILDER] About to start transaction'
    end

    ActiveRecord::Base.transaction do
      File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] Inside transaction' }
      generate_and_process_response
      File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] Transaction completed successfully' }
    end

    File.open(debug_file, 'a') do |f|
      f.puts '[RESPONSE BUILDER] After transaction block'
      f.puts "[RESPONSE BUILDER] Checking if handoff was requested: #{@handoff_requested.inspect}"
    end

    # Process handoff OUTSIDE the transaction so after_commit callbacks work properly
    if @handoff_requested
      File.open(debug_file, 'a') do |f|
        f.puts '[RESPONSE BUILDER] Processing deferred handoff OUTSIDE transaction'
        f.puts "[RESPONSE BUILDER] Transaction open?: #{ActiveRecord::Base.connection.transaction_open?}"
      end
      process_handoff
    end
  rescue StandardError => e
    File.open(debug_file, 'a') do |f|
      f.puts "[RESPONSE BUILDER] ERROR occurred: #{e.class} - #{e.message}"
      f.puts "[RESPONSE BUILDER] Backtrace (first 5): #{e.backtrace.first(5).join("\n")}"
    end
    raise e if e.is_a?(ActiveStorage::FileNotFoundError) || e.is_a?(Faraday::BadRequestError)

    handle_error(e)
  ensure
    File.open(debug_file, 'a') do |f|
      f.puts '[RESPONSE BUILDER] In ensure block'
      f.puts "[RESPONSE BUILDER] Current.executed_by BEFORE clearing: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "[RESPONSE BUILDER] Current.handoff_requested BEFORE clearing: #{Current.handoff_requested.inspect}"
    end
    Current.executed_by = nil
    Current.handoff_requested = nil
    File.open(debug_file, 'a') do |f|
      f.puts "[RESPONSE BUILDER] Current.executed_by AFTER clearing: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "[RESPONSE BUILDER] Current.handoff_requested AFTER clearing: #{Current.handoff_requested.inspect}"
      f.puts '[RESPONSE BUILDER] ========== JOB PERFORM END =========='
      f.puts '='*100
      f.puts ('='*100) + "\n\n"
    end
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    debug_file = "tmp/conversation-#{@conversation.id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n[RESPONSE BUILDER] generate_and_process_response START"
      f.puts "[RESPONSE BUILDER] captain_v2_enabled?: #{captain_v2_enabled?}"
    end

    @response = if captain_v2_enabled?
                  File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] Using AgentRunnerService (V2)' }
                  Captain::Assistant::AgentRunnerService.new(assistant: @assistant, conversation: @conversation).generate_response(
                    message_history: collect_previous_messages
                  )
                else
                  File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] Using AssistantChatService (V1)' }
                  Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
                    message_history: collect_previous_messages
                  )
                end

    File.open(debug_file, 'a') do |f|
      f.puts "[RESPONSE BUILDER] Response received: #{@response.inspect}"
      f.puts "[RESPONSE BUILDER] handoff_requested? (from response): #{handoff_requested?}"
      f.puts "[RESPONSE BUILDER] Current.handoff_requested (from tool): #{Current.handoff_requested.inspect}"
      f.puts "[RESPONSE BUILDER] Will process handoff?: #{handoff_requested? || Current.handoff_requested}"
    end

    if handoff_requested? || Current.handoff_requested
      File.open(debug_file, 'a') do |f|
        f.puts '[RESPONSE BUILDER] Handoff requested - deferring until AFTER transaction commits'
        f.puts '[RESPONSE BUILDER] Setting @handoff_requested = true'
      end
      @handoff_requested = true
      create_handoff_message
      return
    end

    create_messages
    Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
    account.increment_response_usage

    File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] generate_and_process_response END' }
  end

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .map do |message|
      message_hash = {
        content: prepare_multimodal_message_content(message),
        role: determine_role(message)
      }

      # Include agent_name if present in additional_attributes
      message_hash[:agent_name] = message.additional_attributes['agent_name'] if message.additional_attributes&.dig('agent_name').present?

      message_hash
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def process_handoff
    debug_file = "tmp/conversation-#{@conversation.id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n[RESPONSE BUILDER] process_handoff START (OUTSIDE TRANSACTION)"
      f.puts "[RESPONSE BUILDER] Current.executed_by: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "[RESPONSE BUILDER] Current.handoff_requested: #{Current.handoff_requested.inspect}"
      f.puts "[RESPONSE BUILDER] Triggered by: #{Current.handoff_requested ? 'HandoffTool (Current flag)' : 'LLM response'}"
      f.puts "[RESPONSE BUILDER] Transaction open?: #{ActiveRecord::Base.connection.transaction_open?}"
    end

    I18n.with_locale(@assistant.account.locale) do
      File.open(debug_file, 'a') do |f|
        f.puts "[RESPONSE BUILDER] Locale set to: #{@assistant.account.locale}"
        f.puts "[RESPONSE BUILDER] Conversation status BEFORE bot_handoff!: #{@conversation.reload.status}"
      end
      File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] Calling bot_handoff!' }
      @conversation.bot_handoff!
      File.open(debug_file, 'a') do |f|
        f.puts '[RESPONSE BUILDER] bot_handoff! completed'
        f.puts "[RESPONSE BUILDER] Conversation status AFTER bot_handoff!: #{@conversation.reload.status}"
      end
    end

    File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] process_handoff END' }
  end

  def create_handoff_message
    create_outgoing_message(
      @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff')
    )
  end

  def create_messages
    validate_message_content!(@response['response'])
    create_outgoing_message(@response['response'], agent_name: @response['agent_name'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content, agent_name: nil)
    additional_attrs = {}
    additional_attrs[:agent_name] = agent_name if agent_name.present?

    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: message_content,
      additional_attributes: additional_attrs
    )
  end

  def handle_error(error)
    debug_file = "tmp/conversation-#{@conversation.id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n[RESPONSE BUILDER] handle_error called"
      f.puts "[RESPONSE BUILDER] Error: #{error.class} - #{error.message}"
      f.puts '[RESPONSE BUILDER] Will handoff due to error'
    end

    log_error(error)

    # Create handoff message and set flag so handoff happens outside transaction
    @handoff_requested = true
    create_handoff_message if @conversation.messages.where(content: @assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff')).where(
      'created_at > ?', 1.minute.ago
    ).empty?

    File.open(debug_file, 'a') { |f| f.puts '[RESPONSE BUILDER] @handoff_requested set to true due to error' }

    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end

  def captain_v2_enabled?
    return account.feature_enabled?('captain_integration_v2')
  end
end
