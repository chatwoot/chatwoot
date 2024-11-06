class MessageTemplates::Template::CalEvent
  pattr_initialize [:conversation_id!, :account_id!, :event_url]

  def initialize(conversation_id, account_id, event_url)
    @conversation = Conversation.find_by(display_id: conversation_id, account_id: account_id)
    @event_url = event_url
  end

  def perform
    ActiveRecord::Base.transaction do
      @conversation.messages.create!(cal_event_template_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    true
  end

  private

  # Change this to use the instance variable
  delegate :contact, :account, to: :@conversation

  def cal_event_template_message_params
    content = I18n.t('conversations.templates.cal_event_message_body')

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :cal_event,
      content: content,
      content_attributes: { 'event_url': @event_url }
    }
  end
end
