class Email::SendOnEmailService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Email
  end

  def perform_reply
    return unless message.email_notifiable_message?

    if channel.microsoft?
      send_via_microsoft_graph
    else
      send_via_smtp
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def send_via_microsoft_graph
    result = Microsoft::SendMailService.new(
      channel: channel,
      message: message,
      to_emails: to_emails,
      cc_emails: cc_emails,
      bcc_emails: bcc_emails,
      subject: mail_subject,
      html_body: html_body,
      text_body: text_body,
      in_reply_to: in_reply_to,
      references: references_header
    ).perform

    Rails.logger.info("Email message #{message.id} sent via Microsoft Graph API with source_id: #{result.message_id}")
    message.update(source_id: result.message_id)
  end

  def send_via_smtp
    reply_mail = ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_now
    Rails.logger.info("Email message #{message.id} sent with source_id: #{reply_mail.message_id}")
    message.update(source_id: reply_mail.message_id)
  end

  # Helper methods to build email components
  def to_emails
    content_attrs = message.content_attributes
    to_list = content_attrs&.dig('to_emails') || content_attrs&.dig(:to_emails)
    to_list.presence || [contact&.email].compact
  end

  def cc_emails
    content_attrs = message.content_attributes
    content_attrs&.dig('cc_emails') || content_attrs&.dig(:cc_emails) || []
  end

  def bcc_emails
    content_attrs = message.content_attributes
    content_attrs&.dig('bcc_emails') || content_attrs&.dig(:bcc_emails) || []
  end

  def mail_subject
    subject = conversation.additional_attributes&.dig('mail_subject')
    return "[##{conversation.display_id}] #{I18n.t('conversations.reply.email_subject')}" if subject.nil?

    conversation.messages.chat.count > 1 ? "Re: #{subject}" : subject
  end

  def html_body
    content_attrs = message.content_attributes
    html_content = content_attrs&.dig('email', 'html_content', 'reply')

    if html_content.present?
      html_content
    elsif message.content.present?
      ChatwootMarkdownRenderer.new(message.outgoing_content).render_message
    else
      ''
    end
  end

  def text_body
    content_attrs = message.content_attributes
    content_attrs&.dig('email', 'text_content', 'reply') || message.content || ''
  end

  def in_reply_to
    incoming_message = conversation.messages.incoming.last
    content_attrs = incoming_message&.content_attributes
    message_id = content_attrs&.dig('email', 'message_id')
    message_id.present? ? "<#{message_id}>" : nil
  end

  def references_header
    in_reply_to || "<account/#{conversation.account_id}/conversation/#{conversation.uuid}@#{email_domain}>"
  end

  def email_domain
    channel.email.split('@').last
  end
end
