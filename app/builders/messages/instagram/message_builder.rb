# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Instagram::MessageBuilder < Messages::Messenger::MessageBuilder
  attr_reader :messaging

  def initialize(messaging, inbox, outgoing_echo: false)
    super()
    @messaging = messaging
    @inbox = inbox
    @outgoing_echo = outgoing_echo
  end

  def perform
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_message
    end
  rescue Koala::Facebook::AuthenticationError
    @inbox.channel.authorization_error!
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  private

  def attachments
    @messaging[:message][:attachments] || {}
  end

  def message_type
    @outgoing_echo ? :outgoing : :incoming
  end

  def message_identifier
    message[:mid]
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
    @conversation ||= Conversation.where(conversation_params).find_by(
      "additional_attributes ->> 'type' = 'instagram_direct_message'"
    ) || build_conversation
  end

  def message_content
    @messaging[:message][:text]
  end

  def story_reply_attributes
    message[:reply_to][:story] if message[:reply_to].present? && message[:reply_to][:story].present?
  end

  def build_message
    return if @outgoing_echo && already_sent_from_chatwoot?
    return if message_content.blank? && all_unsupported_files?

    @message = conversation.messages.create!(message_params)
    save_story_id

    attachments.each do |attachment|
      process_attachment(attachment)
    end
  end

  def save_story_id
    return if story_reply_attributes.blank?

    @message.save_story_info(story_reply_attributes)
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)

    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id,
                           additional_attributes: { type: 'instagram_direct_message' }
                         ))
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      source_id: message_identifier,
      content: message_content,
      sender: @outgoing_echo ? nil : contact
    }
  end

  def already_sent_from_chatwoot?
    cw_message = conversation.messages.where(
      source_id: @messaging[:message][:mid]
    ).first

    cw_message.present?
  end

  def all_unsupported_files?
    return if attachments.empty?

    attachments_type = attachments.pluck(:type).uniq.first
    unsupported_file_type?(attachments_type)
  end

  ### Sample response
  # {
  #   "object": "instagram",
  #   "entry": [
  #     {
  #       "id": "<IGID>",// ig id of the business
  #       "time": 1569262486134,
  #       "messaging": [
  #         {
  #           "sender": {
  #             "id": "<IGSID>"
  #           },
  #           "recipient": {
  #             "id": "<IGID>"
  #           },
  #           "timestamp": 1569262485349,
  #           "message": {
  #             "mid": "<MESSAGE_ID>",
  #             "text": "<MESSAGE_CONTENT>"
  #           }
  #         }
  #       ]
  #     }
  #   ],
  # }
end
