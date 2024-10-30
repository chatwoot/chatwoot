# This class creates both outgoing messages from chatwoot and echo outgoing messages based on the flag `outgoing_echo`
# Assumptions
# 1. Incase of an outgoing message which is echo, source_id will NOT be nil,
#    based on this we are showing "not sent from chatwoot" message in frontend
#    Hence there is no need to set user_id in message for outgoing echo messages.

# rubocop:disable Metrics/ClassLength
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
  rescue Koala::Facebook::AuthenticationError => e
    Rails.logger.warn("Instagram authentication error for inbox: #{@inbox.id} with error: #{e.message}")
    Rails.logger.error e
    @inbox.channel.authorization_error!
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  private

  def attachments
    message[:attachments] || {}
  end

  def message_type
    @outgoing_echo ? :outgoing : :incoming
  end

  def message_identifier
    message[:mid]
  end

  def message_timestamp
    @messaging[:timestamp] / 1000
  end

  def message_source_id
    @outgoing_echo ? recipient_id : sender_id
  end

  def message_is_unsupported?
    message[:is_unsupported].present? && message[:is_unsupported] == true
  end

  def sender_id
    @messaging[:sender][:id]
  end

  def recipient_id
    @messaging[:recipient][:id]
  end

  def message
    postback? ? @messaging[:postback] : @messaging[:message]
  end

  def postback?
    @messaging[:postback].present?
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
  end

  def conversation
    @conversation ||= set_conversation_based_on_inbox_config
  end

  def instagram_direct_message_conversation
    Conversation.where(conversation_params)
                .where("additional_attributes ->> 'type' = 'instagram_direct_message'")
  end

  def set_conversation_based_on_inbox_config
    if @inbox.lock_to_single_conversation
      instagram_direct_message_conversation.order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_or_build_for_multiple_conversations
    last_conversation = instagram_direct_message_conversation.where.not(status: :resolved).order(created_at: :desc).first

    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def template_message?
    if @messaging[:message].present?
      if @messaging[:message][:is_echo].present? && @messaging[:message][:attachments].present?
        @messaging[:message][:attachments][0][:type] == 'template'
      else
        false
      end
    else
      false
    end
  end

  # rubocop:disable Metrics/AbcSize
  def message_content
    if @messaging[:message].present?
      if @messaging[:message][:text].present?
        @messaging[:message][:text]
      elsif @messaging[:message][:is_echo].present? && @messaging[:message][:attachments][0][:type] == 'template'
        element = @messaging[:message][:attachments][0][:payload][:generic][:elements][0]
        element[:title]
      end
    elsif @messaging[:postback].present?
      @messaging[:postback][:title].presence
    end
  end
  # rubocop:enable Metrics/AbcSize

  def template_message_content
    return if @messaging[:message].blank?
    return unless @messaging[:message][:is_echo].present? && @messaging[:message][:attachments][0][:type] == 'template'

    elements = @messaging[:message][:attachments][0][:payload][:generic][:elements]
    elements.pluck(:title)
  end

  def template_attachments
    return unless template_message?

    elements = @messaging[:message][:attachments][0][:payload][:generic][:elements]
    elements.map do |element|
      {
        'type' => 'image',
        'payload' => {
          'url' => element[:image_url]
        }
      }
    end
  end

  def template_message_button_content
    return unless template_message?

    elements = @messaging[:message][:attachments][0][:payload][:generic][:elements]
    elements.map do |element|
      buttons = element[:buttons].map.with_index { |button, index| "#{index + 1}. #{button[:title]}" }.join("\n")
      buttons_content = "The above automated message was sent along with the following buttons:\n#{buttons}"

      if element[:subtitle].present?
        "#{element[:subtitle]}\n\n#{buttons_content}"
      else
        buttons_content
      end
    end
  end

  def story_reply_attributes
    message[:reply_to][:story] if message[:reply_to].present? && message[:reply_to][:story].present?
  end

  def message_reply_attributes
    message[:reply_to][:mid] if message[:reply_to].present? && message[:reply_to][:mid].present?
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def build_message
    return if @outgoing_echo && already_sent_from_chatwoot?
    return if message_content.blank? && all_unsupported_files?

    if template_message?
      template_valid_attachments = template_attachments || []
      template_message_params.zip(template_button_message_params,
                                  template_valid_attachments).each do |message_params, button_params, attachment_params|
        @message = conversation.messages.create!(message_params)
        process_attachment(attachment_params) if attachment_params.is_a?(Hash) && attachment_params['payload']['url'].present?
        conversation.messages.create!(button_params)
      end
    else
      @message = conversation.messages.create!(message_params)
    end

    save_story_id

    attachments.each do |attachment|
      process_attachment(attachment)
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def save_story_id
    return if story_reply_attributes.blank?

    @message.save_story_info(story_reply_attributes)
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)

    previous_conversation = find_previous_conversation

    new_conversation = Conversation.create!(conversation_params.merge(
                                              contact_inbox_id: @contact_inbox.id,
                                              additional_attributes: { type: 'instagram_direct_message' }
                                            ))

    ConversationImport.perform_later(new_conversation.id, previous_conversation.id) if previous_conversation.present?

    new_conversation.messages.create!(private_message_params("Conversation with #{contact.name.capitalize} started",
                                                             new_conversation))
    new_conversation
  end

  def private_message_params(content, new_conversation)
    { account_id: new_conversation.account_id,
      additional_attributes: { disable_notifications: true },
      inbox_id: new_conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      private: true,
      content_attributes: { external_created_at: message_timestamp - 1 } }
  end

  def find_previous_conversation
    Conversation.where(conversation_params).order(created_at: :desc).first
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def template_button_message_params
    template_message_button_content.map do |content|
      params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type,
        source_id: message_identifier,
        content: content,
        sender: @outgoing_echo ? nil : contact,
        private: true,
        content_attributes: {
          in_reply_to_external_id: message_reply_attributes
        }
      }

      params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
      params
    end
  end

  def template_message_params
    template_message_content.map do |content|
      params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: message_type,
        source_id: message_identifier,
        content: content,
        sender: @outgoing_echo ? nil : contact,
        content_attributes: {
          in_reply_to_external_id: message_reply_attributes
        }
      }

      params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
      params
    end
  end

  def message_params
    params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      source_id: message_identifier,
      content: message_content,
      sender: @outgoing_echo ? nil : contact,
      content_attributes: {
        in_reply_to_external_id: message_reply_attributes,
        external_created_at: message_timestamp
      }
    }

    params[:content_attributes][:is_unsupported] = true if message_is_unsupported?
    params
  end

  def already_sent_from_chatwoot?
    recent_conversations = instagram_direct_message_conversation.order(created_at: :desc).limit(2)
    recent_conversations.any? do |conversation|
      conversation.messages.exists?(source_id: @messaging[:message][:mid])
    end
  end

  def all_unsupported_files?
    return false if attachments.empty?

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
# rubocop:enable Metrics/ClassLength
