class MessageTemplates::Template::OutOfOffice
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(out_of_office_message_params)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def out_of_office_message_params
    content = @conversation.inbox&.out_of_office_message

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end
end
