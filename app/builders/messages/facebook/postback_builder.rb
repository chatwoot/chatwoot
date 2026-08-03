# Builder to create incoming messages from Facebook Messenger postback button clicks.
class Messages::Facebook::PostbackBuilder # rubocop:disable Metrics/ClassLength
  attr_reader :messaging, :inbox

  def initialize(messaging, inbox)
    @messaging = messaging
    @inbox = inbox
  end

  def perform
    return if postback_already_exists?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_message
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def postback
    @messaging[:postback] || {}
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

  def sender_id
    @messaging.dig(:sender, :id)
  end

  def contact
    @contact ||= @contact_inbox&.contact
  end

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: sender_id,
      inbox: inbox,
      contact_attributes: {}
    ).perform
  end

  def conversation
    @conversation ||= find_or_create_conversation
  end

  def find_or_create_conversation
    if inbox.lock_to_single_conversation
      conversation_scope.order(created_at: :desc).first || build_conversation
    else
      last_conversation = conversation_scope.where.not(status: :resolved).order(created_at: :desc).first
      last_conversation || build_conversation
    end
  end

  def conversation_scope
    Conversation.where(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id
    )
  end

  def build_conversation
    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def build_message
    conversation.messages.create!(message_params)
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      source_id: postback_mid,
      content: message_content,
      sender: contact,
      content_attributes: {
        postback: true,
        postback_payload: postback_payload,
        postback_title: postback_title
      }.merge(selected_reply_attributes)
    }
  end

  def message_content
    postback_title.presence || "[Postback: #{postback_payload}]"
  end

  def postback_already_exists?
    return false if postback_mid.blank?

    Message.exists?(source_id: postback_mid)
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
    return find_matching_interactive_buttons_button(source_message) if source_message.content_type == 'interactive_buttons'

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

  def find_matching_interactive_buttons_button(source_message)
    Array(source_message.content_attributes['buttons']).each_with_index do |button, button_index|
      button = button.with_indifferent_access
      next unless button[:id] == postback_payload

      return [
        {
          card_index: 0,
          title: source_message.outgoing_content.presence || source_message.content_attributes['body_text'],
          description: source_message.content_attributes['footer_text']
        },
        {
          button_index: button_index
        }
      ]
    end

    nil
  end

  def handle_error(error)
    Rails.logger.error("[FacebookPostbackBuilder Error]: #{error.message}")
    ChatwootExceptionTracker.new(error, account: inbox.account).capture_exception
    true
  end
end
