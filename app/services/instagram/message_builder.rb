# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Instagram::MessageBuilder
  attr_reader :messaging

  def initialize(messaging, inbox, outgoing_echo: false)
    @messaging = messaging
    @inbox = inbox
    @outgoing_echo = outgoing_echo
  end

  def perform
    return if @inbox.channel.reauthorization_required?
    build_message
  rescue Koala::Facebook::AuthenticationError
    Rails.logger.info "Facebook Authorization expired for Inbox #{@inbox.id}"
  rescue StandardError => e
    Sentry.capture_exception(e)
    true
  end

  private

  def attachments
    @messaging[:message][:attachments] || {}
  end

  def message_type
    @outgoing_echo ? :outgoing : :incoming
  end

  def message_source_id
    @outgoing_echo ? recipient_id : sender_id
  end

  def sender_id
    @messaging[:sender][:id]
  end

  def recipient_id
    @messaging[:recipient][:id]
  end

  def message
    @messaging[:message]
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
  end

  def conversation
    @conversation ||= Conversation.find_by(conversation_params) || build_conversation
  end

  def message_content
    @messaging[:message][:text]
  end

  def content_attributes
    { message_id: @messaging[:message][:mid] }
  end

  def build_message
    @message = conversation.messages.create!(message_params)

    attachments.each do |attachment|
      process_attachment(attachment)
    end
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def process_attachment(attachment)
    return if attachment['type'].to_sym == :template

    attachment_obj = @message.attachments.new(attachment_params(attachment).except(:remote_file_url))
    attachment_obj.save!
    attach_file(attachment_obj, attachment_params(attachment)[:remote_file_url]) if attachment_params(attachment)[:remote_file_url]
  end

  def attachment_params(attachment)
    file_type = attachment['type'].to_sym
    params = { file_type: file_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video].include? file_type
      params.merge!(file_type_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    {
      external_url: attachment['payload']['url'],
      remote_file_url: attachment['payload']['url']
    }
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id,
      additional_attributes: {
        type: 'instagram_direct_message'
      }
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      source_id: message_source_id,
      content: message_content,
      content_attributes: content_attributes,
      sender: @outgoing_echo ? nil : contact
    }
  end

end
