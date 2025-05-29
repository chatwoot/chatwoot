class MessageTemplates::Template::AutoResolve
  pattr_initialize [:conversation!]

  def perform
    return if conversation.account.auto_resolve_message.blank?

    ActiveRecord::Base.transaction do
      conversation.messages.create!(auto_resolve_message_params)
    end
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def auto_resolve_message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: account.auto_resolve_message
    }
  end
end
