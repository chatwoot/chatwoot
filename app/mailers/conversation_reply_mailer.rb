class ConversationReplyMailer < ApplicationMailer
  include ConversationReplyMailerHelper
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  layout :choose_layout

  def reply_with_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    recap_messages = @conversation.messages.chat.where('id < ?', last_queued_id).last(10)
    new_messages = @conversation.messages.chat.where('id >= ?', last_queued_id)
    @messages = recap_messages + new_messages
    @messages = @messages.select(&:email_reply_summarizable?)
    prepare_mail(true)
  end

  def reply_without_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    @messages = @conversation.messages.chat.where(message_type: [:outgoing, :template]).where('id >= ?', last_queued_id)
    @messages = @messages.reject { |m| m.template? && !m.input_csat? }
    return false if @messages.count.zero?

    prepare_mail(false)
  end

  def email_reply(message)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(message.conversation)
    @message = message
    reply_mail_object = prepare_mail(true)

    message.update(source_id: reply_mail_object.message_id)
  end

  def conversation_transcript(conversation, to_email)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)

    @messages = @conversation.messages.chat.select(&:conversation_transcriptable?)

    mail({
           to: to_email,
           from: from_email_with_name,
           subject: "[##{@conversation.display_id}] #{I18n.t('conversations.reply.transcript_subject')}"
         })
  end

  private

  def init_conversation_attributes(conversation)
    @conversation = conversation
    @account = @conversation.account
    @contact = @conversation.contact
    @agent = @conversation.assignee
    @inbox = @conversation.inbox
    @channel = @inbox.channel
  end

  def should_use_conversation_email_address?
    @inbox.inbox_type == 'Email' || inbound_email_enabled?
  end

  def conversation_already_viewed?
    # whether contact already saw the message on widget
    return unless @conversation.contact_last_seen_at
    return unless last_outgoing_message&.created_at

    @conversation.contact_last_seen_at > last_outgoing_message&.created_at
  end

  def last_outgoing_message
    @conversation.messages.chat.where.not(message_type: :incoming)&.last
  end

  def assignee_name
    @assignee_name ||= @agent&.available_name || 'Notifications'
  end

  def mail_subject
    subject = @conversation.additional_attributes['mail_subject']
    return "[##{@conversation.display_id}] #{I18n.t('conversations.reply.email_subject')}" if subject.nil?

    chat_count = @conversation.messages.chat.count
    if chat_count > 1
      "Re: #{subject}"
    else
      subject
    end
  end

  def reply_email
    if should_use_conversation_email_address?
      I18n.t('conversations.reply.email.header.reply_with_name', assignee_name: assignee_name, inbox_name: @inbox.name,
                                                                 reply_email: "#{@conversation.uuid}@#{@account.inbound_email_domain}")
    else
      @inbox.email_address || @agent&.email
    end
  end

  def from_email_with_name
    if should_use_conversation_email_address?
      I18n.t('conversations.reply.email.header.from_with_name', assignee_name: assignee_name, inbox_name: @inbox.name,
                                                                from_email: parse_email(@account.support_email))
    else
      I18n.t('conversations.reply.email.header.from_with_name', assignee_name: assignee_name, inbox_name: @inbox.name,
                                                                from_email: parse_email(inbox_from_email_address))
    end
  end

  def parse_email(email_string)
    Mail::Address.new(email_string).address
  end

  def inbox_from_email_address
    return @inbox.email_address if @inbox.email_address

    @account.support_email
  end

  def custom_message_id
    last_message = @message || @messages&.last

    "<conversation/#{@conversation.uuid}/messages/#{last_message&.id}@#{@account.inbound_email_domain}>"
  end

  def in_reply_to_email
    conversation_reply_email_id || "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{@account.inbound_email_domain}>"
  end

  def conversation_reply_email_id
    content_attributes = @conversation.messages.incoming.last&.content_attributes

    if content_attributes && content_attributes['email'] && content_attributes['email']['message_id']
      return "<#{content_attributes['email']['message_id']}>"
    end

    nil
  end

  def cc_bcc_emails
    content_attributes = @conversation.messages.outgoing.last&.content_attributes

    return [] unless content_attributes
    return [] unless content_attributes[:cc_emails] || content_attributes[:bcc_emails]

    [content_attributes[:cc_emails], content_attributes[:bcc_emails]]
  end

  def inbound_email_enabled?
    @inbound_email_enabled ||= @account.feature_enabled?('inbound_emails') && @account.inbound_email_domain
                                                                                      .present? && @account.support_email.present?
  end

  def choose_layout
    return false if action_name == 'reply_without_summary' || action_name == 'email_reply'

    'mailer/base'
  end
end
