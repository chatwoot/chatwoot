class MessageTemplates::Template::Greeting
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(greeting_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def greeting_message_params
    content = @conversation.inbox&.greeting_message
    content = string_interpolation_on_content

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end

  def string_interpolation_on_content
    binding.pry
    content.match?/{{.*?}}/
    email_text = content.gsub(/\{\{(.*?)\}\}/) { Regexp.last_match(1) }
    association, attribute = email_text.split('.')
    record = conversation.send(association)
    contacts_name = record.try(attribute)

    content.gsub(/{{.*?}}/, contacts_name)
  end
end
