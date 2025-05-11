class Captain::ProcessCopilotMessageJob < ApplicationJob
  queue_as :default

  def perform(assistant_id:, message:, options: {})
    ensure_assistant(assistant_id)
    ensure_user(options[:user_id])
    process_message(message, options)
  end

  private

  def ensure_assistant(assistant_id)
    @assistant = Captain::Assistant.find(assistant_id)
    @account = @assistant.account
  end

  def ensure_user(user_id)
    @user = @account.users.find(user_id)
  end

  def process_message(message, options)
    return unless @assistant

    conversation = find_conversation(options[:conversation_id])
    generate_chat_response(message, conversation, options[:previous_history])
  end

  def find_conversation(conversation_id)
    return unless conversation_id

    @account.conversations.find_by(display_id: conversation_id)
  end

  def generate_chat_response(message, conversation, previous_history)
    Captain::Copilot::ChatService.new(
      @assistant,
      previous_messages: previous_history || [],
      stream_writer: ->(data) { broadcast_response(data) },
      additional_info: {
        language: @account.locale_english_name,
        conversation_id: conversation&.display_id,
        contact_id: conversation&.contact_id
      }
    ).generate_response(message)
  end

  def broadcast_response(data)
    ActionCable.server.broadcast(
      "copilot_#{@account.id}_#{@user.id}",
      { event: 'copilot.response', data: data }
    )
  end
end
