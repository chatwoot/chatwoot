class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  MAX_MESSAGE_LENGTH = 10_000

  def perform(conversation, assistant)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant

    Current.executed_by = @assistant

    ActiveRecord::Base.transaction do
      generate_and_process_response
    end
  rescue StandardError => e
    handle_error(e)
  ensure
    Current.executed_by = nil
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
      @conversation.messages.incoming.last.content,
      collect_previous_messages
    )

    return process_action('handoff') if handoff_requested?

    create_messages
    Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .map do |message|
        {
          content: message_content(message),
          role: determine_role(message)
        }
      end
  end

  def message_content(message)
    return message.content if message.content.present?

    'User has shared an attachment' if message.attachments.any?

    'User has shared a message without content'
  end

  def determine_role(message)
    return 'system' if message.content.blank?

    message.message_type == 'incoming' ? 'user' : 'system'
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def process_action(action)
    case action
    when 'handoff'
      I18n.with_locale(@assistant.account.locale) do
        create_handoff_message
        @conversation.bot_handoff!
      end
    end
  end

  def create_handoff_message
    create_outgoing_message(@assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff'))
  end

  def create_messages
    validate_message_content!(@response['response'])
    create_outgoing_message(@response['response'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content)
    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: message_content
    )
  end

  def handle_error(error)
    log_error(error)
    process_action('handoff')
    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end
end
