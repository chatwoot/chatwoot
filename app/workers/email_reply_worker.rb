class EmailReplyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(message_id)
    message = Message.find(message_id)

    Rails.logger.info "EmailReplyWorker - Loading message #{message_id}"
    Rails.logger.info "EmailReplyWorker - content_attributes: #{message.content_attributes.inspect}"
    Rails.logger.info "EmailReplyWorker - HTML content present: #{message.content_attributes.dig('email', 'html_content', 'full').present?}"

    return unless message.email_notifiable_message?

    # send the email
    ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_now
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    message.update!(status: :failed, external_error: e.message)
  end
end
