class EmailReplyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(message_id)
    message = Message.find(message_id)

    return if message.blank?
    return unless message.email_notifiable_message?
    return if message.content.nil?

    # send the email
    ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_later
  end
end
