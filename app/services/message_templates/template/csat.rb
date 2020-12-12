class MessageTemplates::Template::Csat
  pattr_initialize [:message!, :account_template!]

  def perform
    # TODO: fix this up
    return if message.content != 'Thanks'

    ActiveRecord::Base.transaction do
      conversation.messages.create!(csat_message_params)
    end
  rescue StandardError => e
    Raven.capture_exception(e)
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :conversation, to: :message

  def csat_message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: account_template.config[:message] || 'How happy are you with the support recieved ?',
      content_type: 'input_select',
      content_attributes: item_hash
    }
  end

  def item_hash
    {
      items: [
        { title: '😃', value: '5' },
        { title: '😊', value: '4' },
        { title: '😶', value: '3' },
        { title: '😐', value: '2' },
        { title: '🙁', value: '1' }
      ]
    }
  end
end
