class EmailReplyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers

  def perform(message_id)
    message = Message.find(message_id)

    # send the email
    ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_later
  end
end
