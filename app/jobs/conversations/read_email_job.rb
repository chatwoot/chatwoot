class Conversations::ReadEmailJob < ApplicationJob
  queue_as :medium

  def perform(conversation, agent, read_at)
    return unless conversation.inbox&.email?

    conversation.messages.create!({
                                    message_type: :activity,
                                    account_id: conversation.account_id,
                                    inbox_id: conversation.inbox_id,
                                    content: I18n.t('conversations.activity.read_email', user_name: agent.name,
                                                                                         read_at: read_at.strftime('%Y-%m-%d %H:%M:%S'))
                                  })
  end
end
