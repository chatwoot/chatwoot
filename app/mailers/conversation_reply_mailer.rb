class ConversationReplyMailer < ApplicationMailer
  # We needs to expose large attachments to the view as links
  # Small attachments are linked as mail attachments directly
  attr_reader :large_attachments

  include ConversationReplyMailerHelper
  include ReferencesHeaderBuilder
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  layout :choose_layout
  RECAP_LIMIT = (ENV['EMAIL_RECAP_LIMIT'] || 50).to_i

  def reply_with_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    recap_messages = @conversation.messages
                                  .where('id < ?', last_queued_id)
                                  .order(id: :desc)
                                  .limit(RECAP_LIMIT)
                                  .to_a
    recap_messages.reverse!

    new_messages   = @conversation.messages
                                  .where('id >= ?', last_queued_id)
                                  .order(:id)
                                  .to_a

    selected_messages = filtered_recap_messages(recap_messages + new_messages)
    @messages = preload_messages(selected_messages)
    prepare_mail(true)
  end

  def reply_without_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    scoped_messages = @conversation.messages.chat.where(message_type: [:outgoing, :template]).where('id >= ?', last_queued_id)
    filtered_messages = scoped_messages.reject { |m| (m.template? && !m.input_csat?) || m.private? }
    return false if filtered_messages.empty?

    @messages = preload_messages(filtered_messages)
    prepare_mail(false)
  end

  def email_reply(message)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(message.conversation)
    @message = message
    recap_messages = recap_messages_for_email_reply(message)
    @messages = preload_messages(filtered_recap_messages(recap_messages))
    prepare_mail(true)
  end

  def conversation_transcript(conversation, to_email)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)

    transcript_messages = @conversation.messages.chat.select(&:conversation_transcriptable?)
    @messages = preload_messages(transcript_messages)

    Rails.logger.info("Email sent from #{from_email_with_name} \
      to #{to_email} with subject #{@conversation.display_id} \
      #{I18n.t('conversations.reply.transcript_subject')} ")
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
    inbound_email_enabled? && @inbox.email_address.blank?
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

  def sender_name(sender_email)
    if @inbox.friendly?
      I18n.t('conversations.reply.email.header.friendly_name', sender_name: custom_sender_name, business_name: business_name,
                                                               from_email: sender_email)
    else
      I18n.t('conversations.reply.email.header.professional_name', business_name: business_name, from_email: sender_email)
    end
  end

  def current_message
    @message || @conversation.messages.outgoing.last
  end

  def custom_sender_name
    current_message&.sender&.available_name || @agent&.available_name || I18n.t('conversations.reply.email.header.notifications')
  end

  def business_name
    @inbox.business_name || @inbox.sanitized_name
  end

  def from_email
    should_use_conversation_email_address? ? parse_email(@account.support_email) : parse_email(inbox_from_email_address)
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
    return @inbox.email_address if @inbox.email_address.present?

    if should_use_conversation_email_address?
      sender_name("reply+#{@conversation.uuid}@#{@account.inbound_email_domain}")
    else
      @agent&.email || inbox_from_email_address
    end
  end

  def from_email_with_name
    sender_name(from_email)
  end

  def channel_email_with_name
    sender_name(@channel.email)
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

    "<conversation/#{@conversation.uuid}/messages/#{last_message&.id}@#{channel_email_domain}>"
  end

  def in_reply_to_email
    conversation_reply_email_id || "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{channel_email_domain}>"
  end

  def conversation_reply_email_id
    # Find the last incoming message's message_id to reply to
    content_attributes = @conversation.messages.incoming.last&.content_attributes

    if content_attributes && content_attributes['email'] && content_attributes['email']['message_id']
      return "<#{content_attributes['email']['message_id']}>"
    end

    nil
  end

  def references_header
    build_references_header(@conversation, in_reply_to_email)
  end

  def cc_bcc_emails
    content_attributes = @conversation.messages.outgoing.last&.content_attributes

    return [] unless content_attributes
    return [] unless content_attributes[:cc_emails] || content_attributes[:bcc_emails]

    [content_attributes[:cc_emails], content_attributes[:bcc_emails]]
  end

  def to_emails_from_content_attributes
    content_attributes = @conversation.messages.outgoing.last&.content_attributes

    return [] unless content_attributes
    return [] unless content_attributes[:to_emails]

    content_attributes[:to_emails]
  end

  def to_emails
    # if there is no to_emails from content_attributes, send it to @contact&.email
    to_emails_from_content_attributes.presence || [@contact&.email]
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
