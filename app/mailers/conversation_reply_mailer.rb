class ConversationReplyMailer < ApplicationMailer # rubocop:disable Metrics/ClassLength
  # We needs to expose large attachments to the view as links
  # Small attachments are linked as mail attachments directly
  attr_reader :large_attachments

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

    Rails.logger.info("Email sent from #{from_email_with_name} \
      to #{to_email} with subject #{@conversation.display_id} \
      #{I18n.t('conversations.reply.transcript_subject')} ")
    mail({
           to: to_email,
           from: from_email_with_name,
           subject: "[##{@conversation.display_id}] #{I18n.t('conversations.reply.transcript_subject')}"
         })
  end

  def forward_email(message, forward_to_emails, forward_comment = nil) # rubocop:disable Metrics/MethodLength
    init_conversation_attributes(message.conversation)

    # Check SMTP configuration - allow if channel SMTP is enabled OR global SMTP is set
    return unless @inbox.inbox_type == 'Email' && (@channel.smtp_enabled || smtp_config_set_or_development?)

    @message = message
    @forward_to_emails = forward_to_emails
    @forward_comment = forward_comment
    @large_attachments = []

    # Set up SMTP based on channel configuration
    ms_smtp_settings
    google_smtp_settings
    set_delivery_method

    Rails.logger.info("Forwarding email from #{from_email_with_name} to #{@forward_to_emails.join(', ')}")

    # Create the mail object first
    mail_object = mail(
      to: @forward_to_emails,
      from: from_email_with_name,
      reply_to: reply_email,
      subject: forward_subject,
      message_id: "<forwarded/#{@conversation.uuid}/#{@message.id}/#{SecureRandom.hex}@#{channel_email_domain}>",
      template_name: 'forward_email'
    )

    # Process attachments after mail object is created
    process_attachments_for_forward(mail_object) if @message.attachments.present?

    mail_object
  end

  private

  def process_attachments_for_forward(mail_object)
    current_total_size = 0
    @message.attachments.each do |attachment|
      raw_data = attachment.file.download
      attachment_name = attachment.file.filename.to_s
      file_size = raw_data.bytesize

      if current_total_size + file_size <= 20.megabytes
        mail_object.attachments[attachment_name] = raw_data
        current_total_size += file_size
      else
        @large_attachments << attachment
      end
    end
  end

  def forward_subject
    original_subject = @conversation.additional_attributes['mail_subject'] ||
                       @message.content_attributes.dig('email', 'subject') ||
                       I18n.t('conversations.reply.email_subject')
    "Fwd: #{original_subject}"
  end

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
    current_message&.sender&.available_name || @agent&.available_name || 'Notifications'
  end

  def business_name
    @inbox.business_name || @inbox.name
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
    if should_use_conversation_email_address?
      sender_name("reply+#{@conversation.uuid}@#{@account.inbound_email_domain}")
    else
      @inbox.email_address || @agent&.email
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
