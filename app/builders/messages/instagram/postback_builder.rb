# Builder to create incoming messages from Instagram Quick Reply / postback button clicks.
# https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messaging_postbacks
class Messages::Instagram::PostbackBuilder # rubocop:disable Metrics/ClassLength
  attr_reader :messaging, :inbox

  def initialize(messaging, inbox)
    @messaging = messaging
    @inbox = inbox
  end

  def perform
    return if postback_already_exists?

    ActiveRecord::Base.transaction do
      build_message
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def postback
    @messaging[:postback]
  end

  def postback_title
    postback[:title]
  end

  def postback_payload
    decoded_source&.last || raw_postback_payload
  end

  def raw_postback_payload
    postback[:payload]
  end

  def decoded_source
    @decoded_source ||= Messages::PostbackPayloadCodec.decode(raw_postback_payload)
  end

  def postback_mid
    postback[:mid]
  end

  def timestamp
    @messaging[:timestamp]
  end

  def sender_id
    @messaging[:sender][:id]
  end

  # Meta reports postback[:mid] as the id of the outgoing message that
  # contained the clicked button, not a click-specific id, and it is reused
  # for every click on that message. Build a synthetic key so a genuine
  # duplicate webhook delivery is deduped without dropping every ordinary click.
  def click_source_id
    "postback:#{sender_id}:#{postback_mid}:#{raw_postback_payload}:#{timestamp}"
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: sender_id)&.contact
  end

  def conversation
    @conversation ||= find_or_create_conversation
  end

  def find_or_create_conversation
    if @inbox.lock_to_single_conversation
      find_conversation_scope.order(created_at: :desc).first || build_conversation
    else
      find_or_build_for_multiple_conversations
    end
  end

  def find_conversation_scope
    Conversation.where(conversation_params)
  end

  def find_or_build_for_multiple_conversations
    last_conversation = find_conversation_scope.where.not(status: :resolved).order(created_at: :desc).first
    return build_conversation if last_conversation.nil?

    last_conversation
  end

  def build_conversation
    @contact_inbox = contact.contact_inboxes.find_by!(source_id: sender_id)
    Conversation.create!(conversation_params.merge(contact_inbox_id: @contact_inbox.id))
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id
    }
  end

  def build_message
    conversation.messages.create!(message_params)
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      source_id: click_source_id,
      content: message_content,
      sender: contact,
      content_attributes: {
        postback: true,
        postback_payload: postback_payload,
        postback_title: postback_title
      }.merge(selected_reply_attributes)
    }
  end

  # Create a readable message content from the postback
  # The title is what the button displayed to the user
  def message_content
    postback_title.presence || "[Quick Reply: #{postback_payload}]"
  end

  def postback_already_exists?
    return false if postback_mid.blank?

    Message.exists?(source_id: click_source_id)
  end

  def selected_reply_attributes
    selected_reply = {
      id: postback_payload,
      title: postback_title,
      type: 'postback'
    }

    selected_reply.merge!(postback_source_context)

    {
      selected_reply: selected_reply.compact
    }
  end

  def postback_source_context
    source_message, source_card, source_button = matching_source_message
    return {} if source_message.blank?

    {
      source_message_external_id: source_message.source_id,
      source_message_id: source_message.id,
      source_message_content_type: source_message.content_type,
      card_index: source_card&.dig(:card_index),
      card_title: source_card&.dig(:title),
      card_description: source_card&.dig(:description),
      button_index: source_button&.dig(:button_index)
    }
  end

  def matching_source_message
    return matching_source_message_by_id if decoded_source

    matching_source_message_by_scan
  end

  def matching_source_message_by_id
    source_message = conversation.messages.outgoing.find_by(id: decoded_source.first)
    return [nil, nil, nil] if source_message.blank?

    card, button = find_matching_card_and_button(source_message)
    [source_message, card, button]
  end

  def matching_source_message_by_scan
    source_message = conversation.messages.outgoing
                                 .where(content_type: %w[cards interactive_buttons])
                                 .reorder(created_at: :desc)
                                 .detect { |outgoing_message| find_matching_card_and_button(outgoing_message).present? }

    return [nil, nil, nil] if source_message.blank?

    card, button = find_matching_card_and_button(source_message)
    [source_message, card, button]
  end

  def find_matching_card_and_button(source_message)
    return find_matching_interactive_button(source_message) if source_message.content_type == 'interactive_buttons'

    Array(source_message.content_attributes['items']).each_with_index do |item, card_index|
      item = item.with_indifferent_access

      Array(item[:actions]).each_with_index do |action, button_index|
        action = action.with_indifferent_access
        next unless action[:payload] == postback_payload

        return [
          {
            card_index: card_index,
            title: item[:title],
            description: item[:description]
          },
          {
            button_index: button_index
          }
        ]
      end
    end

    nil
  end

  def find_matching_interactive_button(source_message)
    Array(source_message.content_attributes['buttons']).each_with_index do |button, button_index|
      button = button.with_indifferent_access
      next unless button[:id] == postback_payload

      return [
        nil,
        {
          button_index: button_index
        }
      ]
    end

    nil
  end

  def handle_error(error)
    Rails.logger.error("[InstagramPostbackBuilder Error]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
    true
  end
end
