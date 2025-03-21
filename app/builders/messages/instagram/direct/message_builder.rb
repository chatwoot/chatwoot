# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

class Messages::Instagram::Direct::MessageBuilder < Messages::Instagram::Direct::BaseBuilder
  attr_reader :messaging

  def initialize(messaging, inbox, outgoing_echo: false)
    super()
    @messaging = messaging
    @inbox = inbox
    @outgoing_echo = outgoing_echo
  end

  def perform
    Rails.logger.info("Performing message builder for Instagram Direct Message: #{@messaging}")
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_message
    end
  rescue StandardError => e
    Rails.logger.error("Error performing message builder for Instagram Direct Message: #{@messaging}")
    # TODO: Check if this is the correct way to handle the error
    if e.response&.unauthorized?
      @inbox.channel.authorization_error!
      raise
    end
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

  def message_is_unsupported?
    message[:is_unsupported].present? && @messaging[:message][:is_unsupported] == true
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
    @conversation ||= set_conversation_based_on_inbox_config
  end

  def set_conversation_based_on_inbox_config
    if @inbox.lock_to_single_conversation
      Conversation.where(conversation_params).order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_or_build_for_multiple_conversations
    # If lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    last_conversation = Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first

    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def message_content
    @messaging[:message][:text]
  end

  def story_reply_attributes
    message[:reply_to][:story] if message[:reply_to].present? && message[:reply_to][:story].present?
  end

  def message_reply_attributes
    message[:reply_to][:mid] if message[:reply_to].present? && message[:reply_to][:mid].present?
  end

  def build_message
    Rails.logger.info("Building message for Instagram Direct Message: #{@messaging}")
    return if @outgoing_echo && already_sent_from_chatwoot?
    return if message_content.blank? && all_unsupported_files?

    @message = conversation.messages.create!(direct_message_params)
    save_story_id

    attachments.each do |attachment|
      process_direct_attachment(attachment)
    end
  end

  def save_story_id
    Rails.logger.info("Saving story id for Instagram Direct Message: #{@messaging}")
    return if story_reply_attributes.blank?

    @message.save_story_info(story_reply_attributes)
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)

    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def direct_message_params
    params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      source_id: message_identifier,
      content: message_content,
      sender: @outgoing_echo ? nil : contact,
      content_attributes: {
        in_reply_to_external_id: message_reply_attributes
      }
    }

    params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
    params
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

  # Sample message response
  # {
  #   "time": <timestamp>,
  #   "id": <CONNECT_CHANNEL_INSTAGRAM_USER_ID>, // Connect channel Instagram User ID
  #   "messaging": [
  #     {
  #       "sender": {
  #         "id": <INSTAGRAM_USER_ID>
  #       },
  #       "recipient": {
  #         "id": <CONNECT_CHANNEL_INSTAGRAM_USER_ID>
  #       },
  #       "timestamp": <timestamp>,
  #       "message": {
  #         "mid": <MESSAGE_ID>,
  #         "text": <MESSAGE_TEXT>
  #       }
  #     }
  #   ]
  # }

  # Sample story mention response
  # {
  #   "id": <CONNECT_CHANNEL_INSTAGRAM_USER_ID>, // Connect channel Instagram User ID
  #   "messaging": [
  #     {
  #       "sender": {
  #         "id": <SENDER_ID>
  #       },
  #       "recipient": {
  #         "id": <RECIPIENT_ID>
  #       },
  #       "timestamp": 1741856516834,
  #       "message": {
  #         "mid": <MESSAGE_ID>,
  #         "attachments": [
  #           {
  #             "type": "story_mention",
  #             "payload": {
  #               "url": <attachment_url>
  #             }
  #           }
  #         ]
  #       }
  #     }
  #   ]
  # }
end
