class EmailReplyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(message_id)
    message = Message.find(message_id)

    return unless message.outgoing? || message.input_csat?
    return if message.private?

    # send the email
    ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_later
  end
end
