class MessageTemplates::Template::CalEventConfirmation
  pattr_initialize [:message_id!, :event_payload!]

  def initialize(message_id, event_payload)
    @event_payload = event_payload
    puts "event_payload__: #{@event_payload.inspect}"
    @message = Message.find_by_id(message_id)
    @conversation = Conversation.find_by_id(@message.conversation_id)
  end

  def perform
    ActiveRecord::Base.transaction do
      @message.update!(content_type: :text)
      @conversation.messages.create!(cal_event_confirmation_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    true
  end

  private

  # Change this to use the instance variable
  delegate :contact, :account, to: :@conversation

  def cal_event_confirmation_message_params
    content = I18n.t('conversations.templates.cal_event_confirmation_body')

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :cal_event_confirmation,
      content: content,
      content_attributes: {
        event_payload: @event_payload
      }
    }
  end
end
